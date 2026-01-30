import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/app/app.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/config/settings_controller.dart';
import 'package:mts/core/config/settings_service.dart';
import 'package:mts/core/network/http_overrides.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/permission_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/data/datasources/remote/pusher_datasource.dart';
import 'package:mts/data/repositories/local/local_shift_repository_impl.dart';
import 'package:mts/domain/services/realtime/websocket_service.dart';
import 'package:mts/form_bloc/add_customer_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/plugins/presentation_displays/displaymanager.dart';
import 'package:mts/presentation/features/activate_license/activate_license_screen.dart';
import 'package:mts/presentation/features/after_login/after_login_screen.dart';
import 'package:mts/presentation/features/login/login_screen.dart';
import 'package:mts/presentation/features/secondary_display/second_screen.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';
import 'package:mts/providers/customer/customer_providers.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Global configuration
final GlobalKey<ScaffoldState> homeScaffoldKey = GlobalKey<ScaffoldState>();
final globalStopwatch = Stopwatch();
final globalStopwatch2 = Stopwatch();
final globalStopwatch3 = Stopwatch();

/// List of providers for state management
// We'll populate this list after ServiceLocator initialization
List<SingleChildWidget> providers = [];
final DisplayManager displayManager = DisplayManager();

/// Global secondary display configuration
bool hasSecondaryDisplay = false;
String? secondaryDisplayId;
bool isDisplayDetectionComplete = false;

/// Main entry point for the application
void main() async {
  // Initialize Flutter bindings
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  // Note: HiveInspector available for debugging (see lib/core/services/hive_inspector.dart)

  // Initialize Hive adapter registration (when @HiveType models are implemented)
  // await HiveAdapterRegistration.registerAllAdapters();
  // no need to register adapters because we can use json to put the model in the hive box

  // Initialize Hive boxes for caching
  await HiveBoxManager.initializeAllBoxes();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Configure HTTP overrides for SSL handling
  HttpOverrides.global = MyHttpOverrides();

  // Initialize localization
  await EasyLocalization.ensureInitialized();

  // Request necessary permissions before initializing the database
  try {
    await PermissionUtils.requestAllPermissions();
  } catch (e) {
    prints('Error requesting permissions: $e');
    // Continue app initialization even if permissions fail
  }

  // Initialize service locator for dependency injection
  ServiceLocator.init();
  final dbHelper = ServiceLocator.get<IDatabaseHelpers>();
  await dbHelper.initializeDatabaseWithMigrations();

  // Set orientation to landscape only
  // await SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.landscapeLeft,
  //   DeviceOrientation.landscapeRight,
  // ]);

  // initialize feature
  final container = riverpod.ProviderContainer();
  await container.read(featureCompanyProvider.notifier).initialize();

  // Initialize barcode scanner
  // ServiceLocator.get<BarcodeScannerNotifier>().initialize();

  // Clear any active focus
  FocusManager.instance.primaryFocus?.unfocus();

  // Initialize settings controller
  final settingsController = SettingsController(SettingsService());
  await settingsController.loadSettings();

  // Initialize models
  await _initializeModels();

  // Initialize WebSocket/Pusher connection
  final wsService = WebSocketService(
    pusherDatasource: ServiceLocator.get<PusherDatasource>(),
    shiftRepository: LocalShiftRepositoryImpl(
      dbHelper: ServiceLocator.get<IDatabaseHelpers>(),
    ),
  );
  await wsService.subscribeToLatestShift();

  // Detect and cache secondary display information
  await detectAndCacheSecondaryDisplay();

  // Determine initial route based on authentication status
  final initialRoute = await _determineInitialRoute();

  // Run the application
  runApp(
    riverpod.ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('ms', 'MY'), Locale('en', 'US')],
        path: 'assets/dictionary',
        fallbackLocale: const Locale('en', 'US'),
        startLocale: const Locale('en', 'US'),
        saveLocale: true,
        child: MultiProvider(
          providers: providers,
          child: riverpod.Consumer(
            builder: (context, ref, child) {
              final customerNotifier = ref.read(customerProvider.notifier);
              return MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create:
                        (context) =>
                            AddCustomerFormBloc(context, customerNotifier),
                  ),
                ],
                child: App(
                  settingsController: settingsController,
                  initialRoute: initialRoute,
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

/// Detect and cache secondary display information
/// Should be called once during app initialization
Future<void> detectAndCacheSecondaryDisplay() async {
  try {
    final displays = await displayManager.getDisplays();
    prints('DISPLAY DETECTION: ${displays.map((e) => e.a).toList()}');

    // Filter displays (exclude primary display with ID "0")
    final filteredDisplays =
        displays.where((display) => display.a != '0').toList();

    // Cache the results
    hasSecondaryDisplay = filteredDisplays.isNotEmpty;
    secondaryDisplayId = hasSecondaryDisplay ? filteredDisplays.first.a : null;
    isDisplayDetectionComplete = true;

    LogUtils.info(
      'Secondary display detection complete: '
      'hasDisplay=$hasSecondaryDisplay, displayId=$secondaryDisplayId',
    );
  } catch (e) {
    prints('Error during display detection: $e');
    LogUtils.error('Error during display detection: $e');

    // Set safe defaults
    hasSecondaryDisplay = false;
    secondaryDisplayId = null;
    isDisplayDetectionComplete = true;
  }
}

/// Initialize models from secure storage or create new ones
Future<void> _initializeModels() async {
  final secureStorageApi = ServiceLocator.get<SecureStorageApi>();

  // Register initial empty models
  ServiceLocator.registerSingleton<UserModel>(UserModel());
  ServiceLocator.registerSingleton<StaffModel>(StaffModel());
  ServiceLocator.registerSingleton<OutletModel>(OutletModel());
  ServiceLocator.registerSingleton<PosDeviceModel>(PosDeviceModel());

  // Load data from secure storage
  final userJson = await secureStorageApi.readObject('user');
  final outletJson = await secureStorageApi.readObject('outlet');
  final deviceJson = await secureStorageApi.readObject('device');

  // Create models from stored data if available
  UserModel user =
      userJson != null ? UserModel.fromJson(userJson) : UserModel();

  OutletModel outletModel =
      outletJson != null ? OutletModel.fromJson(outletJson) : OutletModel();

  // prints('${outletModel.toJson()}', name: 'OutletModel', level: 700);

  PosDeviceModel deviceModel =
      deviceJson != null
          ? PosDeviceModel.fromJson(deviceJson)
          : PosDeviceModel();

  // Register models with actual data
  // The ServiceLocator.registerSingleton method will unregister existing instances automatically
  ServiceLocator.registerSingleton<UserModel>(user);
  ServiceLocator.registerSingleton<OutletModel>(outletModel);
  ServiceLocator.registerSingleton<PosDeviceModel>(deviceModel);
}

/// Determine the initial route based on authentication status
Future<Widget> _determineInitialRoute() async {
  // check have user token  or not
  // if have user > dont have staff token

  // if have user token but no staff token, return after login {choose store}
  final secureStorageApi = ServiceLocator.get<SecureStorageApi>();
  // final deviceFacade = ServiceLocator.get<DeviceFacade>();
  final licenseKey = await secureStorageApi.read(key: 'license_key');
  final deviceToken = await secureStorageApi.read(key: 'device');
  final userToken = await secureStorageApi.read(key: 'access_token');
  final staffToken = await secureStorageApi.read(key: 'staff_access_token');

  if (userToken.isNotEmpty) {
    // belum login pin
    if (staffToken.isEmpty) {
      // belum pilih device
      if (deviceToken.isEmpty) {
        return AfterLoginScreen(token: userToken, initialIndex: 0);
      } else {
        // dah pilih device
        return AfterLoginScreen(token: userToken, initialIndex: 2); // pin
      }
    } else {
      // dah login pin
      return AfterLoginScreen(token: staffToken, initialIndex: 2); // pin
    }
  } else {
    if (licenseKey.isNotEmpty) {
      return LoginScreen();
    } else {
      return const LicenseScreen();
    }
  }
}

/// Entry point for secondary display
@pragma('vm:entry-point')
void secondaryDisplayMain() {
  runApp(
    riverpod.ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('ms', 'MY'), Locale('en', 'US')],
        path: 'assets/dictionary',
        fallbackLocale: const Locale('en', 'US'),
        startLocale: const Locale('en', 'US'),
        saveLocale: true,
        child: MultiProvider(providers: providers, child: const SecondScreen()),
      ),
    ),
  );
}
