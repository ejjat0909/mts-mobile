import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/pusher_datasource.dart';
import 'package:mts/domain/repositories/local/shift_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service responsible for managing WebSocket/Pusher connections
///
/// This service handles:
/// - Initializing WebSocket connections (Pusher)
/// - Subscribing/unsubscribing to channels
/// - Managing connection lifecycle
/// - Channel configuration based on shift
class WebSocketService {
  final PusherDatasource _pusherDatasource;
  final LocalShiftRepository _shiftRepository;

  WebSocketService({
    required PusherDatasource pusherDatasource,
    required LocalShiftRepository shiftRepository,
  }) : _pusherDatasource = pusherDatasource,
       _shiftRepository = shiftRepository;

  /// Initialize Pusher connection with shift-based channel
  ///
  /// Parameters:
  /// - [shiftId]: The shift ID to use for channel name
  ///
  /// Returns true if initialization was successful
  Future<bool> initializeForShift(String shiftId) async {
    if (shiftId.isEmpty) {
      prints('Cannot initialize Pusher: shiftId is empty');
      return false;
    }

    final channelName = 'private-shift-$shiftId';
    prints('Initializing Pusher for channel: $channelName');

    try {
      // Save Pusher configuration
      await _pusherDatasource.savePusherConfig(
        apiKey: pusherKey,
        cluster: pusherCluster,
        channelName: channelName,
      );

      // Initialize Pusher connection
      final success = await _pusherDatasource.initPusher(
        apiKey: pusherKey,
        cluster: pusherCluster,
        channelName: channelName,
      );

      if (success) {
        prints('✅ Pusher initialized successfully for shift: $shiftId');
      } else {
        prints('❌ Failed to initialize Pusher for shift: $shiftId');
      }

      return success;
    } catch (e) {
      prints('Error initializing Pusher: $e');
      return false;
    }
  }

  /// Subscribe to Pusher using the latest shift
  ///
  /// This automatically gets the latest shift from local storage
  /// and subscribes to its channel
  Future<bool> subscribeToLatestShift() async {
    try {
      final latestShift = await _shiftRepository.getLatestShift();

      if (latestShift.id == null || latestShift.id!.isEmpty) {
        prints('No shift found to subscribe to');
        return false;
      }

      return await initializeForShift(latestShift.id!);
    } catch (e) {
      prints('Error subscribing to latest shift: $e');
      return false;
    }
  }

  /// Disconnect from Pusher
  Future<void> disconnect() async {
    try {
      await _pusherDatasource.disconnect();
      prints('Disconnected from Pusher');
    } catch (e) {
      prints('Error disconnecting from Pusher: $e');
    }
  }

  /// Check if currently connected
  Future<bool> isConnected() async {
    try {
      return await _pusherDatasource.isConnected();
    } catch (e) {
      prints('Error checking Pusher connection: $e');
      return false;
    }
  }

  /// Reconnect to Pusher (disconnect and reconnect)
  Future<bool> reconnect() async {
    try {
      await disconnect();
      return await subscribeToLatestShift();
    } catch (e) {
      prints('Error reconnecting to Pusher: $e');
      return false;
    }
  }
}

/// Provider for WebSocketService
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService(
    pusherDatasource: ServiceLocator.get<PusherDatasource>(),
    shiftRepository: ServiceLocator.get<LocalShiftRepository>(),
  );
});
