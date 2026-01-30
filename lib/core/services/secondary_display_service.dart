import 'package:flutter/widgets.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/plugins/presentation_displays/displaymanager.dart';

abstract class SecondaryDisplayService {
  GlobalKey<NavigatorState> get navigatorKey;

  void navigateTo(String routeName);

  /// Navigate to a specific screen on the second display
  Future<void> navigateSecondScreen(
    String routeName,
    DisplayManager displayManager, {
    Map<String, dynamic>? data,
    bool isShowLoading = true,
  });

  /// Optimized method for updating the second display without full navigation
  /// This method is more efficient for frequent updates when the display is already showing
  Future<void> updateSecondaryDisplay(
    DisplayManager displayManager,
    Map<String, dynamic> data,
  );

  Future<void> showMainCustomerDisplay();
  Future<SlideshowModel?> getLatestSlideshow();

  /// Stops displaying the secondary screen
  /// Returns true if successfully stopped, false otherwise
  Future<bool> stopSecondaryDisplay(DisplayManager displayManager);
}
