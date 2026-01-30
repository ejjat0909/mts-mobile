import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:http/http.dart' as http;
import 'package:mts/core/config/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/network_utils.dart';
import 'package:mts/data/services/pusher_event_handler_provider.dart';
import 'package:mts/providers/pending_changes/pending_changes_providers.dart';
import 'package:mts/providers/sync_real_time/sync_real_time_providers.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

/// Message data for isolate communication
class IsolateMessage {
  final SendPort sendPort;

  IsolateMessage(this.sendPort);
}

/// Result data from isolate
class IsolateResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? error;

  IsolateResult({required this.success, required this.message, this.error});
}

/// Pusher datasource for real-time communication
class PusherDatasource {
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  final SecureStorageApi _secureStorage;
  final void Function(bool hasInternet)? _onInternetStateChanged;
  final Ref _ref;

  Timer? _pendingChangesTimer;
  bool _isProcessingPendingChanges = false;
  Isolate? _pendingChangesIsolate;
  ReceivePort? _receivePort;
  String? _previousConnectionState;
  Timer? _noInternetTimer;
  DateTime? _noInternetStartTime;
  bool _everDontHaveInternet = false;

  /// Constructor with dependency injection
  PusherDatasource({
    required SecureStorageApi secureStorage,
    required Ref ref,
    void Function(bool hasInternet)? onInternetStateChanged,
  }) : _secureStorage = secureStorage,
       _ref = ref,
       _onInternetStateChanged = onInternetStateChanged;

  /// Initialize Pusher
  Future<bool> initPusher({
    required String apiKey,
    required String cluster,
    required String? channelName,
  }) async {
    try {
      // Note: PusherEventHandler is now a provider, initialized automatically by Riverpod
      prints('Pusher initializing with provider-based event handler');

      await _pusher.init(
        apiKey: apiKey,
        cluster: cluster,
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onSubscriptionSucceeded: _onSubscriptionSucceeded,
        onEvent: _onEvent,
        onSubscriptionError: _onSubscriptionError,
        onDecryptionFailure: _onDecryptionFailure,
        onMemberAdded: _onMemberAdded,
        onMemberRemoved: _onMemberRemoved,
        onSubscriptionCount: _onSubscriptionCount,
        onAuthorizer: _onAuthorizer,
      );
      if (channelName != null) {
        await _pusher.subscribe(channelName: channelName);
      }
      await _pusher.connect();

      return true;
    } catch (e) {
      prints('Pusher Init Error: $e');
      return false;
    }
  }

  /// Authorizer callback for private channels
  dynamic _onAuthorizer(
    String channelName,
    String socketId,
    dynamic options,
  ) async {
    String? token = await _secureStorage.read(key: 'access_token');

    var authUrl = '${originUrl}broadcasting/auth';

    var result = await http.post(
      Uri.parse(authUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'X-Authorization': apiKey,
      },
      body: {'socket_id': socketId, 'channel_name': channelName},
    );

    var json = jsonDecode(result.body);
    json['shared_secret'] = channelName;

    return json;
  }

  /// Connection state change callback
  void _onConnectionStateChange(dynamic currentState, dynamic previousState) {
    prints(
      'Connection State Changed: $currentState (Previous: $_previousConnectionState)',
    );

    /// currentstate [CONNECTED, RECONNECTING, CONNECTING]
    if (currentState == 'CONNECTED') {
      // Only sync if we're coming from RECONNECTING state
      // if (_previousConnectionState != 'CONNECTED') {
      //   prints(
      //     'Transitioning from RECONNECTING to CONNECTED - checking if sync is needed',
      //   );
      //   _checkAndSyncAfterReconnection();
      // }
      // Start the timer to check for pending changes every 5 seconds
      _startPendingChangesTimer();
    } else if (currentState == 'RECONNECTING') {
      // Stop the timer when reconnecting
      // _stopPendingChangesTimer();
      // _riverpodService
      //     .read(appContextProvider.notifier)
      //     .setEverDontHaveInternet(true);
    } else if (currentState == 'CONNECTING') {
      // Stop the timer when connecting
      // _stopPendingChangesTimer();
      // prints('CONNECTINGGGGG');
      // _riverpodService
      //     .read(appContextProvider.notifier)
      //     .setEverDontHaveInternet(true);
    }

    // Update the previous state for next comparison
    _previousConnectionState = currentState;
  }

  /// Check if we need to sync data after reconnection
  Future<void> _checkAndSyncAfterReconnection() async {
    try {
      prints('Internet connectivity confirmed. Proceeding with sync check.');

      // Call syncRealTime to get the latest data
      await _ref
          .read(syncRealTimeProvider.notifier)
          .onSyncOrder(
            null,
            false,
            manuallyClick: false,
            isSuccess: (bool success, String? error) {
              if (success) {
                prints('Full sync completed successfully after reconnection');
              } else {
                prints('Full sync failed after reconnection: $error');
              }
            },
            isAfterActivateLicense: false,
            onlyCheckPendingChanges: false,
            needToDownloadImage:
                true, // Set to true if you need to download images
          );
    } catch (e) {
      prints('Error checking sync status after reconnection: $e');
    }
  }

  /// Start the timer to check for pending changes every 5 seconds
  void _startPendingChangesTimer() {
    // Cancel any existing timer first
    _stopPendingChangesTimer();

    //  Create a new timer that runs every 5 seconds
    _pendingChangesTimer = Timer.periodic(
      const Duration(seconds: pusherPeriodTime),
      (_) async {
        await _processPendingChanges();
      },
    );

    prints('Started pending changes timer');
  }

  /// Stop the timer for checking pending changes
  void _stopPendingChangesTimer() {
    if (_pendingChangesTimer != null) {
      _pendingChangesTimer!.cancel();
      _pendingChangesTimer = null;
      prints('Stopped pending changes timer');
    }

    // Cancel no internet timer and reset tracking
    _noInternetTimer?.cancel();
    _noInternetTimer = null;
    _noInternetStartTime = null;

    // Kill any running isolate
    _killPendingChangesIsolate();
  }

  /// Kill the pending changes isolate if it exists
  void _killPendingChangesIsolate() {
    if (_pendingChangesIsolate != null) {
      _pendingChangesIsolate!.kill(priority: Isolate.immediate);
      _pendingChangesIsolate = null;
    }

    if (_receivePort != null) {
      _receivePort!.close();
      _receivePort = null;
    }
  }

  /// Process pending changes by calling the API in a separate isolate
  Future<void> _processPendingChanges() async {
    prints('CONNECTEDDDDD');
    // Prevent multiple simultaneous calls
    if (_isProcessingPendingChanges) {
      prints('Already processing pending changes, skipping this cycle');
      return;
    }

    try {
      int noInternetTimer = 20;
      // Check internet connectivity before attempting to sync
      bool hasInternet = await NetworkUtils.hasInternetConnection();

      if (!hasInternet) {
        prints(
          'No internet connection detected. Skipping pending changes sync.',
        );

        // Start tracking no internet time if not already tracking
        if (_noInternetStartTime == null) {
          _noInternetStartTime = DateTime.now();
          prints('Started tracking no internet time');

          // Set a timer to check after 10 seconds
          _noInternetTimer?.cancel();
          _noInternetTimer = Timer(Duration(seconds: noInternetTimer), () {
            if (_noInternetStartTime != null) {
              final duration = DateTime.now().difference(_noInternetStartTime!);
              if (duration.inSeconds >= noInternetTimer) {
                prints(
                  'No internet for $noInternetTimer seconds, notifying about no internet',
                );
                _everDontHaveInternet = true;
                _onInternetStateChanged?.call(false);
              }
            }
          });
        }
        return;
      } else {
        // Cancel the timer and reset tracking when internet is back
        _noInternetTimer?.cancel();
        _noInternetTimer = null;
        _noInternetStartTime = null;

        if (_everDontHaveInternet) {
          _everDontHaveInternet = false;
          _onInternetStateChanged?.call(true);
          _checkAndSyncAfterReconnection();
        } else {
          prints('EVERRRRR DONT HAVEEE INTERNET FALSEEEEEEEEEEEEEEEEEEEEE');
        }
      }

      _isProcessingPendingChanges = true;
      final result = await _ref
          .read(pendingChangesProvider.notifier)
          .syncPendingChangesList()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              prints('Sync pending changes timed out after 30 seconds');
              return false;
            },
          );
      _isProcessingPendingChanges = false;
      if (result) {
        prints('SUCCESSFULLY SYNCED PENDING CHANGES');
        if (_everDontHaveInternet) {
          _everDontHaveInternet = false;
          _onInternetStateChanged?.call(true);
        }
      } else {
        prints('FAILED TO SYNC PENDING CHANGES');
      }
    } catch (e) {
      prints('Error setting up  for pending changes: $e');
      _isProcessingPendingChanges = false;
    }
  }

  Map<String, dynamic> toMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is String) {
      return {'message': data};
    }

    return {};
  }

  /// Error callback
  void _onError(String message, int? code, dynamic e) {
    prints('Pusher Error: $message, Code: $code, Exception: $e');
    prints('WIFIII TUTUPPPPPPPPPPPPP');
  }

  /// Event callback
  void _onEvent(PusherEvent event) {
    //  prints('Pusher Event Received: $event');

    // Check if this is a data change event
    if (event.eventName == 'App\\Events\\DataChangeOnServer') {
      prints(
        'Detected DataChangeOnServer event, forwarding to PusherEventHandler',
      );
      // Handle the event using the provider-based event handler
      _ref.read(pusherEventHandlerProvider).handleEvent(event);
    }
  }

  /// Subscription succeeded callback
  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    prints('Subscription Succeeded: $channelName, Data: $data');
  }

  /// Subscription error callback
  void _onSubscriptionError(String message, dynamic e) {
    prints('Subscription Error: $message, Exception: $e');
  }

  /// Decryption failure callback
  void _onDecryptionFailure(String event, String reason) {
    prints('Decryption Failure: $event, Reason: $reason');
  }

  /// Member added callback
  void _onMemberAdded(String channelName, PusherMember member) {
    prints('Member Added: $channelName, User: ${member.userId}');
  }

  /// Member removed callback
  void _onMemberRemoved(String channelName, PusherMember member) {
    prints('Member Removed: $channelName, User: ${member.userId}');
  }

  /// Subscription count callback
  void _onSubscriptionCount(String channelName, int subscriptionCount) {
    prints('Subscription Count: $channelName, Count: $subscriptionCount');
  }

  /// Unsubscribe from channel
  void unsubscribe(String channelName) {
    _stopPendingChangesTimer(); // Stop the timer when unsubscribing
    _pusher.unsubscribe(channelName: channelName);
    _pusher.disconnect();
  }

  /// Trigger event
  Future<void> triggerEvent({
    required String channelName,
    required String eventName,
    required String data,
  }) async {
    try {
      await _pusher.trigger(
        PusherEvent(channelName: channelName, eventName: eventName, data: data),
      );
    } catch (e) {
      prints('Trigger Event Error: $e');
    }
  }

  /// Save Pusher configuration
  Future<void> savePusherConfig({
    required String apiKey,
    required String cluster,
    required String? channelName,
  }) async {
    await _secureStorage.write('apiKey', apiKey);
    await _secureStorage.write('cluster', cluster);
    if (channelName != null) {
      await _secureStorage.write('channelName', channelName);
    }
  }

  /// Load Pusher configuration
  Future<Map<String, String>> loadPusherConfig() async {
    final apiKey = await _secureStorage.read(key: 'apiKey');
    final cluster = await _secureStorage.read(key: 'cluster');
    final channelName = await _secureStorage.read(key: 'channelName');

    return {'apiKey': apiKey, 'cluster': cluster, 'channelName': channelName};
  }
}
