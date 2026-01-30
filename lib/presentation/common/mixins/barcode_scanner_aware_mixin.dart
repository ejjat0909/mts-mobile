import 'package:flutter/material.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/providers/barcode_scanner/barcode_scanner_providers.dart';

mixin BarcodeScannerAwareMixin {
  void initScannerAware() {
    ServiceLocator.get<BarcodeScannerNotifier>().disposeScanner();
  }

  void disposeScannerAware() {
    ServiceLocator.get<BarcodeScannerNotifier>().initializeForSalesScreen();
  }
}

mixin BarcodeScannerAwareMixinState<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    ServiceLocator.get<BarcodeScannerNotifier>().disposeScanner();
  }

  @override
  void dispose() {
    ServiceLocator.get<BarcodeScannerNotifier>().initializeForSalesScreen();
    super.dispose();
  }
}
