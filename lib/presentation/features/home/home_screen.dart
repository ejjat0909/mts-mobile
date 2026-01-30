import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/enum/db_response_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/page/page_model.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/data/models/side_bar/side_bar_model.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/data/models/temp/temp_model.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';
import 'package:mts/main.dart';
import 'package:mts/presentation/common/dialogs/loading_gif_dialogue.dart';
import 'package:mts/presentation/common/dialogs/theme_spinner.dart';
import 'package:mts/presentation/common/layouts/error_page.dart';
import 'package:mts/providers/app/app_providers.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/customer_display_preview/main_customer_display.dart';
import 'package:mts/presentation/features/home/components/custom_appbar.dart';
import 'package:mts/presentation/features/home/components/custom_appbar_receipt.dart';
import 'package:mts/presentation/features/home/components/custom_appbar_sales.dart';
import 'package:mts/presentation/features/home/components/drawer_header_content.dart';
import 'package:mts/presentation/features/home/components/drawer_item.dart';
import 'package:mts/presentation/features/home_receipt/home_receipt_screen.dart';
import 'package:mts/presentation/features/payment/components/payment_details.dart';
import 'package:mts/presentation/features/sales/sales_screen.dart';
import 'package:mts/presentation/features/settings/settings.dart';
import 'package:mts/presentation/features/sales/components/menu_item.dart';
import 'package:mts/presentation/features/shift_screen/shift_screen.dart';
import 'package:mts/providers/app/app_state.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/modifier_option/modifier_option_providers.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/page_item/page_item_providers.dart';
import 'package:mts/providers/payment_type/payment_type_providers.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/sale_item/sale_item_state.dart';
import 'package:mts/providers/shift/shift_providers.dart';
import 'package:mts/providers/page/page_providers.dart';
import 'package:mts/providers/slideshow/slideshow_providers.dart';
import 'package:sqlite_viewer2/sqlite_viewer.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  // Static methods to access cached data from other components
  static SlideshowModel? getCachedSlideshowModel() {
    return _HomeState.getCachedSlideshowModel();
  }

  static bool isSlideshowCacheInitialized() {
    return _HomeState.isSlideshowCacheInitialized();
  }

  static Future<void> ensureSlideshowCacheInitialized() async {
    return _HomeState.ensureSlideshowCacheInitialized();
  }

  static bool isSecondDisplayInitialized() {
    return _HomeState.isSecondDisplayInitialized();
  }

  static void resetSecondDisplayInitialization() {
    _HomeState.resetSecondDisplayInitialization();
  }

  static Future<void> initializeSlideshowCache() async {
    _HomeState.initializeSlideshowCache();
  }

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  int _selectedIndex = 0;

  // use for tap lock button to navigate back to last screen when unlock
  TempModel tempModel = TempModel(tempIndex: 0, tempTitle: '');
  bool isNestedSideBar = true;
  String nestedAppbarTitle = '';
  // SecondaryDisplayService replaced by secondDisplayProvider.notifier usage

  // Optimization: Add debouncing for drawer operations
  Timer? _drawerDebounceTimer;
  bool _isDrawerOperationInProgress = false;

  List<SideBarModel> sidebarItems = [];
  bool isShiftOpen = false;
  PageModel pageModel = PageModel();

  void _onItemTapped(int index) {
    _selectedIndex = index;

    setState(() {});
  }

  void getSelectedIndexSideBarItems(int pageIndex) {
    _selectedIndex = switch (pageIndex) {
      1000 => 0,
      2000 => 1,
      3000 => 2,
      4000 => 3,
      5000 => 4,
      _ => _selectedIndex,
    };
  }

  String getTitleAppbar(int selectedIndex) {
    // Check if selectedIndex is within the valid range
    //
    if (selectedIndex >= 0 && selectedIndex < sidebarItems.length) {
      String title = sidebarItems[selectedIndex].title;
      // Return the title as is
      return title;
    } else {
      // Return an error message for an invalid index
      return 'Invalid Index';
    }
  }

  /// Get appbar title from page index (using centralized state)
  String getTitleFromPageIndex(int pageIndex) {
    try {
      final item =
          sidebarItems.where((item) => item.index == pageIndex).firstOrNull;

      return item?.title ?? 'Invalid Index';
    } catch (e) {
      return 'Invalid Index';
    }
  }

  /// Optimized drawer opening with debouncing to prevent UI lag during sync
  void _openDrawerOptimized() {
    // Cancel any existing timer
    _drawerDebounceTimer?.cancel();

    // Prevent multiple rapid drawer operations
    if (_isDrawerOperationInProgress) {
      prints('OPENIGN DRAWER IN PROGRESS...');
      return;
    }
    prints('OPENING DRAWER...');

    _isDrawerOperationInProgress = true;

    // Use microtask to ensure smooth animation
    scheduleMicrotask(() {
      try {
        if (mounted && homeScaffoldKey.currentState != null) {
          homeScaffoldKey.currentState?.openDrawer();
        }
      } catch (e) {
        prints('Error opening drawer: $e');
      } finally {
        // Reset the flag after a short delay
        _drawerDebounceTimer = Timer(const Duration(milliseconds: 300), () {
          _isDrawerOperationInProgress = false;
        });
      }
    });
  }

  // Future<SlideshowModel> getData() async {
  //   Map<String, dynamic> response = await slideShowFacade.getLatestModel();

  //   if (response[DbResponseEnum.isSuccess]) {
  //     return response[DbResponseEnum.data];
  //   } else {
  //     return SlideshowModel();
  //   }
  // }

  // Cache for slideshow model to avoid repeated DB calls
  static SlideshowModel? _cachedSlideshowModel;
  static bool _slideshowCacheInitialized = false;
  static bool _isSecondDisplayInitialized = false;
  static ProviderContainer? _tryProviderContainer() {
    final context = navigatorKey.currentContext;
    if (context == null) return null;
    return ProviderScope.containerOf(context, listen: false);
  }

  bool dialogShown = false;
  late ValueNotifier<double> progressNotifier;
  late ValueNotifier<String> progressTextNotifier;
  late ValueNotifier<String> errorNotifier;
  BuildContext? _dialogContext;

  Future<void> showSecondDisplay() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Don't block UI initialization - run completely asynchronously
    unawaited(_showSecondDisplayOptimized());
  }

  /// Optimized second display initialization that doesn't block the main UI
  /// Uses caching approach similar to order_item.dart for consistency
  Future<void> _showSecondDisplayOptimized() async {
    // Use microtask to ensure this runs after the current frame
    scheduleMicrotask(() async {
      try {
        // Initialize slideshow cache if not already done
        await _initializeSlideshowCache();

        // Small delay to ensure UI is fully rendered
        // await Future.delayed(const Duration(milliseconds: 100));

        // // Prepare optimized data for second display
        // final Map<String, dynamic> dataWelcome = {
        //   DataEnum.slideshow: _cachedSlideshowModel?.toJson() ?? {},
        //   DataEnum.showThankYou: false,
        //   DataEnum.isCharged: false,
        // };

        // Update secondary display if widget is still mounted
        if (mounted) {
          ref.read(secondDisplayProvider.notifier).showMainCustomerDisplay();
          _isSecondDisplayInitialized = true;
          prints('✅ Second display initialized successfully with cached data');
        }
      } catch (error) {
        prints('❌ Error initializing second display: $error');

        // Fallback initialization
        if (mounted) {
          try {
            await ref
                .read(secondDisplayProvider.notifier)
                .navigateSecondScreen(
                  MainCustomerDisplay.routeName,
                  data: {DataEnum.slideshow: {}},
                );
            _isSecondDisplayInitialized = true;
          } catch (fallbackError) {
            prints(
              '❌ Error in fallback second display initialization: $fallbackError',
            );
          }
        }
      }
    });
  }

  /// Initialize slideshow cache early in initState to prevent lag in other screens
  void _initializeSlideshowCacheEarly() {
    // Use Future.microtask to avoid blocking initState but ensure it runs immediately after
    Future.microtask(() async {
      await _initializeSlideshowCache();
    });
  }

  /// Initialize MenuItem cache early in initState to prevent lag on first item tap
  void _initializeMenuItemCacheEarly() {
    // Use Future.microtask to avoid blocking initState but ensure it runs immediately after
    Future.microtask(() async {
      try {
        prints('🔄 Initializing MenuItem cache early to prevent first-tap lag');

        // Get the data from providers
        final listItemFromNotifier = ref.read(itemProvider).items;
        final listMoFromNotifier = ref.read(modifierOptionProvider).items;

        // Initialize MenuItem cache
        MenuItem.initializeCache(listItemFromNotifier, listMoFromNotifier);

        // Verify cache was initialized
        if (MenuItem.isCacheInitialized()) {
          prints(
            '✅ MenuItem cache initialized successfully - no more first-tap lag!',
          );
        } else {
          prints('⚠️ MenuItem cache initialization may have failed');
        }
      } catch (e) {
        prints('⚠️ Error initializing MenuItem cache: $e');
      }
    });
  }

  /// Initialize Payment cache early in initState to prevent lag when navigating to payment screen
  void _initializePaymentCacheEarly() {
    // Use Future.microtask to avoid blocking initState but ensure it runs immediately after
    Future.microtask(() async {
      try {
        prints(
          '🔄 Initializing Payment cache early to prevent payment screen lag',
        );

        // Get payment methods from provider
        final List<PaymentTypeModel> paymentMethods =
            ref.read(paymentTypeProvider).items;

        if (paymentMethods.isNotEmpty) {
          // Find default payment method (usually Cash)
          PaymentTypeModel? defaultPaymentMethod;
          try {
            defaultPaymentMethod = paymentMethods.firstWhere(
              (payment) => payment.name?.toLowerCase() == 'cash',
            );
          } catch (e) {
            // If no cash payment found, use first available
            defaultPaymentMethod =
                paymentMethods.isNotEmpty ? paymentMethods.first : null;
          }

          // Initialize PaymentDetails cache
          PaymentDetails.initializePaymentCache(
            paymentMethods,
            defaultPaymentMethod,
          );

          // Verify cache was initialized
          if (PaymentDetails.isCacheInitialized()) {
            prints(
              '✅ Payment cache initialized successfully with ${paymentMethods.length} methods - no more payment screen lag!',
            );
          } else {
            prints('⚠️ Payment cache initialization may have failed');
          }
        } else {
          prints('⚠️ Failed to fetch payment methods for cache initialization');
        }
      } catch (e) {
        prints('⚠️ Error initializing Payment cache: $e');
      }
    });
  }

  /// Initialize slideshow cache similar to order_item.dart approach
  Future<void> _initializeSlideshowCache() async {
    if (_slideshowCacheInitialized) return;

    try {
      final Map<String, dynamic> slideshowMap =
          await ref.read(slideshowProvider.notifier).getLatestModel();
      _cachedSlideshowModel = slideshowMap[DbResponseEnum.data];
      _slideshowCacheInitialized = true;
      prints('📱 Slideshow cache initialized successfully');
    } catch (e) {
      prints('⚠️ Error caching slideshow model: $e');
      _cachedSlideshowModel = SlideshowModel();
      _slideshowCacheInitialized = true;
    }
  }

  /// Get cached slideshow model for use by other components
  static SlideshowModel? getCachedSlideshowModel() {
    return _cachedSlideshowModel;
  }

  /// Check if slideshow cache is initialized
  static bool isSlideshowCacheInitialized() {
    return _slideshowCacheInitialized;
  }

  /// Public method to ensure slideshow cache is initialized
  /// This can be called from other screens to warm up the cache
  /// Uses the current ProviderScope container (via navigatorKey) to avoid facades
  static Future<void> ensureSlideshowCacheInitialized() async {
    if (_slideshowCacheInitialized) return;

    try {
      final container = _tryProviderContainer();
      if (container == null) {
        prints(
          '⚠️ No ProviderScope container available; skipping slideshow cache init',
        );
        return;
      }
      final Map<String, dynamic> slideshowMap =
          await container.read(slideshowProvider.notifier).getLatestModel();
      _cachedSlideshowModel = slideshowMap[DbResponseEnum.data];
      _slideshowCacheInitialized = true;
      prints('📱 Slideshow cache initialized from external call');
    } catch (e) {
      prints('⚠️ Error initializing slideshow cache from external call: $e');
      _cachedSlideshowModel = SlideshowModel();
      _slideshowCacheInitialized = true;
    }
  }

  /// Static method to initialize slideshow cache
  /// This is a direct static wrapper for the _initializeSlideshowCache method
  /// Can be called from other components like OpenShiftDialogue
  /// Uses the current ProviderScope container (via navigatorKey) to avoid facades
  static Future<void> initializeSlideshowCache() async {
    if (_cachedSlideshowModel?.id != null) return;

    try {
      final container = _tryProviderContainer();
      if (container == null) {
        prints(
          '⚠️ No ProviderScope container available; skipping slideshow cache init',
        );
        return;
      }
      final Map<String, dynamic> slideshowMap =
          await container.read(slideshowProvider.notifier).getLatestModel();
      _cachedSlideshowModel = slideshowMap[DbResponseEnum.data];
      _slideshowCacheInitialized = true;
      prints('📱 Slideshow cache initialized via static method');
    } catch (e) {
      prints('⚠️ Error caching slideshow model via static method: $e');
      _cachedSlideshowModel = SlideshowModel();
      _slideshowCacheInitialized = true;
    }
  }

  /// Check if second display has been initialized
  static bool isSecondDisplayInitialized() {
    return _isSecondDisplayInitialized;
  }

  /// Reset second display initialization flag to allow faster subsequent interactions
  /// This should be called when switching back to MainCustomerDisplay to treat
  /// the next item selection as a "first item" for immediate response
  static void resetSecondDisplayInitialization() {
    _isSecondDisplayInitialized = false;
    prints(
      '🔄 Second display initialization flag reset for faster interactions',
    );
  }

  @override
  void initState() {
    super.initState();
    // TimerService.startTimer();
    initData();

    prints('Home init');

    progressNotifier = ValueNotifier<double>(0.0);
    progressTextNotifier = ValueNotifier<String>('');
    errorNotifier = ValueNotifier<String>('');

    // Initialize all caches immediately to ensure they're available for all screens
    // This prevents lag when navigating to payment screen or interacting with menu items

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      isShiftOpen = ref.read(shiftProvider).isOpenShift;
      final dialogueNav = ref.read(myNavigatorProvider.notifier);

      Future.delayed(const Duration(milliseconds: 200), () async {
        if (dialogueNav.lastPageIndex != null &&
            dialogueNav.lastSelectedTab != null) {
          final lpi = dialogueNav.lastPageIndex!;

          getSelectedIndexSideBarItems(lpi);
          await dialogueNav.setUINavigatorAndIndex();
        } else {
          if (isShiftOpen) {
            if (pageModel.id != null) {
              // LogUtils.log("pageModel.toJson(): ${pageModel.toJson()}");

              ref
                  .read(pageItemProvider.notifier)
                  .setCurrentPageId(pageModel.id!);
              ref.read(pageItemProvider.notifier).setLastPageId(pageModel.id!);
              ref
                  .read(myNavigatorProvider.notifier)
                  .setPageIndex(1000, 'sales'.tr());
              //  Don’t sync everytime user key in pin
              //  await syncRealTime();
            }
          } else {
            ref
                .read(myNavigatorProvider.notifier)
                .setPageIndex(3000, 'shift'.tr());
            _selectedIndex = 2;
          }
        }
      });

      if (hasSecondaryDisplay) {
        _initializeMenuItemCacheEarly();
      }
      if (isShiftOpen && hasSecondaryDisplay) {
        _initializeSlideshowCacheEarly();
        await showSecondDisplay();
      }
      _initializePaymentCacheEarly();
    });
  }

  @override
  void dispose() {
    progressNotifier.dispose();
    progressTextNotifier.dispose();
    errorNotifier.dispose();

    if (dialogShown) {
      _closeLoadingDialog();
    }

    super.dispose();
  }

  void _showLoadingDialog() {
    final globalContext = navigatorKey.currentContext;
    if (globalContext != null && !dialogShown) {
      dialogShown = true;
      showDialog(
        context: globalContext,
        barrierDismissible: false,
        builder: (dialogContext) {
          _dialogContext = dialogContext;
          return LoadingGifDialogue(
            gifPath: 'assets/images/play-download.gif',
            loadingText: 'Syncing'.tr(),
            progressNotifier: progressNotifier,
            speedNotifier: progressTextNotifier,
            errorNotifier: errorNotifier,
          );
        },
      );
    }
  }

  void _closeLoadingDialog() {
    if (dialogShown) {
      dialogShown = false;

      if (_dialogContext != null) {
        try {
          if (Navigator.canPop(_dialogContext!)) {
            Navigator.of(_dialogContext!, rootNavigator: true).pop();
            prints('✅✅  Dialog closed using dialog context');
            setState(() {});
            _dialogContext = null;

            return;
          }
        } catch (e) {
          prints('⚠️ Failed to close dialog using dialog context: $e');
        }
      }

      final globalContext = navigatorKey.currentContext;
      if (globalContext != null) {
        try {
          if (Navigator.canPop(globalContext)) {
            Navigator.of(globalContext, rootNavigator: true).pop();
            prints('✅ Dialog closed using global context');
            setState(() {});
            _dialogContext = null;
            return;
          }
        } catch (e) {
          prints('⚠️ Failed to close dialog using global context: $e');
        }
      }

      _dialogContext = null;
      prints('⚠️ Dialog could not be closed, but state cleared');
    }
  }

  void _updateProgress(AppState appContextState) {
    if (appContextState.isSyncing) {
      prints(
        'Updating progress: ${appContextState.syncProgress}% - ${appContextState.syncProgressText}',
      );
      progressNotifier.value = appContextState.syncProgress;
      progressTextNotifier.value = appContextState.syncProgressText;

      if (appContextState.syncProgress >= 100.0 && dialogShown) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && dialogShown) {
            prints('⚠️ Auto-closing dialog after reaching 100% progress');
            _closeLoadingDialog();
          }
        });
      }
    }
  }

  Future<void> initData() async {
    getSidebarItems();
    pageModel = await ref.read(pageProvider.notifier).getFirstPage();

    setState(() {});
  }

  List<SideBarModel> getSidebarItems() {
    return sidebarItems = [
      SideBarModel(
        title: 'sales'.tr(),
        icon: Icons.attach_money_rounded,
        haveNestedSideBar: isNestedSideBar,
        index: 1000,
      ),
      SideBarModel(
        title: 'receipt'.tr(),
        icon: Icons.receipt_rounded,
        haveNestedSideBar: isNestedSideBar,
        index: 2000,
      ),
      SideBarModel(
        title: 'shift'.tr(),
        icon: Icons.swap_horiz_rounded,
        haveNestedSideBar: !isNestedSideBar,
        index: 3000,
      ),
      SideBarModel(
        title: 'settings'.tr(),
        icon: Icons.settings,
        haveNestedSideBar: isNestedSideBar,
        index: 4000,
      ),
      SideBarModel(
        title: 'backOffice'.tr(),
        icon: Icons.business_center_rounded,
        haveNestedSideBar: !isNestedSideBar,
        index: 5000,
      ),
    ];
  }

  // Future<void> _launchInBrowser(Uri url) async {
  //   if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
  //     throw Exception('Could not launch $url');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final dialoguNav = ref.watch(myNavigatorProvider.notifier);
    final saleItemsState = ref.watch(saleItemProvider);
    final saleItemsNotifier = ref.watch(saleItemProvider.notifier);
    bool isShiftOpenn = ref.watch(shiftProvider).isOpenShift;

    final appContextState = ref.watch(appProvider);
    bool isSyncing = appContextState.isSyncing;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isSyncing && !dialogShown) {
        _showLoadingDialog();
      } else if (!isSyncing && dialogShown) {
        _closeLoadingDialog();
      }
    });
    ref.listen<AppState>(appProvider, (previous, next) {
      _updateProgress(next);
    });

    _updateProgress(appContextState);

    return Scaffold(
      key: homeScaffoldKey,
      resizeToAvoidBottomInset: false,
      // make the widgets behind the keyboard
      appBar: getAppbar(
        isShiftOpenn,
        saleItemsState,
        saleItemsNotifier,
        dialoguNav,
      ),
      body: SafeArea(child: Center(child: getPages())),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              DrawerHeaderContent(tempModel: tempModel),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      ...(!isShiftOpenn
                              ? sidebarItems.where((model) {
                                // Return only items with index 2 and 3 when !isShiftOpen
                                return model.index == 3000 ||
                                    model.index == 4000;
                              }).toList()
                              : sidebarItems // Return all items when isShiftOpen is true
                              )
                          .map((model) {
                            // Use centralized pageIndex from MyNavigator for sidebar selection
                            final currentPageIndex =
                                ref.watch(myNavigatorProvider).pageIndex;
                            return DrawerItem(
                              title: model.title,
                              iconData: model.icon,
                              isSelected: currentPageIndex == model.index,
                              onTapped: () {
                                // Update the state of the app
                                //  prints('INDEX ${sidebarItems.indexOf(model)}');
                                //0
                                //1
                                _onItemTapped(sidebarItems.indexOf(model));

                                setState(() {
                                  tempModel.tempIndex = model.index;
                                  tempModel.tempTitle = model.title;
                                });

                                // Also store in MyNavigator for shift lock/unlock restoration
                                // context.read<MyNavigator>().setTempSidebarState(
                                //   model.index,
                                //   model.title,
                                // );

                                ref
                                    .read(myNavigatorProvider.notifier)
                                    .setPageIndex(model.index, model.title);

                                if (model.index == 4000 &&
                                    model.title == 'settings'.tr()) {
                                  prints('Settings Tapped');
                                  ref
                                      .read(myNavigatorProvider.notifier)
                                      .setSelectedTab(4100, 'receipt'.tr());
                                } else if (model.index == 3000 &&
                                    model.title == 'shift'.tr()) {
                                  isShiftOpen =
                                      ref.read(shiftProvider).isOpenShift;
                                  if (isShiftOpen) {
                                    ref
                                        .read(myNavigatorProvider.notifier)
                                        .setSelectedTab(
                                          3200,
                                          'shiftDetails'.tr(),
                                        );
                                  } else {
                                    ref
                                        .read(myNavigatorProvider.notifier)
                                        .setSelectedTab(3100, 'openShift'.tr());
                                  }
                                } else {
                                  prints("Selected tab 0, AKAN ERROR");
                                  ref
                                      .read(myNavigatorProvider.notifier)
                                      .setSelectedTab(0, '');
                                }
                                // prints("Selected tab 0, AKAN ERROR");
                                // context.read<MyNavigator>().setSelectedTab(
                                //   0,
                                //   '',
                                // );
                                // Set nested app title to empty string

                                // set selected receipt to -1
                                ref
                                    .read(receiptProvider.notifier)
                                    .setSelectedReceiptIndex(-1);

                                // Then close the drawer
                                // Future.delayed(
                                //   const Duration(milliseconds: 50),
                                //   () {
                                //
                                //   },
                                // );
                                NavigationUtils.pop(context);
                                // If the index is 5000 (back office)
                                if (!isStaging) {
                                  if (model.index == 5000) {
                                    Uri.parse(originUrl);
                                    setState(() {});
                                    return;
                                  }
                                }
                              },
                            );
                          }),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo_horizontal.png',
                    width: 150,
                    height: 50,
                  ),
                ],
              ),
              const Space(10),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget getAppbar(
    bool isShiftOpenn,
    SaleItemState saleItemsState,
    SaleItemNotifier saleItemsNotifier,
    MyNavigatorNotifier dialoguNav,
  ) {
    final categoryId = saleItemsState.categoryId;
    final currentPageIndex = ref.watch(myNavigatorProvider).pageIndex;

    // Find the current sidebar item based on centralized pageIndex
    final currentSidebarItem =
        sidebarItems
            .where((item) => item.index == currentPageIndex)
            .firstOrNull;

    if (currentSidebarItem?.haveNestedSideBar ?? false) {
      if (currentSidebarItem?.title == 'sales'.tr()) {
        if (currentPageIndex != 1000) {
          return AppBar(
            backgroundColor: canvasColor,
            elevation: 0,
            centerTitle: true,
            title: Text(
              getTitleFromPageIndex(currentPageIndex),
              style: const TextStyle(color: kWhiteColor),
            ),
            leading: ScaleTap(
              onPressed: _openDrawerOptimized,
              child: const Icon(FontAwesomeIcons.bars, color: kWhiteColor),
            ),
          );
        } else {
          return CustomAppBarSales(
            actionPress: () {
              if (categoryId != '') {
                saleItemsNotifier.setCategoryId('');
              } else {
                _openDrawerOptimized();
              }
            },
            action:
                categoryId != ''
                    ? FontAwesomeIcons.arrowLeft
                    : FontAwesomeIcons.bars,
            scaffoldKey: homeScaffoldKey,
            titleLeftSide: getTitleFromPageIndex(currentPageIndex),
            titleRightSide: 'order'.tr(),
            rightSideIcon: FontAwesomeIcons.ellipsisVertical,
          );
        }
      } else if (currentSidebarItem?.title == 'receipt'.tr()) {
        if (currentPageIndex != 2000) {
          return AppBar(
            backgroundColor: canvasColor,
            elevation: 0,
            centerTitle: true,
            title: Text(
              getTitleFromPageIndex(currentPageIndex),
              style: const TextStyle(color: kWhiteColor),
            ),
            leading: IconButton(
              icon: const Icon(FontAwesomeIcons.bars, color: kWhiteColor),
              onPressed: _openDrawerOptimized,
            ),
          );
        } else {
          return CustomAppBarReceipt(
            leftSidePress: _openDrawerOptimized,
            titleLeftSide: getTitleFromPageIndex(currentPageIndex),
            titleRightSide: ref.watch(myNavigatorProvider).tabTitle,
          );
        }
      } else {
        return CustomAppBar(
          leftSidePress: _openDrawerOptimized,
          leftSideIcon: FontAwesomeIcons.bars,
          scaffoldKey: homeScaffoldKey,
          leftSideTitle: getTitleFromPageIndex(currentPageIndex),
          rightSideTitle: ref.watch(myNavigatorProvider).tabTitle,
        );
      }
    } else {
      final isCloseShiftScreen = dialoguNav.getIsCloseShiftScreen;
      return AppBar(
        backgroundColor: canvasColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          getTitleAppbar(_selectedIndex),
          style: const TextStyle(color: kWhiteColor),
        ),
        leading:
            isCloseShiftScreen
                ? SizedBox.shrink()
                : Row(
                  children: [
                    SizedBox(width: 20.w),
                    Expanded(
                      child: IconButton(
                        onPressed: () {
                          homeScaffoldKey.currentState?.openDrawer();
                        },
                        icon: const Icon(
                          FontAwesomeIcons.bars,
                          color: kWhiteColor,
                        ),
                      ),
                    ),
                  ],
                ),
      );
    }
  }

  // Method to launch URL in external browser

  Widget getPages() {
    var pageIndex = ref.watch(myNavigatorProvider).pageIndex;

    prints('pageIndex $pageIndex');
    switch (pageIndex) {
      case 1000:
        return SalesScreen(homeContext: context);

      case 2000:
        return const HomeReceiptScreen();
      case 3000:
        return const ShiftScreen();
      case 4000:
        return const Settings();
      case 5000:
        if (isStaging) {
          return DatabaseList();
        } else {
          // Return a placeholder widget while launching
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ThemeSpinner.spinner(),
                const SizedBox(height: 20),
                Text(
                  'Launching Management Hub...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          );
        }

      default:
        return ErrorPage(index: pageIndex.toString());
    }
    // return _selectedIndex >= 0 && _selectedIndex < getWidgetOptions().length
    //     ? getWidgetOptions()[_selectedIndex]
    //     : const Text(
    //         "error",
    //         style: TextStyle(color: white),
    //       );
  }
}
