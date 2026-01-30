import 'dart:convert'; // Import the dart:convert package for JSON operations

import 'package:flutter/services.dart';
import 'package:mts/core/utils/log_utils.dart';

class DisplayManager {
  static const MethodChannel _channel = MethodChannel(
    'presentation_displays_plugin',
  );

  //late EventChannel? _displayEventChannel;
  // final _displayEventChannelId = "presentation_displays_plugin_events";

  DisplayManager() {
    // _displayEventChannel = EventChannel(_displayEventChannelId);
  }

  Future<List<Display>> getDisplays() async {
    // The result is expected to be a JSON string representing a list
    final String result = await _channel.invokeMethod('listDisplay');

    // Decode the JSON string to a List<dynamic>
    final List<dynamic> list = json.decode(result);

    // Map each item to a Display object
    return list.map((item) => Display.fromJson(item)).toList();
  }

  Future<void> showSecondaryDisplay({
    required String displayId,
    required String routerName,
  }) async {
    await _channel.invokeMethod('showPresentation', {
      'displayId': displayId,
      'routerName': routerName,
    });
  }

  /// Hide a specific secondary display by its display ID
  /// Returns true if the presentation was successfully dismissed,
  /// false if no presentation was found for the given display ID
  Future<bool?> hideSecondaryDisplay({required String displayId}) async {
    const hidePresentation = "hidePresentation";

    try {
      // Convert displayId to int if possible
      int displayIdInt =
          int.tryParse(displayId) ?? 1; // Default to 1 if parsing fails

      // Create the JSON string exactly as expected by the Java code
      String jsonParam = "{\"displayId\": $displayIdInt}";

      prints("Hiding presentation for display ID: $displayId");
      bool? result = await _channel.invokeMethod<bool?>(
        hidePresentation,
        jsonParam,
      );

      if (result == true) {
        prints("✅ Presentation for display $displayId successfully dismissed");
      } else if (result == false) {
        prints("⚠️ No presentation found for display $displayId");
      }

      return result;
    } catch (e) {
      prints("❌ Failed to hide display $displayId: $e");
      return false;
    }
  }

  /// Hide all active presentations
  Future<int?> hideAllSecondaryDisplays() async {
    const hideAllPresentations = "hideAllPresentations";

    try {
      prints("Hiding all secondary displays...");
      int? dismissedCount = await _channel.invokeMethod<int?>(
        hideAllPresentations,
      );

      if (dismissedCount != null && dismissedCount > 0) {
        prints("Successfully dismissed $dismissedCount presentations");
      } else {
        prints("No presentations were active to dismiss");
      }

      return dismissedCount;
    } catch (e) {
      prints("Failed to hide all displays: $e");
      return null;
    }
  }

  /// Get the count of currently active presentations
  Future<int?> getActivePresentationsCount() async {
    const getActivePresentationsCount = "getActivePresentationsCount";

    try {
      int? count = await _channel.invokeMethod<int?>(
        getActivePresentationsCount,
      );
      prints("Active presentations count: $count");
      return count;
    } catch (e) {
      prints("Failed to get active presentations count: $e");
      return null;
    }
  }

  Future<String?> getNameById(String index, {String? category}) async {
    List<Display> displays = await getDisplays();
    String? name;
    int? idx = int.tryParse(index);

    if (idx != null && idx >= 0) {
      for (Display display in displays) {
        if (display.a == index) name = display.d;
      }
    }

    return name;
  }

  Future<void> transferDataToPresentation(dynamic data) async {
    await _channel.invokeMethod('transferDataToPresentation', data);
  }

  // Stream<int?>? get connectedDisplaysChangedStream {
  //   final _displayEventChannelId = "presentation_displays_plugin_events";
  //   return _displayEventChannel?.receiveBroadcastStream().cast();
  // }
}

class Display {
  final String a;
  final String b;
  final String c;
  final String d;

  Display(this.a, this.b, this.c, this.d);

  factory Display.fromJson(Map<String, dynamic> json) {
    return Display(
      json['a'].toString(),
      json['b'].toString(),
      json['c'].toString(),
      json['d'].toString(),
    );
  }
}
