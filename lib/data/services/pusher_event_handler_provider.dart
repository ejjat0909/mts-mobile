import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/services/sync/sync_handlers_provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

/// Provider for PusherEventHandler with full Riverpod integration
///
/// This replaces the singleton pattern with proper Riverpod dependency injection.
/// The handler automatically uses the provider-aware SyncHandlerRegistry.
///
/// Usage in PusherDatasource:
/// ```dart
/// class PusherDatasource {
///   final Ref _ref;
///
///   Future<void> onEvent(PusherEvent event) async {
///     await _ref.read(pusherEventHandlerProvider).handleEvent(event);
///   }
/// }
/// ```
final pusherEventHandlerProvider = Provider<PusherEventHandler>((ref) {
  return PusherEventHandler(ref);
});

/// Handler for Pusher events that routes them to appropriate sync handlers
class PusherEventHandler {
  final Ref _ref;

  PusherEventHandler(this._ref);

  /// Handle Pusher event by parsing and routing to appropriate sync handler
  Future<void> handleEvent(PusherEvent event) async {
    try {
      prints('Processing Pusher event: ${event.eventName}');

      // Parse the event data
      final Map<String, dynamic> eventData = jsonDecode(event.data);

      // Extract event type, model name, and model data
      // The structure is {"event":"updated","modelName":"Category","model":{...}}
      final String? eventType = eventData['event'] as String?;
      final String? modelName = eventData['modelName'] as String?;
      final dynamic modelData = eventData['model'];

      prints('Event type: $eventType, Model name: $modelName');

      if (eventType == null || modelName == null) {
        prints('Invalid event data: missing event type or model name');
        return;
      }

      // Check if we have model data to use
      if (modelData != null && modelData is Map<String, dynamic>) {
        prints(
          'Forwarding event to handler for model: $modelName, event type: $eventType',
        );

        // Get handler from the new provider-based map
        final handler = _ref.read(syncHandlerProvider(modelName));
        if (handler != null) {
          // Route to appropriate handler method based on event type
          switch (eventType) {
            case 'created':
              await handler.handleCreated(modelData);
              break;
            case 'updated':
              await handler.handleUpdated(modelData);
              break;
            case 'deleted':
              await handler.handleDeleted(modelData);
              break;
            default:
              prints('Unknown event type: $eventType');
          }
        } else {
          prints('No handler found for model: $modelName');
        }
      } else {
        prints('No model data found or invalid format: $modelData');
      }

      prints('Event handling completed successfully');
    } catch (e, stackTrace) {
      prints('Error handling Pusher event: $e');
      prints('Stack trace: $stackTrace');
    }
  }
}
