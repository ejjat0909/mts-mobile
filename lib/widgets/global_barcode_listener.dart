import 'package:flutter/material.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/providers/barcode_scanner/barcode_scanner_providers.dart';

/// Global keyboard listener widget for capturing barcode scanner input
class GlobalBarcodeListener extends StatefulWidget {
  final Widget child;

  const GlobalBarcodeListener({super.key, required this.child});

  @override
  State<GlobalBarcodeListener> createState() => _GlobalBarcodeListenerState();
}

class _GlobalBarcodeListenerState extends State<GlobalBarcodeListener> {
  late final BarcodeScannerNotifier _barcodeNotifier;

  @override
  void initState() {
    super.initState();
    _barcodeNotifier = ServiceLocator.get<BarcodeScannerNotifier>();
  }

  /// Check if any text field is currently focused
  bool _isTextFieldFocused() {
    final FocusNode? focusedNode = FocusManager.instance.primaryFocus;
    return focusedNode != null && focusedNode.hasFocus;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      canRequestFocus:
          true, // Changed to false to avoid stealing focus from text fields
      onKeyEvent: (node, event) {
        // Don't handle key events if a text field is currently focused
        // if (_isTextFieldFocused()) {
        //   prints('FOCUSED');
        //   return KeyEventResult.ignored;
        // }

        // Handle the key event through the barcode scanner service
        final handled = _barcodeNotifier.scannerService.handleKeyEvent(event);

        // Return appropriate key event result
        return handled ? KeyEventResult.handled : KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}
