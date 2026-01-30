import 'package:flutter/services.dart';
import 'package:mts/core/utils/log_utils.dart';

class BluetoothGatt {
  static const MethodChannel _channel = MethodChannel('bluetooth_gatt_utils');

  /// Forces closing the BluetoothGatt connection on Android.
  static Future<void> forceCloseGatt(String deviceAddress) async {
    try {
      await _channel.invokeMethod('forceCloseGatt', {'device': deviceAddress});
    } on PlatformException catch (e) {
      // Handle error or log
      prints('Failed to close GATT connection: ${e.message}');
    }
  }

  static Future<void> connectToMac(String mac) async {
    try {
      await _channel.invokeMethod('connectToMacAddress', {"macAddress": mac});
    } on PlatformException catch (e) {
      // Handle error or log
      prints('Failed to connect to Mac address: ${e.message}');
    }
  }
}
