import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/enum/db_response_enum.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/main.dart' as main;
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/core/services/secondary_display_service.dart';
import 'package:mts/domain/repositories/local/slideshow_repository.dart';
import 'package:mts/plugins/presentation_displays/displaymanager.dart';
import 'package:mts/presentation/features/customer_display_preview/main_customer_display.dart';
import 'package:mts/presentation/features/home/home_screen.dart';
import 'package:mts/providers/item_notifier.dart';
import 'package:mts/providers/modifier_option_notifier.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';
import 'package:mts/presentation/features/sales/components/menu_item.dart';

class SecondaryDisplayServiceImpl implements SecondaryDisplayService {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  SecondaryDisplayServiceImpl({required SecureStorageApi secureStorageApi});

  factory SecondaryDisplayServiceImpl.fromServiceLocator() {
    return SecondaryDisplayServiceImpl(
      secureStorageApi: ServiceLocator.get<SecureStorageApi>(),
    );
  }

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  @override
  void navigateTo(String routeName) {
    navigatorKey.currentState?.pushNamed(routeName);
  }

  /// Optimized method for updating the second display without full navigation
  /// This method is more efficient for frequent updates when the display is already showing
  @override
  Future<void> updateSecondaryDisplay(
    DisplayManager displayManager,
    Map<String, dynamic> data,
  ) async {
    // Early return if no secondary display available
    if (!main.hasSecondaryDisplay || main.secondaryDisplayId == null) {
      LogUtils.info('No secondary display available for update');
      return;
    }

    // Skip display detection - use cached values
    // Transfer data directly since we know display exists
    // prints(
    //   "🔍 DEBUG: Checking data keys - listItems: ${data.containsKey(DataEnum.listItems)}, listMO: ${data.containsKey(DataEnum.listMO)}",
    // );
    // prints("🔍 DEBUG: Data keys: ${data.keys.toList()}");

    if (!data.containsKey(DataEnum.listItems) &&
        !data.containsKey(DataEnum.listMO)) {
      prints("ℹ️ TAK CONTAINS CACHE......TAPI NAK UPDATE DATA");

      // Use cached data instead of fetching from notifiers for better performance
      if (MenuItem.isCacheInitialized()) {
        final cachedData = MenuItem.getCachedCommonData();
        data.addEntries([
          MapEntry(DataEnum.listItems, cachedData[DataEnum.listItems]),
          MapEntry(DataEnum.listMO, cachedData[DataEnum.listMO]),
        ]);
        prints('✅ Added cached data to second display');
      } else {
        // Fallback to notifiers if cache is not available
        final listItemFromNotifier =
            ServiceLocator.get<ItemNotifier>().getListItems;
        final listMoFromNotifier =
            ServiceLocator.get<ModifierOptionNotifier>().getModifierOptionList;

        data.addEntries([
          MapEntry(
            DataEnum.listItems,
            listItemFromNotifier.map((e) => e.toJson()).toList(),
          ),
          MapEntry(
            DataEnum.listMO,
            listMoFromNotifier.map((e) => e.toJson()).toList(),
          ),
        ]);
        prints('⚠️ Used notifiers as fallback for second display data');
      }
    } else {
      prints("✅ DAH CONTAINS CACHE .... TAK PERLU BUAT APE APE");
    }

    await displayManager.transferDataToPresentation(data);
  }

  @override
  Future<void> navigateSecondScreen(
    String routeName,
    DisplayManager displayManager, {
    Map<String, dynamic>? data,
    bool isShowLoading = true,
  }) async {
    // Early return if no secondary display available
    if (!main.hasSecondaryDisplay || main.secondaryDisplayId == null) {
      LogUtils.info(
        'No secondary display available for navigation to: $routeName',
      );
      return;
    }

    bool isSwitchScreen = false;
    SecondDisplayNotifier sdn = ServiceLocator.get<SecondDisplayNotifier>();
    String currRouteName = sdn.getCurrentRouteName;

    if (currRouteName != routeName) {
      sdn.setCurrentRouteName(routeName, preventAutoSync: true);
      isSwitchScreen = true;
    }

    // Use cached display ID directly
    if (currRouteName != routeName) {
      final stopwatch = Stopwatch()..start();

      await displayManager.showSecondaryDisplay(
        displayId: main.secondaryDisplayId!,
        routerName: routeName,
      );

      stopwatch.stop();
      prints(
        'Secondary display switch took: ${stopwatch.elapsedMilliseconds}ms',
      );
    }

    // Handle data transfer with optimized logic
    if (data != null && !isSwitchScreen) {
      await updateSecondaryDisplay(displayManager, data);
    } else if (data != null) {
      // Prepare data for full navigation
      // prints(
      //   "🔍 DEBUG navigateSecondScreen: Checking data keys - listItems: ${data.containsKey(DataEnum.listItems)}, listMO: ${data.containsKey(DataEnum.listMO)}",
      // );
      // prints("🔍 DEBUG navigateSecondScreen: Data keys: ${data.keys.toList()}");

      if (!data.containsKey(DataEnum.listItems) ||
          !data.containsKey(DataEnum.listMO)) {
        prints("ℹ️ TAK CONTAINS CACHE......CHECKING ROUTENAME");
        if (routeName != MainCustomerDisplay.routeName) {
          // means nak show list items, masukkan cache

          prints(
            "ℹ️ ROUTENAME BUKAN MAIN CUSTOMER DISPLAY PERLU MASUKKAN CACHE KALAU TAK INIT LAGI",
          );
          final listItemFromNotifier =
              ServiceLocator.get<ItemNotifier>().getListItems;
          final listMoFromNotifier =
              ServiceLocator.get<ModifierOptionNotifier>()
                  .getModifierOptionList;

          data.addEntries([
            MapEntry(
              DataEnum.listItems,
              listItemFromNotifier.map((e) => e.toJson()).toList(),
            ),
            MapEntry(
              DataEnum.listMO,
              listMoFromNotifier.map((e) => e.toJson()).toList(),
            ),
          ]);
        } else {
          prints(
            "ℹ️ ROUTENAME ADALAH MAIN CUSTOMER DISPLAY TAK PERLU MASUKKAN CACHE",
          );
        }
      } else {
        prints("ℹ️ DAH CONTAINS CACHE");
      }
      await displayManager.transferDataToPresentation(data);
    }

    // List<Display?> displays = [];

    //   AUTO DETECT AND CONNECT TO SCREEN
    // final values = await displayManager.getDisplays();
    // displays.addAll(values as Iterable<Display?>);
    // if (displays.length > 1) {
    //   String? x = displays[1]!.a;
    //   displayManager.showSecondaryDisplay(
    //     displayId: x ?? "0",
    //     routerName: routeName,
    //   );
    // }

    // if (data != null) {
    //   await displayManager.transferDataToPresentation(data);
    // } else {
    //   prints("DATA WANT TO DISPLAY IS NULL, NO DATA TO TRANSFER");
    //   LogUtils.error("DATA WANT TO DISPLAY IS NULL, NO DATA TO TRANSFER");
    // }
  }

  @override
  Future<void> showMainCustomerDisplay() async {
    // Don't block UI - run completely asynchronously like in home_screen.dart
    unawaited(_showMainCustomerDisplayOptimized());
  }

  /// Optimized main customer display that doesn't block the UI thread
  /// Uses cached slideshow data and runs asynchronously to prevent lag and button blocking
  Future<void> _showMainCustomerDisplayOptimized() async {
    // Use microtask to ensure this runs after the current frame and doesn't block UI
    scheduleMicrotask(() async {
      try {
        // Reset second display initialization flag to allow faster subsequent interactions
        // This treats the next item selection as a "first item" for immediate response
        Home.resetSecondDisplayInitialization();

        // Use cached slideshow data from home_screen.dart to prevent lag
        SlideshowModel? sdModel;

        if (Home.isSlideshowCacheInitialized()) {
          // Use cached data - no database call needed
          sdModel = Home.getCachedSlideshowModel();
          LogUtils.info(
            'Using cached slideshow data for main customer display',
          );
        } else {
          // Fallback to database call if cache is not initialized
          // This ensures slideshow cache is available for future calls
          LogUtils.info('Slideshow cache not initialized, initializing now...');
          await Home.ensureSlideshowCacheInitialized();
          sdModel = Home.getCachedSlideshowModel();
        }

        // Minimal delay to ensure UI is fully rendered and responsive
        // Reduced from 150ms to 10ms to prevent interaction blocking
        await Future.delayed(const Duration(milliseconds: 10));

        Map<String, dynamic> dataWelcome = {
          DataEnum.slideshow: sdModel?.toJson() ?? {},
        };

        await navigateSecondScreen(
          MainCustomerDisplay.routeName,
          main.displayManager,
          data: dataWelcome,
        );

        LogUtils.info(
          '✅ Main customer display shown asynchronously - UI remains responsive',
        );
      } catch (error) {
        LogUtils.error('❌ Error showing main customer display: $error');

        // Fallback with minimal data
        try {
          await navigateSecondScreen(
            MainCustomerDisplay.routeName,
            main.displayManager,
            data: {DataEnum.slideshow: {}},
          );
        } catch (fallbackError) {
          LogUtils.error(
            '❌ Error in fallback main customer display: $fallbackError',
          );
        }
      }
    });
  }

  @override
  Future<SlideshowModel?> getLatestSlideshow() async {
    final LocalSlideshowRepository localSlideshowRepository =
        ServiceLocator.get<LocalSlideshowRepository>();

    Map<String, dynamic> response =
        await localSlideshowRepository.getLatestModel();
    return response[DbResponseEnum.data];
  }

  @override
  Future<bool> stopSecondaryDisplay(DisplayManager displayManager) async {
    try {
      // Reset state in notifier regardless of display existence
      SecondDisplayNotifier sdn = ServiceLocator.get<SecondDisplayNotifier>();
      sdn.setCurrentRouteName('', preventAutoSync: true);

      if (sdn.getCurrentSdModel != null) {
        sdn.setCurrSdModel(null);
      }

      // Early return if no secondary display available
      if (!main.hasSecondaryDisplay || main.secondaryDisplayId == null) {
        LogUtils.info('No secondary display found to stop');
        return true;
      }

      // Hide all secondary displays instead of just one specific display
      try {
        LogUtils.info('Attempting to stop all secondary displays...');

        final dismissedCount = await displayManager.hideAllSecondaryDisplays();

        if (dismissedCount != null && dismissedCount > 0) {
          LogUtils.info(
            'Successfully stopped $dismissedCount secondary display(s)',
          );
        } else {
          LogUtils.info('No active secondary displays found to stop');
        }

        await Future.delayed(const Duration(milliseconds: 500));
        return true;
      } catch (e) {
        LogUtils.error('Error calling hideAllSecondaryDisplays: $e');
        return true; // Partial success since we reset the state
      }
    } catch (e) {
      LogUtils.error('Error stopping secondary display: $e');
      return false;
    }
  }
}
