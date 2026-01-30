import 'dart:io';

import 'package:mts/core/utils/log_utils.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permission utility functions
class PermissionUtils {
  /// Request storage permission
  static Future<PermissionStatus> requestStoragePermission() async {
    try {
      return await Permission.storage.request();
    } catch (e) {
      prints('Error requesting storage permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Request bluetooth permission
  static Future<PermissionStatus> requestBluetoothPermission() async {
    try {
      return await Permission.bluetooth.request();
    } catch (e) {
      prints('Error requesting bluetooth permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Request bluetooth connect permission
  static Future<PermissionStatus> requestBluetoothConnectPermission() async {
    try {
      if (Platform.isAndroid && await _isAndroidVersionAtLeast(31)) {
        return await Permission.bluetoothConnect.request();
      }
      return PermissionStatus.granted;
    } catch (e) {
      prints('Error requesting bluetooth connect permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Request bluetooth scan permission
  static Future<PermissionStatus> requestBluetoothScanPermission() async {
    try {
      if (Platform.isAndroid && await _isAndroidVersionAtLeast(31)) {
        return await Permission.bluetoothScan.request();
      }
      return PermissionStatus.granted;
    } catch (e) {
      prints('Error requesting bluetooth scan permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Request location permission
  static Future<PermissionStatus> requestLocationPermission() async {
    try {
      return await Permission.location.request();
    } catch (e) {
      prints('Error requesting location permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Request camera permission
  static Future<PermissionStatus> requestCameraPermission() async {
    try {
      return await Permission.camera.request();
    } catch (e) {
      prints('Error requesting camera permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Request microphone permission
  static Future<PermissionStatus> requestMicrophonePermission() async {
    try {
      return await Permission.microphone.request();
    } catch (e) {
      prints('Error requesting microphone permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Check if storage permission is granted
  static Future<bool> isStoragePermissionGranted() async {
    try {
      return await Permission.storage.isGranted;
    } catch (e) {
      prints('Error checking storage permission: $e');
      return false;
    }
  }

  /// Check if bluetooth permission is granted
  static Future<bool> isBluetoothPermissionGranted() async {
    try {
      return await Permission.bluetooth.isGranted;
    } catch (e) {
      prints('Error checking bluetooth permission: $e');
      return false;
    }
  }

  /// Check if bluetooth connect permission is granted
  static Future<bool> isBluetoothConnectPermissionGranted() async {
    try {
      if (Platform.isAndroid && await _isAndroidVersionAtLeast(31)) {
        return await Permission.bluetoothConnect.isGranted;
      }
      return true;
    } catch (e) {
      prints('Error checking bluetooth connect permission: $e');
      return false;
    }
  }

  /// Check if bluetooth scan permission is granted
  static Future<bool> isBluetoothScanPermissionGranted() async {
    try {
      if (Platform.isAndroid && await _isAndroidVersionAtLeast(31)) {
        return await Permission.bluetoothScan.isGranted;
      }
      return true;
    } catch (e) {
      prints('Error checking bluetooth scan permission: $e');
      return false;
    }
  }

  /// Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    try {
      return await Permission.location.isGranted;
    } catch (e) {
      prints('Error checking location permission: $e');
      return false;
    }
  }

  /// Check if camera permission is granted
  static Future<bool> isCameraPermissionGranted() async {
    try {
      return await Permission.camera.isGranted;
    } catch (e) {
      prints('Error checking camera permission: $e');
      return false;
    }
  }

  /// Check if microphone permission is granted
  static Future<bool> isMicrophonePermissionGranted() async {
    try {
      return await Permission.microphone.isGranted;
    } catch (e) {
      prints('Error checking microphone permission: $e');
      return false;
    }
  }

  /// Request all necessary permissions for the app
  static Future<void> requestAllPermissions() async {
    try {
      // Add a short delay to ensure the activity is fully initialized
      await Future.delayed(const Duration(milliseconds: 500));

      // Request storage permission
      // to save image item and log files
      await requestStoragePermission();

      // Request bluetooth permissions if on Android
      if (Platform.isAndroid) {
        await requestBluetoothPermission();

        // These permissions are only needed on Android 12+
        if (await _isAndroidVersionAtLeast(31)) {
          await requestBluetoothConnectPermission();
          await requestBluetoothScanPermission();
        }
      }

      // Request location permissions (needed for Bluetooth scanning)
      await requestLocationPermission();
    } catch (e) {
      prints('Error requesting all permissions: $e');
    }
  }

  /// Check if the Android version is at least the specified version
  static Future<bool> _isAndroidVersionAtLeast(int version) async {
    if (!Platform.isAndroid) return false;

    try {
      final sdkInt = await _getAndroidSdkVersion();
      return sdkInt >= version;
    } catch (e) {
      prints('Error checking Android version: $e');
      return false;
    }
  }

  /// Get the Android SDK version
  static Future<int> _getAndroidSdkVersion() async {
    try {
      // This is a placeholder. In a real implementation, you would use
      // a platform channel or a plugin to get the actual SDK version.
      // For now, we'll assume Android 12 (SDK 31) or higher
      return 31;
    } catch (e) {
      prints('Error getting Android SDK version: $e');
      return 0;
    }
  }
}
