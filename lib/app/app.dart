import 'dart:async';
import 'dart:ui';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/config/settings_controller.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/presentation/features/after_login/after_login_screen.dart';
import 'package:mts/presentation/features/customer_display_preview/main_customer_display.dart';
import 'package:mts/presentation/features/customer_display_preview/main_customer_display_show_receipt.dart';
import 'package:mts/presentation/features/barcode_test/barcode_test_screen.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/widgets/global_barcode_listener.dart';
import 'package:mts/core/mixins/usb_printer_lifecycle_mixin.dart';
import 'package:mts/plugins/flutter_thermal_printer/utils/printer.dart';

/// App widget
class App extends StatefulWidget {
  /// Settings controller
  final SettingsController settingsController;

  /// Initial route
  final Widget initialRoute;

  /// Constructor
  const App({
    super.key,
    required this.settingsController,
    required this.initialRoute,
  });

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App>
    with WidgetsBindingObserver, UsbPrinterLifecycleMixin {
  // Stream controller for showing the lock screen
  final StreamController<bool> _showLockScreenStream = StreamController();
  Locale deviceLocale = window.locale;
  String localeDevice = '';
  bool _isAppJustStarted = true;

  // Subscription to listen for changes in the lock screen stream
  StreamSubscription? _showPinLockScreen;

  // Flag to track if notification bar is being pulled down
  bool _isNotificationBarVisible = false;
  double _previousTopPadding = 0.0;

  Future<void> _showLockScreenDialog() async {
    final secureStorageApi = ServiceLocator.get<SecureStorageApi>();
    final DeviceFacade deviceFacade = ServiceLocator.get<DeviceFacade>();
    PosDeviceModel posDeviceModel = await deviceFacade.getLatestDeviceModel();
    final dialogueNav = ServiceLocator.get<MyNavigatorNotifier>();
    final userToken = await secureStorageApi.read(key: 'access_token');
    final staffToken = await secureStorageApi.read(key: 'staff_access_token');
    final token =
        staffToken.isNotEmpty
            ? staffToken
            : (userToken.isNotEmpty ? userToken : '');

    if (token.isNotEmpty && posDeviceModel.id != null) {
      prints('PUSH REPLACEMENT');
      prints('LAST PAGE INDEX ${dialogueNav.lastPageIndex}');
      // last page index 1000
      // page index 2
      prints('  PAGE INDEX ${dialogueNav.pageIndex}');
      // cannot use lastPageIndex and pageIndex because they pageIndex will still 2
      // and lastPageIndex cannot be 2
      if (dialogueNav.lastScreenIndex != 2 &&
          dialogueNav.lastScreenIndex != 3 &&
          dialogueNav.lastScreenIndex != 4 &&
          dialogueNav.lastScreenIndex != 5) {
        navigatorKey.currentState?.push(
          CupertinoPageRoute(
            builder: (BuildContext context) {
              return const AfterLoginScreen();
            },
          ),
        );
      }
    } else {
      // navigatorKey.currentState?.pushReplacement(
      //   CupertinoPageRoute(
      //     builder: (BuildContext context) {
      //       return const LicenseScreen();
      //     },
      //   ),
      // );
    }
  }

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    WidgetsBinding.instance.addObserver(this);
    localeDevice = '${deviceLocale.languageCode}-${deviceLocale.countryCode}';

    // Initialize the previous top padding
    _previousTopPadding = WidgetsBinding.instance.window.padding.top;

    // App just started logic here
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isAppJustStarted) {
        //  _handleAppStart();
        _isAppJustStarted = false;
      }
    });

    // Listen for changes in the lock screen stream
    _showPinLockScreen = _showLockScreenStream.stream.listen((bool show) async {
      if (mounted && show) {
        await _showLockScreenDialog();
      }
    });

    // Permissions are now requested in main.dart before database initialization
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    // Get the current top padding (notification bar area)
    final currentTopPadding = WidgetsBinding.instance.window.padding.top;

    // If top padding is increasing, the notification bar is being pulled down
    if (currentTopPadding > _previousTopPadding) {
      _isNotificationBarVisible = true;
      prints("Notification bar is being pulled down");
    }
    // If top padding is decreasing back to normal, the notification bar is being closed
    else if (currentTopPadding < _previousTopPadding) {
      _isNotificationBarVisible = false;
      prints("Notification bar is being closed");
    }

    _previousTopPadding = currentTopPadding;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _showPinLockScreen?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    final navigatorKey = ServiceLocator.get<MyNavigatorNotifier>();
    final secureStorageApi = ServiceLocator.get<SecureStorageApi>();
    final PosDeviceModel posDeviceModel = ServiceLocator.get<PosDeviceModel>();
    final userToken = await secureStorageApi.read(key: 'access_token');
    final staffToken = await secureStorageApi.read(key: 'staff_access_token');
    final token =
        staffToken.isNotEmpty
            ? staffToken
            : (userToken.isNotEmpty ? userToken : '');

    if (state == AppLifecycleState.paused) {
      // Check if the notification bar is being pulled down
      if (_isNotificationBarVisible) {
        // Notification bar is being pulled down, don't lock the screen
        prints("App paused due to notification bar - ignoring lock screen");
      } else {
        // This is a genuine app pause (home button or app switch), show lock screen
        if (token.isNotEmpty && posDeviceModel.id != null) {
          prints("App genuinely paused - showing lock screen");
          prints('LAST PAGE INDEX ${navigatorKey.pageIndex}');
          prints('LAST TAB INDEX ${navigatorKey.selectedTab}');

          if (navigatorKey.pageIndex != 2 &&
              navigatorKey.pageIndex != 3 &&
              navigatorKey.pageIndex != 4 &&
              navigatorKey.pageIndex != 5) {
            navigatorKey.setLastPageIndex(
              navigatorKey.pageIndex,
              navigatorKey.headerTitle,
            );
            navigatorKey.setLastSelectedTab(
              navigatorKey.selectedTab,
              navigatorKey.tabTitle,
            );
          }

          navigatorKey.setLastScreenIndex(navigatorKey.pageIndex);

          _isNotificationBarVisible = true;
          await Future.delayed(const Duration(milliseconds: 200));
          navigatorKey.setPageIndex(2, "pinLock".tr());
        }
      }
    } else if (state == AppLifecycleState.detached) {
      // App is detached (closed), no need to handle this case
      prints("App detached");
    } else if (state == AppLifecycleState.inactive) {
      // App is inactive but not fully paused (e.g., during app switching)
      // We don't need to handle this separately as paused will be called next
      prints("App inactive");
      prints("isNotificationBarVisible $_isNotificationBarVisible");
      // prints('LAST PAGE INDEX ${navigatorKey.pageIndex}');
      // prints('LAST TAB INDEX ${navigatorKey.selectedTab}');
      // navigatorKey.setLastPageIndex(
      //   navigatorKey.pageIndex,
      //   navigatorKey.headerTitle,
      // );
      // navigatorKey.setLastSelectedTab(
      //   navigatorKey.selectedTab,
      //   navigatorKey.tabTitle,
      // );
      if (_isNotificationBarVisible) {
        await Future.delayed(const Duration(milliseconds: 200));
        navigatorKey.setPageIndex(2, "pinLock".tr());
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_isAppJustStarted) {
        // App resumed from background, not a fresh start
        prints('App resumed from background');
      }
      // App is resumed from a paused state

      prints("isNotificationBarVisible $_isNotificationBarVisible");
      // If we've already shown the lock screen, navigate to the appropriate screen
      if (_isNotificationBarVisible) {
        if (navigatorKey.pageIndex == 2) {
          prints("SHOW LOCK SCREEN");
          _showLockScreenStream.add(true);
          _isNotificationBarVisible = false;
        } else {
          prints("NOT SHOWING LOCK SCREEN");
        }
      }

      prints("App resumed");
      prints(state.name);
    }
  }

  // USB Printer event handlers
  @override
  void onUsbPrinterConnected(PrinterModel printer) {
    super.onUsbPrinterConnected(printer);
    prints('🖨️ USB Printer Connected: ${printer.name} (${printer.address})');

    // You can add custom logic here, such as:
    // - Show a notification to the user
    // - Automatically set this printer as the default
    // - Update printer settings in the app
    // - Log the connection event

    // Example: Show a snackbar notification
    // if (mounted) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('USB Printer Connected: ${printer.name}'),
    //       backgroundColor: Colors.green,
    //       duration: const Duration(seconds: 3),
    //     ),
    //   );
    // }
  }

  @override
  void onUsbPrinterDisconnected(PrinterModel printer) {
    super.onUsbPrinterDisconnected(printer);
    prints(
      '🖨️ USB Printer Disconnected: ${printer.name} (${printer.address})',
    );

    // You can add custom logic here, such as:
    // - Show a notification to the user
    // - Switch to a backup printer if available
    // - Update printer settings in the app
    // - Log the disconnection event

    // Example: Show a snackbar notification
    // if (mounted) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('USB Printer Disconnected: ${printer.name}'),
    //       backgroundColor: Colors.orange,
    //       duration: const Duration(seconds: 3),
    //     ),
    //   );
    // }
  }

  @override
  void onUsbPrinterConnectionFailed(PrinterModel printer, String error) {
    super.onUsbPrinterConnectionFailed(printer, error);
    prints('🖨️ USB Printer Connection Failed: ${printer.name} - $error');

    // You can add custom logic here, such as:
    // - Show an error notification to the user
    // - Retry connection after a delay
    // - Log the error for debugging
    // - Switch to a backup printer

    // Example: Show an error snackbar
    // if (mounted) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('USB Printer Connection Failed: ${printer.name}\nError: $error'),
    //       backgroundColor: Colors.red,
    //       duration: const Duration(seconds: 5),
    //     ),
    //   );
    // }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Design size from the Figma - tablet size
      designSize: const Size(1194, 834),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: GlobalBarcodeListener(
            child: MaterialApp(
              scaffoldMessengerKey: scaffoldMessengerKey,
              navigatorKey: navigatorKey,
              title: 'Mysztech Pos',
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              // theme: AppTheme.getLightTheme(),
              theme: ThemeData(
                popupMenuTheme: const PopupMenuThemeData(color: white),
                scrollbarTheme: scrollbarTheme(),
                useMaterial3: false,
                primaryColor: kPrimaryColor,
                scaffoldBackgroundColor: scaffoldBackgroundColor,
                textTheme: const TextTheme(
                  headlineSmall: TextStyle(
                    color: Colors.white,
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              themeMode: widget.settingsController.themeMode,
              debugShowCheckedModeBanner: false,
              onGenerateRoute: (RouteSettings routeSettings) {
                return MaterialPageRoute<void>(
                  settings: routeSettings,
                  builder: (BuildContext context) {
                    switch (routeSettings.name) {
                      case AfterLoginScreen.routeName:
                        return const AfterLoginScreen();
                      case MainCustomerDisplay.routeName:
                        return const MainCustomerDisplay();

                      case CustomerShowReceipt.routeName:
                        return const CustomerShowReceipt();

                      case BarcodeTestScreen.routeName:
                        return const BarcodeTestScreen();

                      // case CustomerFeedback.routeName:
                      //   return const CustomerFeedback();
                      default:
                        return widget.initialRoute;
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  ScrollbarThemeData scrollbarTheme() {
    return ScrollbarThemeData(
      thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        // Use your primary color for all states
        return kPrimaryColor.withValues(alpha: 0.6);
      }),
    );
  }
}
