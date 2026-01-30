import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:mts/core/services/usb_printer_service.dart';
import 'package:mts/plugins/flutter_thermal_printer/utils/printer.dart';

/// Mixin to handle USB printer events in app lifecycle
/// Use this mixin with StatefulWidget to automatically handle USB printer connections
mixin UsbPrinterLifecycleMixin<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  /// Override this method to handle when a USB printer is connected
  void onUsbPrinterConnected(PrinterModel printer) {
    log('USB printer connected: ${printer.name}');
    // Default implementation - override in your widget
  }

  /// Override this method to handle when a USB printer is disconnected
  void onUsbPrinterDisconnected(PrinterModel printer) {
    log('USB printer disconnected: ${printer.name}');
    // Default implementation - override in your widget
  }

  /// Override this method to handle when USB printer connection fails
  void onUsbPrinterConnectionFailed(PrinterModel printer, String error) {
    log('USB printer connection failed: ${printer.name} - $error');
    // Default implementation - override in your widget
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Delay the setup to ensure the app is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupUsbPrinterListener();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupUsbPrinterListener();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground, start listening to USB events
        _startUsbPrinterListener();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App is in background or being closed, stop listening
        _stopUsbPrinterListener();
        break;
      case AppLifecycleState.hidden:
        // App is hidden, stop listening
        _stopUsbPrinterListener();
        break;
    }
  }

  /// Setup USB printer event listeners
  void _setupUsbPrinterListener() {
    final service = UsbPrinterService.instance;

    // Set up callbacks
    service.setOnPrinterConnected(onUsbPrinterConnected);
    service.setOnPrinterDisconnected(onUsbPrinterDisconnected);
    service.setOnConnectionFailed(onUsbPrinterConnectionFailed);

    // Start listening
    _startUsbPrinterListener();
  }

  /// Start USB printer listener
  Future<void> _startUsbPrinterListener() async {
    try {
      await UsbPrinterService.instance.startListening();
    } catch (e) {
      log('Error starting USB printer listener: $e');
    }
  }

  /// Stop USB printer listener
  Future<void> _stopUsbPrinterListener() async {
    try {
      await UsbPrinterService.instance.stopListening();
    } catch (e) {
      log('Error stopping USB printer listener: $e');
    }
  }

  /// Cleanup USB printer listener
  void _cleanupUsbPrinterListener() {
    UsbPrinterService.instance.dispose();
  }

  /// Get currently connected USB printers
  List<PrinterModel> get connectedUsbPrinters {
    return UsbPrinterService.instance.connectedPrinters;
  }
}
