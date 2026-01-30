// Example usage of the updated DisplayManager with multiple display support

import 'package:mts/core/utils/log_utils.dart';

import 'displaymanager.dart';

class DisplayManagerExample {
  final DisplayManager _displayManager = DisplayManager();

  /// Example: Show presentations on multiple displays
  Future<void> showMultipleDisplays() async {
    try {
      // Show presentation on display 1
      await _displayManager.showSecondaryDisplay(
        displayId: '1',
        routerName: '/customer_display',
      );

      // Show presentation on display 2
      await _displayManager.showSecondaryDisplay(
        displayId: '2',
        routerName: '/kitchen_display',
      );

      prints('Multiple displays shown successfully');
    } catch (e) {
      prints('Error showing multiple displays: $e');
    }
  }

  /// Example: Hide a specific display
  Future<void> hideSpecificDisplay(String displayId) async {
    try {
      bool? result = await _displayManager.hideSecondaryDisplay(
        displayId: displayId,
      );

      if (result == true) {
        prints('Display $displayId hidden successfully');
      } else {
        prints('Display $displayId was not active or not found');
      }
    } catch (e) {
      prints('Error hiding display $displayId: $e');
    }
  }

  /// Example: Hide all displays at once
  Future<void> hideAllDisplays() async {
    try {
      int? dismissedCount = await _displayManager.hideAllSecondaryDisplays();

      if (dismissedCount != null && dismissedCount > 0) {
        prints('Successfully hidden $dismissedCount displays');
      } else {
        prints('No displays were active');
      }
    } catch (e) {
      prints('Error hiding all displays: $e');
    }
  }

  /// Example: Check how many displays are currently active
  Future<void> checkActiveDisplays() async {
    try {
      int? count = await _displayManager.getActivePresentationsCount();

      if (count != null) {
        prints('Currently $count displays are active');
      } else {
        prints('Could not get active display count');
      }
    } catch (e) {
      prints('Error checking active displays: $e');
    }
  }

  /// Example: Complete workflow - show, check, and hide displays
  Future<void> completeWorkflow() async {
    prints('=== Starting Display Manager Workflow ===');

    // 1. Check initial state
    await checkActiveDisplays();

    // 2. Show multiple displays
    await showMultipleDisplays();

    // 3. Check how many are now active
    await checkActiveDisplays();

    // 4. Hide a specific display
    await hideSpecificDisplay('1');

    // 5. Check remaining active displays
    await checkActiveDisplays();

    // 6. Hide all remaining displays
    await hideAllDisplays();

    // 7. Final check
    await checkActiveDisplays();

    prints('=== Workflow Complete ===');
  }
}

/// Usage in your app:
/// 
/// ```dart
/// final example = DisplayManagerExample();
/// 
/// // Hide a specific customer display
/// await example.hideSpecificDisplay('2');
/// 
/// // Hide all displays when closing the app
/// await example.hideAllDisplays();
/// 
/// // Check if any displays are still active
/// await example.checkActiveDisplays();
/// ```