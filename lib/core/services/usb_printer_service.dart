import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:mts/plugins/flutter_thermal_printer/utils/printer.dart';

/// Service to handle USB printer connection/disconnection events
/// This service listens to USB printer events and automatically handles connections
class UsbPrinterService {
  UsbPrinterService._();

  static UsbPrinterService? _instance;
  static UsbPrinterService get instance {
    _instance ??= UsbPrinterService._();
    return _instance!;
  }

  // Event channel for USB printer events
  static const EventChannel _eventChannel = EventChannel(
    'flutter_thermal_printer/events',
  );

  // Stream subscription for USB events
  StreamSubscription<dynamic>? _usbEventSubscription;

  // Callback functions
  Function(PrinterModel)? _onPrinterConnected;
  Function(PrinterModel)? _onPrinterDisconnected;
  Function(PrinterModel, String)? _onConnectionFailed;

  // Currently connected printers
  final List<PrinterModel> _connectedPrinters = [];

  /// Get list of currently connected printers
  List<PrinterModel> get connectedPrinters =>
      List.unmodifiable(_connectedPrinters);

  /// Set callback for when a printer is connected
  void setOnPrinterConnected(Function(PrinterModel) callback) {
    _onPrinterConnected = callback;
  }

  /// Set callback for when a printer is disconnected
  void setOnPrinterDisconnected(Function(PrinterModel) callback) {
    _onPrinterDisconnected = callback;
  }

  /// Set callback for when connection fails
  void setOnConnectionFailed(Function(PrinterModel, String) callback) {
    _onConnectionFailed = callback;
  }

  /// Start listening to USB printer events
  Future<void> startListening() async {
    try {
      // Cancel existing subscription if any
      await stopListening();

      log('Starting USB printer event listener');

      // Check if platform is ready by testing the method channel first
      // If this fails (e.g., on secondary display), we'll gracefully skip
      final bool platformReady = await _waitForPlatformReady();
      if (!platformReady) {
        log(
          'Platform not ready for USB printer events - skipping (likely secondary display)',
        );
        return;
      }

      _usbEventSubscription = _eventChannel.receiveBroadcastStream().listen(
        (event) {
          _handleUsbEvent(event);
        },
        onError: (error) {
          log('Error in USB printer event stream: $error');
          // Don't retry if this is likely a secondary display issue
          if (!error.toString().contains('MissingPluginException')) {
            _retryStartListening();
          }
        },
      );

      log('USB printer event listener started successfully');
    } catch (e) {
      log('Failed to start USB printer event listener: $e');
      // Don't retry if this is a MissingPluginException (secondary display)
      if (!e.toString().contains('MissingPluginException')) {
        _retryStartListening();
      }
    }
  }

  /// Wait for platform to be ready by testing the method channel
  /// Returns true if platform is ready, false if not (e.g., secondary display)
  Future<bool> _waitForPlatformReady() async {
    const MethodChannel methodChannel = MethodChannel(
      'flutter_thermal_printer',
    );
    int attempts = 0;
    const maxAttempts = 5; // Reduced attempts for faster detection

    while (attempts < maxAttempts) {
      try {
        // Try to call a simple method to check if platform is ready
        await methodChannel.invokeMethod('getPlatformVersion');
        log('Platform is ready for USB printer events');
        return true;
      } catch (e) {
        attempts++;

        // If it's a MissingPluginException, this is likely a secondary display
        if (e.toString().contains('MissingPluginException')) {
          log(
            'MissingPluginException detected - likely secondary display, skipping USB printer',
          );
          return false;
        }

        log('Platform not ready yet, attempt $attempts/$maxAttempts: $e');
        if (attempts < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 300 * attempts));
        }
      }
    }

    log(
      'Platform readiness check failed after $maxAttempts attempts - likely secondary display',
    );
    return false;
  }

  /// Retry starting the listener after a delay
  /// Only retries if it's not a secondary display issue
  void _retryStartListening() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_usbEventSubscription == null) {
        log('Retrying to start USB printer event listener');
        startListening();
      }
    });
  }

  /// Stop listening to USB printer events
  Future<void> stopListening() async {
    try {
      if (_usbEventSubscription != null) {
        await _usbEventSubscription!.cancel();
        _usbEventSubscription = null;
        log('USB printer event listener stopped');
      }
    } catch (e) {
      log('Error stopping USB printer event listener: $e');
    }
  }

  /// Handle USB event from native side
  void _handleUsbEvent(dynamic event) {
    try {
      final Map<String, dynamic> eventData = Map<String, dynamic>.from(event);
      final String eventType = eventData['event'] ?? '';

      log('Received USB printer event: $eventType');
      log('Event data: $eventData');

      // Create printer model from event data
      final PrinterModel printer = PrinterModel(
        vendorId: eventData['vendorId']?.toString() ?? '',
        productId: eventData['productId']?.toString() ?? '',
        name: eventData['deviceName']?.toString() ?? 'Unknown USB Printer',
        connectionType: ConnectionTypeEnum.USB,
        address: '${eventData['vendorId']}:${eventData['productId']}',
        isConnected: eventType == 'connected',
      );

      switch (eventType) {
        case 'connected':
          _handlePrinterConnected(printer);
          break;
        case 'disconnected':
          _handlePrinterDisconnected(printer);
          break;
        case 'connection_failed':
          _handleConnectionFailed(
            printer,
            eventData['error']?.toString() ?? 'Unknown error',
          );
          break;
        default:
          log('Unknown USB printer event type: $eventType');
      }
    } catch (e) {
      log('Error handling USB printer event: $e');
    }
  }

  /// Handle printer connected event
  void _handlePrinterConnected(PrinterModel printer) {
    log('USB printer connected: ${printer.name} (${printer.address})');

    // Add to connected printers list if not already present
    final existingIndex = _connectedPrinters.indexWhere(
      (p) => p.address == printer.address,
    );

    if (existingIndex >= 0) {
      _connectedPrinters[existingIndex] = printer;
    } else {
      _connectedPrinters.add(printer);
    }

    // Call callback if set
    _onPrinterConnected?.call(printer);
  }

  /// Handle printer disconnected event
  void _handlePrinterDisconnected(PrinterModel printer) {
    log('USB printer disconnected: ${printer.name} (${printer.address})');

    // Remove from connected printers list
    _connectedPrinters.removeWhere((p) => p.address == printer.address);

    // Call callback if set
    _onPrinterDisconnected?.call(printer);
  }

  /// Handle connection failed event
  void _handleConnectionFailed(PrinterModel printer, String error) {
    log(
      'USB printer connection failed: ${printer.name} (${printer.address}) - $error',
    );

    // Call callback if set
    _onConnectionFailed?.call(printer, error);
  }

  /// Dispose the service
  void dispose() {
    stopListening();
    _connectedPrinters.clear();
    _onPrinterConnected = null;
    _onPrinterDisconnected = null;
    _onConnectionFailed = null;
  }
}
