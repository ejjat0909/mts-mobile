import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';

/// Network utility functions
class NetworkUtils {
  /// Check if device has internet connection
  static Future<bool> hasInternetConnection() async {
    try {
      final connectivityResults = await (Connectivity().checkConnectivity());

      if (connectivityResults.any(
        (element) =>
            element == ConnectivityResult.mobile ||
            element == ConnectivityResult.wifi ||
            element == ConnectivityResult.ethernet,
      )) {
        // Connected to a mobile or wifi network
        // For low-end devices, also verify actual connectivity with a quick ping
        try {
          final result = await InternetAddress.lookup(
            'google.com',
          ).timeout(const Duration(seconds: 5));
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            return true;
          }
        } catch (e) {
          // Lookup failed, no actual internet
          prints('Internet lookup failed: $e');
          return false;
        }
        return true;
      }
      return false;
    } catch (e) {
      prints('Error checking internet connection: $e');
      return false;
    }
  }

  /// Check if device has actual internet connectivity by making a real HTTP request
  static Future<bool> hasActualInternetConnection() async {
    try {
      // First check basic connectivity
      if (!await hasInternetConnection()) {
        prints('NO INTERENT CONNECTION');
        return false;
      }

      // Try to make a simple HTTP request to a reliable endpoint
      final response = await http
          .get(
            Uri.parse('https://www.google.com'),
            headers: {'Connection': 'close'},
          )
          .timeout(const Duration(seconds: 30));
      //  prints("GOOGLE STATUS CODE ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      // Any exception means no internet connectivity
      return false;
    }
  }

  static void noInternetDialog(BuildContext context) {
    CustomDialog.show(
      context,
      dialogType: DialogType.danger,
      icon: Icons.wifi_off_outlined,
      title: 'noInternet'.tr(),
      description: 'pleaseConnectInternet'.tr(),
      btnOkText: 'ok'.tr(),
      btnOkOnPress: () => NavigationUtils.pop(context),
    );
  }

  /// Save log to file
  static Future<void> saveLog(String message) async {
    try {
      // Get the document directory
      final Directory appDocDir = await Directory.systemTemp.createTemp('logs');
      final String logFilePath = '${appDocDir.path}/app_log.txt';

      // Create the log file if it doesn't exist
      final File logFile = File(logFilePath);
      if (!await logFile.exists()) {
        await logFile.create();
      }

      // Get the current timestamp
      final String timestamp = DateTime.now().toString();

      // Append the log message with timestamp
      await logFile.writeAsString(
        '[$timestamp] $message\n',
        mode: FileMode.append,
      );
    } catch (e) {
      prints('Error saving log: $e');
    }
  }
}
