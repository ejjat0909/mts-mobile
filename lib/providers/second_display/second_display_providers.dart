import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/services/secondary_display_service.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/plugins/presentation_displays/displaymanager.dart';
import 'package:mts/presentation/features/customer_display_preview/main_customer_display.dart';
import 'package:mts/presentation/features/home/home_screen.dart';
import 'package:mts/presentation/features/sales/components/menu_item.dart';
import 'package:mts/main.dart' as main;
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/modifier_option/modifier_option_providers.dart';
import 'package:mts/providers/second_display/second_display_state.dart';

/// StateNotifier for SecondDisplay domain
class SecondDisplayNotifier extends StateNotifier<SecondDisplayState> {
  final Ref _ref;
  SecondDisplayNotifier(this._ref) : super(const SecondDisplayState());

  String get getCurrentRouteName => state.currentRouteName;
  SlideshowModel? get getCurrentSdModel => state.currentSdModel;

  static const String keySdRouteName = 'current_sd_route_name';
  static const String keySdModel = 'current_sd_model';

  void setCurrentRouteName(String routeName, {bool preventAutoSync = true}) {
    state = state.copyWith(currentRouteName: routeName);
    // final secureStorage = ServiceLocator.get<SecureStorageApi>();
    // await secureStorage.write(keySdRouteName, routeName);
  }

  void setCurrSdModel(SlideshowModel? model) {
    state = state.copyWith(currentSdModel: model);
    // await secureStorage.saveObject(keySdModel, model);
  }

  void reset() {
    state = const SecondDisplayState();
  }

  /// Optimized method for updating the second display without full navigation
  Future<void> updateSecondaryDisplay(Map<String, dynamic> data) async {
    if (!main.hasSecondaryDisplay || main.secondaryDisplayId == null) {
      return;
    }

    if (!data.containsKey(DataEnum.listItems) &&
        !data.containsKey(DataEnum.listMO)) {
      if (MenuItem.isCacheInitialized()) {
        final cachedData = MenuItem.getCachedCommonData();
        data.addEntries([
          MapEntry(DataEnum.listItems, cachedData[DataEnum.listItems]),
          MapEntry(DataEnum.listMO, cachedData[DataEnum.listMO]),
        ]);
      } else {
        final listItemFromNotifier = _ref.read(itemProvider).items;
        final listMoFromNotifier = _ref.read(modifierOptionProvider).items;

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
      }
    }

    final displayManager = _ref.read(displayManagerProvider);
    await displayManager.transferDataToPresentation(data);
  }

  /// Navigate or update the second screen depending on route switch
  Future<void> navigateSecondScreen(
    String routeName, {
    Map<String, dynamic>? data,
    bool isShowLoading = true,
  }) async {
    if (!main.hasSecondaryDisplay || main.secondaryDisplayId == null) {
      return;
    }

    bool isSwitchScreen = false;
    final currRouteName = state.currentRouteName;

    if (currRouteName != routeName) {
      setCurrentRouteName(routeName, preventAutoSync: true);
      isSwitchScreen = true;
    }

    final displayManager = _ref.read(displayManagerProvider);
    if (currRouteName != routeName) {
      await displayManager.showSecondaryDisplay(
        displayId: main.secondaryDisplayId!,
        routerName: routeName,
      );
    }

    if (data != null && !isSwitchScreen) {
      await updateSecondaryDisplay(data);
    } else if (data != null) {
      if (!data.containsKey(DataEnum.listItems) ||
          !data.containsKey(DataEnum.listMO)) {
        if (routeName != MainCustomerDisplay.routeName) {
          final listItemFromNotifier = _ref.read(itemProvider).items;
          final listMoFromNotifier = _ref.read(modifierOptionProvider).items;
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
        }
      }
      await displayManager.transferDataToPresentation(data);
    }
  }

  /// Show main customer display asynchronously using slideshow cache
  Future<void> showMainCustomerDisplay() async {
    scheduleMicrotask(() async {
      try {
        Home.resetSecondDisplayInitialization();

        SlideshowModel? sdModel;

        if (Home.isSlideshowCacheInitialized()) {
          sdModel = Home.getCachedSlideshowModel();
        } else {
          await Home.ensureSlideshowCacheInitialized();
          sdModel = Home.getCachedSlideshowModel();
        }

        await Future.delayed(const Duration(milliseconds: 10));

        final dataWelcome = {DataEnum.slideshow: sdModel?.toJson() ?? {}};

        await navigateSecondScreen(
          MainCustomerDisplay.routeName,
          data: dataWelcome,
        );
      } catch (_) {
        try {
          await navigateSecondScreen(
            MainCustomerDisplay.routeName,
            data: {DataEnum.slideshow: {}},
          );
        } catch (_) {}
      }
    });
  }

  /// Stop any active secondary displays and reset state
  Future<bool> stopSecondaryDisplay() async {
    try {
      setCurrentRouteName('', preventAutoSync: true);
      if (state.currentSdModel != null) {
        setCurrSdModel(null);
      }

      if (!main.hasSecondaryDisplay || main.secondaryDisplayId == null) {
        return true;
      }

      try {
        final displayManager = _ref.read(displayManagerProvider);
        final dismissedCount = await displayManager.hideAllSecondaryDisplays();
        await Future.delayed(const Duration(milliseconds: 500));
        return true;
      } catch (_) {
        return true;
      }
    } catch (_) {
      return false;
    }
  }
}

/// Provider for secondDisplay domain
final secondDisplayProvider =
    StateNotifierProvider<SecondDisplayNotifier, SecondDisplayState>((ref) {
      return SecondDisplayNotifier(ref);
    });

/// Provider for current route name
final secondDisplayCurrentRouteNameProvider = Provider<String>((ref) {
  return ref.watch(secondDisplayProvider).currentRouteName;
});

/// Provider for current slideshow model
final secondDisplayCurrentSdModelProvider = Provider<SlideshowModel?>((ref) {
  return ref.watch(secondDisplayProvider).currentSdModel;
});

/// Provider for checking if slideshow model is set
final secondDisplayHasSdModelProvider = Provider<bool>((ref) {
  return ref.watch(secondDisplayProvider).currentSdModel != null;
});

/// Provider for SecondaryDisplayService to replace direct ServiceLocator access
final secondaryDisplayServiceProvider = Provider<SecondaryDisplayService>((_) {
  return ServiceLocator.get<SecondaryDisplayService>();
});

/// Provider for DisplayManager instance
final displayManagerProvider = Provider<DisplayManager>((ref) {
  return main.displayManager;
});
