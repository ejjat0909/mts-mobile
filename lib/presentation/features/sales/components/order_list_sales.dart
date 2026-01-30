import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/custom_variant_map_enum.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/enum/db_response_enum.dart';
import 'package:mts/core/enum/department_type_enum.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/core/enum/table_status_enum.dart';
import 'package:mts/core/enums/inventory_transaction_type_enum.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/core/utils/ui_utils.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/dialogs/loading_dialogue.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/button_bottom.dart';
import 'package:mts/presentation/common/widgets/button_primary.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/empty_dotted_container.dart';
import 'package:mts/presentation/common/widgets/rolling_text.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/home/home_screen.dart';
import 'package:mts/presentation/features/payment/payment_screen.dart';
import 'package:mts/presentation/features/payment/components/payment_details.dart';
import 'package:mts/presentation/features/sales/components/choose_order_option.dart';
import 'package:mts/presentation/features/sales/components/discount_sales_container.dart';
import 'package:mts/presentation/features/sales/components/order_item.dart';
import 'package:mts/presentation/features/sales/components/tax_dialogue.dart';
import 'package:mts/presentation/features/save_order/save_order_dialogue.dart';
import 'package:mts/presentation/features/variation_and_modifier/variation_and_modifier_dialogue.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';
import 'package:mts/providers/customer/customer_providers.dart';
import 'package:mts/providers/dialog_navigator/dialog_navigator_providers.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';
import 'package:mts/providers/modifier_option/modifier_option_providers.dart';
import 'package:mts/providers/payment/payment_providers.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/app/app_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/sale_item/sale_item_state.dart';
import 'package:mts/providers/sale/sale_providers.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/presentation/features/sales/components/menu_item.dart';
import 'package:mts/providers/slideshow/slideshow_providers.dart';
import 'package:mts/providers/user/user_providers.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';
import 'package:mts/providers/deleted_sale_item/deleted_sale_item_providers.dart';
import 'package:mts/providers/error_log/error_log_providers.dart';
import 'package:mts/providers/inventory/inventory_providers.dart';
import 'package:mts/providers/outlet/outlet_providers.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';
import 'package:mts/providers/print_receipt_cache/print_receipt_cache_providers.dart';
import 'package:mts/providers/sale_modifier/sale_modifier_providers.dart';
import 'package:mts/providers/sale_modifier_option/sale_modifier_option_providers.dart';
import 'package:mts/providers/table/table_providers.dart';
import 'package:mts/providers/modifier/modifier_providers.dart';
import 'package:mts/providers/staff/staff_providers.dart';

class OrderListSales extends ConsumerStatefulWidget {
  final BuildContext salesContext;
  // Static variable to track if an operation is in progress
  static bool _isProcessing = false;
  // Static timer for throttling
  static Timer? _throttleTimer;
  // Static timer for debouncing second display updates (50ms)
  static Timer? _secondDisplayDebounceTimer;
  // Queue for pending operations
  static final Queue<Function> _pendingOperations = Queue<Function>();
  // Flag to track if queue is being processed
  static bool _isProcessingQueue = false;
  // Cache for common data
  // Flag to track if cache has been initialized
  static bool _isCacheInitialized = false;
  // Map to accumulate pending quantity changes for each item
  static final Map<String, Map<String, dynamic>> _pendingSecondDisplayUpdates =
      {};
  // Flag to track if second display update is pending
  static bool _isSecondDisplayUpdatePending = false;
  // Last sent state to second display for comparison
  const OrderListSales({super.key, required this.salesContext});

  /// Add an operation to the queue and process it
  static void _addToQueue(Function operation) {
    _pendingOperations.add(operation);
    _processQueue();
  }

  /// Process queue items one at a time
  static Future<void> _processQueue() async {
    if (_isProcessingQueue || _pendingOperations.isEmpty) return;

    _isProcessingQueue = true;

    while (_pendingOperations.isNotEmpty) {
      final operation = _pendingOperations.removeFirst();
      await operation();
      // Small delay between operations to allow UI to update
      await Future.delayed(const Duration(milliseconds: 10));
    }

    _isProcessingQueue = false;
  }

  /// Initialize cache with common data
  static void initializeCache(
    List<ItemModel> items,
    List<ModifierOptionModel> modifierOptions,
  ) {
    if (_isCacheInitialized) return;

    _isCacheInitialized = true;
  }

  /// Update cache when data changes
  // static void updateCache(String key, dynamic value) {
  //   _cachedCommonData[key] = value;
  // }

  /// Schedule a debounced second display update
  /// This method accumulates changes and only sends to second display after 50ms of inactivity
  static void _scheduleSecondDisplayUpdate(
    String itemId,
    Map<String, dynamic> dataToTransfer,
    Function sendToSecondDisplay,
  ) {
    // Cancel existing debounce timer
    _secondDisplayDebounceTimer?.cancel();

    // Accumulate the pending update data
    _pendingSecondDisplayUpdates[itemId] = dataToTransfer;
    _isSecondDisplayUpdatePending = true;

    prints(
      '📱 Scheduling second display update for item: $itemId (50ms debounce)',
    );

    // Set new debounce timer for 50 milliseconds for faster response
    _secondDisplayDebounceTimer = Timer(
      const Duration(milliseconds: 50),
      () async {
        prints(
          '⏰ Debounce timer triggered - sending accumulated updates to second display',
        );
        await _sendAccumulatedUpdatesToSecondDisplay(sendToSecondDisplay);
      },
    );
  }

  /// Send all accumulated updates to second display
  static Future<void> _sendAccumulatedUpdatesToSecondDisplay(
    Function sendToSecondDisplay,
  ) async {
    if (!_isSecondDisplayUpdatePending ||
        _pendingSecondDisplayUpdates.isEmpty) {
      return;
    }

    try {
      prints(
        '🚀 Sending ${_pendingSecondDisplayUpdates.length} accumulated updates to second display',
      );

      // Get the most recent update data (last item that was tapped)
      final String lastItemId = _pendingSecondDisplayUpdates.keys.last;
      final Map<String, dynamic> finalData =
          _pendingSecondDisplayUpdates[lastItemId]!;

      // Send the final accumulated state to second display
      await sendToSecondDisplay(finalData);

      // Store the sent state for future comparison

      prints('✅ Successfully sent accumulated updates to second display');
    } catch (e) {
      prints('❌ Error sending accumulated updates to second display: $e');
    } finally {
      // Clear pending updates
      _pendingSecondDisplayUpdates.clear();
      _isSecondDisplayUpdatePending = false;
    }
  }

  /// Cancel any pending second display updates
  static void cancelPendingSecondDisplayUpdates() {
    _secondDisplayDebounceTimer?.cancel();
    _pendingSecondDisplayUpdates.clear();
    _isSecondDisplayUpdatePending = false;
    prints('🚫 Cancelled pending second display updates');
  }

  /// Check if there are pending second display updates
  static bool hasPendingSecondDisplayUpdates() {
    return _isSecondDisplayUpdatePending &&
        _pendingSecondDisplayUpdates.isNotEmpty;
  }

  @override
  ConsumerState<OrderListSales> createState() => _OrderListSalesState();
}

class _OrderListSalesState extends ConsumerState<OrderListSales> {
  bool hasItem = true;

  List<Map<String, dynamic>> dataSaleItem = [];
  // ScrollController for auto-scrolling to bottom
  final ScrollController _scrollController = ScrollController();

  // Track previous item count to detect when new items are added
  int _previousItemCount = 0;

  PredefinedOrderNotifier get _predefinedOrderNotifier =>
      ref.read(predefinedOrderProvider.notifier);
  PrinterSettingNotifier get _printerSettingNotifier =>
      ref.read(printerSettingProvider.notifier);
  SaleNotifier get _saleNotifier => ref.read(saleProvider.notifier);
  SaleItemNotifier get _saleItemNotifier => ref.read(saleItemProvider.notifier);
  SaleModifierNotifier get _saleModifierNotifier =>
      ref.read(saleModifierProvider.notifier);
  SaleModifierOptionNotifier get _saleModifierOptionNotifier =>
      ref.read(saleModifierOptionProvider.notifier);
  TableNotifier get _tableNotifier => ref.read(tableProvider.notifier);
  OutletNotifier get _outletNotifier => ref.read(outletProvider.notifier);
  InventoryNotifier get _inventoryNotifier =>
      ref.read(inventoryProvider.notifier);
  DeletedSaleItemNotifier get _deletedSaleItemNotifier =>
      ref.read(deletedSaleItemProvider.notifier);
  PrintReceiptCacheNotifier get _printReceiptCacheNotifier =>
      ref.read(printReceiptCacheProvider.notifier);
  ErrorLogNotifier get _errorLogNotifier => ref.read(errorLogProvider.notifier);
  ModifierNotifier get _modifierNotifier => ref.read(modifierProvider.notifier);
  StaffNotifier get _staffNotifier => ref.read(staffProvider.notifier);
  StaffModel get _staffModel => ServiceLocator.get<StaffModel>();
  OutletModel get _outletModel => ServiceLocator.get<OutletModel>();
  // for cache the slideshowmodel
  Map<String, dynamic> slideShowMap = {};
  SlideshowModel slideShowModel = SlideshowModel();

  Map<String, dynamic> getData(List<SaleItemModel> saleItemList) {
    if (saleItemList.isEmpty) {
      return {'saleModel': null};
    }

    final firstSaleId = saleItemList.first.saleId;
    if (firstSaleId == null) {
      return {'saleModel': null};
    }

    final modelSale = ref
        .read(saleProvider.notifier)
        .getSaleModelById(firstSaleId);
    return {'saleModel': modelSale};
  }

  // Cache for memoized futures to prevent unnecessary database calls
  // final Map<String, Map<String, dynamic>> _futureCache = {};

  // Helper method to memoize futures based on the sale item list
  // Map<String, dynamic> useMemoizedFuture(List<SaleItemModel> saleItemList) {
  //   // Create a cache key based on the list contents
  //   final cacheKey =
  //       saleItemList.isEmpty
  //           ? 'empty'
  //           : saleItemList
  //               .map(
  //                 (item) =>
  //                     '${item.id}-${item.updatedAt?.millisecondsSinceEpoch}',
  //               )
  //               .join('|');

  //   // Return cached future if it exists, otherwise create and cache a new one
  //   return _futureCache.putIfAbsent(cacheKey, () => getData(saleItemList));
  // }

  @override
  void initState() {
    super.initState();

    // Schedule a post-frame callback to ensure the widget is fully built before accessing the provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      slideShowMap =
          await ref.read(slideshowProvider.notifier).getLatestModel();
      slideShowModel = slideShowMap[DbResponseEnum.data] ?? SlideshowModel();
      if (mounted) {
        // Get data from Riverpod
        final saleItemsState = ref.read(saleItemProvider);

        setState(() {
          // This will trigger a rebuild with the state properly initialized
          hasItem = saleItemsState.saleItems.isNotEmpty;
          // Initialize dataSaleItem from Riverpod state
          dataSaleItem = saleItemsState.orderList;
        });

        // Scroll to bottom on initial load if there are items
        if (hasItem && _scrollController.hasClients) {
          _scrollToBottom();
        }

        // Listen for changes in the Riverpod state
        ref.listenManual(saleItemProvider, (previous, next) {
          // Clear the cache when the state changes
          // clearFutureCache();

          // Auto-scroll to bottom after the state is updated
          _scrollToBottom();
        });
      }
    });
  }

  // Helper method to scroll to the bottom of the list
  void _scrollToBottom() {
    // Use a post-frame callback to ensure the list has been built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && hasItem && _scrollController.hasClients) {
        try {
          // First try to jump near the end to avoid long scrolling animations
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent * 0.9,
          );

          // Then animate to the exact bottom for a smooth finish
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 50),
            curve: Curves.decelerate,
          );
        } catch (e) {
          // Handle any errors that might occur during scrolling
          prints('Error scrolling to bottom: $e');
        }
      }
    });
  }

  // Clear the future cache when data changes
  // void clearFutureCache() {
  //   _futureCache.clear();
  // }

  @override
  void dispose() {
    // Dispose of the scroll controller
    _scrollController.dispose();

    // Clear the cache when the widget is disposed to prevent memory leaks
    // _futureCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext parentContext) {
    // Use both Provider and Riverpod for compatibility during transition

    // Get data from Riverpod - this is the source of truth for our UI
    final saleItemsNotifier = ref.watch(saleItemProvider.notifier);
    final saleItemsState = ref.watch(saleItemProvider);
    final riverpodSaleItems = saleItemsState.saleItems;
    final riverpodOrderList = saleItemsState.orderList;
    final appContextState = ref.watch(appProvider);
    bool isSyncing = appContextState.isSyncing;

    // Update local state based on Riverpod state
    hasItem = riverpodSaleItems.isNotEmpty;
    dataSaleItem = riverpodOrderList;

    // Check if items have been added and trigger auto-scroll if needed
    if (riverpodSaleItems.length > _previousItemCount &&
        riverpodSaleItems.isNotEmpty) {
      // Only scroll when new items are added
      _scrollToBottom();
    }

    // Update the previous item count for the next build
    _previousItemCount = riverpodSaleItems.length;

    // Get edit mode from the notifier (will be moved to Riverpod state in future)
    final isEditMode = saleItemsState.isEditMode;

    // Use a more efficient conditional structure
    if (isEditMode) {
      return editModeBody(saleItemsNotifier);
    }

    return hasItem
        ? orderListBodyHaveItem(riverpodSaleItems, parentContext, isSyncing)
        : orderListBodyNoItem(riverpodSaleItems, parentContext, isSyncing);
  }

  Widget editModeBody(SaleItemNotifier saleItemsNotifier) {
    return Expanded(
      flex: 2,
      child: Container(
        color: white,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(child: SizedBox()),
                        Expanded(
                          flex: 2,
                          child: EmptyDottedContainer(
                            isEditMode: true,
                            isSquare: true,
                          ),
                        ),
                        Expanded(child: SizedBox()),
                      ],
                    ),

                    const Space(20),
                    Text('itemLayoutSetup'.tr(), style: AppTheme.h1TextStyle()),
                    const Space(20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'itemLayoutSetupDesc'.tr(),
                        style: AppTheme.mediumTextStyle(color: canvasColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: ButtonBottom(
                'done'.tr(),
                press: () {
                  saleItemsNotifier.setModeEdit(false);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget orderListBodyHaveItem(
    List<SaleItemModel> saleItemList,
    BuildContext parentContext,
    bool isSyncing,
  ) {
    // Use a memoized future to prevent unnecessary rebuilds
    // This ensures the future is only created once per unique saleItemList
    final saleItemsNotifier = ref.read(saleItemProvider.notifier);
    return Builder(
      builder: (context) {
        final Map<String, dynamic> dataFuture = getData(saleItemList);
        // Handle error state
        // if (dataFuture.isEmpty) {
        //   return Expanded(
        //     flex: 2,
        //     child: Container(
        //       decoration: BoxDecoration(
        //         color: white,
        //         boxShadow: UIUtils.itemShadows,
        //       ),
        //       child: Center(child: Text('errorLoadingData'.tr())),
        //     ),
        //   );
        // }

        // Handle loading or no data state
        if (dataFuture.isEmpty) {
          return orderListBodyNoItem(saleItemList, parentContext, isSyncing);
        }

        // Get the order data from Riverpod state for better performance and live updates

        final List<Map<String, dynamic>> orderDataList =
            saleItemsNotifier.getOrderList();

        return Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: white,
              boxShadow: UIUtils.itemShadows,
            ),
            child: Column(
              children: [
                //   if (isSyncing) syncIndicator(),
                // Top section - Category chooser (fixed)
                ChooseOrderOption(chooseCallback: () {}),

                // Middle section - Scrollable order items only
                Expanded(
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // The dynamic list - only order items are scrollable
                      SliverList(
                        delegate: SliverChildBuilderDelegate((
                          BuildContext context,
                          int index,
                        ) {
                          final Map<String, dynamic> orderData =
                              orderDataList[index];

                          return OrderItem(
                            orderData: orderData,
                            onDeletedSaleItemID: (idSaleItem) {
                              // plan nak buat kat dalam
                              // // Force refresh the Riverpod state after deletion
                              // // Recalculate totals to refresh the state
                              // final notifier = ref.read(
                              //   saleItemsProvider.notifier,
                              // );
                              // notifier.calcTotalDiscount();
                              // notifier.calcTaxAfterDiscount();
                              // notifier.calcTotalAfterDiscountAndTax();
                              // notifier.calcTotalWithAdjustedPrice();
                            },
                            press: () async {
                              final saleItem =
                                  orderData[DataEnum.saleItemModel]
                                      as SaleItemModel;
                              await onPress(saleItem, index, context);
                            },
                          );
                        }, childCount: orderDataList.length),
                      ),
                    ],
                  ),
                ),

                // Bottom section - Fixed at bottom (not part of scroll view)
                Container(
                  decoration: BoxDecoration(
                    color: white,
                    border: Border(
                      top: BorderSide(
                        color: kPrimaryColor.withValues(alpha: 0.1),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: Column(
                      children: [
                        const Space(5),
                        const DiscountSalesContainer(), // Now using Riverpod state
                        tax(), // Using Riverpod state internally
                        taxIncluded(),
                        const Space(5),
                        const Divider(thickness: 0.3),
                        total(), // Using Riverpod state internally
                        const Space(10),
                        saveOrderAndChargeButton(parentContext),
                        const Space(10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Container syncIndicator() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: kTextSuccess,
        borderRadius: BorderRadius.circular(0),
      ),
      child: Text('pleaseWait'.tr(), style: textStyleNormal(color: kBgSuccess)),
    );
  }

  Expanded orderListBodyNoItem(
    List<SaleItemModel> saleItemList,
    BuildContext parentContext,
    bool isSyncing,
  ) {
    // Use const for static widgets to improve performance
    const emptyStateIcon = Icon(
      FontAwesomeIcons.cashRegister,
      color: Color(
        0x80808080,
      ), // kTextGray.withValues(alpha: 0.5) as a constant
      size: 40,
    );

    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(color: white, boxShadow: UIUtils.itemShadows),
        child: Column(
          children: [
            //  if (isSyncing) syncIndicator(),
            // Top section - Category chooser (fixed)
            ChooseOrderOption(chooseCallback: () {}),

            // Middle section - Empty state with message (scrollable area)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    emptyStateIcon,
                    Space(20.h),
                    Text('noItem'.tr(), style: AppTheme.mediumTextStyle()),
                  ],
                ),
              ),
            ),

            // Bottom section - Fixed at bottom (not part of scroll view)
            Container(
              decoration: BoxDecoration(
                color: white,
                border: Border(
                  top: BorderSide(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 0),
                child: Column(
                  children: [
                    const Space(5),
                    const DiscountSalesContainer(), // Now using Riverpod state
                    tax(), // Using Riverpod state internally
                    const Space(5),
                    const Divider(thickness: 0.3),
                    total(), // Using Riverpod state internally
                    const Space(10),
                    saveOrderAndChargeButton(parentContext),
                    const Space(10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onPress(
    SaleItemModel saleItemModel,
    int index,
    BuildContext context, {
    bool updateSecondDisplayImmediately = true,
  }) async {
    // If an operation is in progress, add this operation to the queue instead of executing immediately
    if (OrderListSales._isProcessing) {
      prints('Adding onPress to queue - operation in progress');
      OrderListSales._addToQueue(
        () => _processOnPress(
          saleItemModel,
          index,
          context,
          updateSecondDisplayImmediately: updateSecondDisplayImmediately,
        ),
      );
      return;
    }

    // Cancel any existing throttle timer
    OrderListSales._throttleTimer?.cancel();

    // Set processing flag to prevent further immediate taps
    OrderListSales._isProcessing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialize cache if not already done
      if (!MenuItem.isCacheInitialized()) {
        prints(
          '⚠️ MenuItem cache not initialized, initializing now (this should not happen if home_screen initialized it)',
        );
        final listItemFromNotifier = ref.read(itemProvider).items;
        final listMoFromNotifier = ref.read(modifierOptionProvider).items;
        MenuItem.initializeCache(listItemFromNotifier, listMoFromNotifier);
      } else {
        prints(
          '✅ MenuItem cache already initialized - skipping redundant initialization',
        );
      }
      // Process the onPress after ensuring no conflicts
      await _processOnPress(
        saleItemModel,
        index,
        context,
        updateSecondDisplayImmediately: updateSecondDisplayImmediately,
      );
    });
  }

  /// Convenience method for order list interactions with debounced updates by default
  Future<void> onPressWithDebounce(
    SaleItemModel saleItemModel,
    int index,
    BuildContext context,
  ) async {
    return onPress(
      saleItemModel,
      index,
      context,
      updateSecondDisplayImmediately: false,
    );
  }

  Future<void> _processOnPress(
    SaleItemModel saleItemModel,
    int index,
    BuildContext context, {
    bool updateSecondDisplayImmediately = true,
  }) async {
    try {
      // Pre-check if we should continue processing
      if (!mounted) {
        OrderListSales._isProcessing = false;
        return;
      }

      // Process in a separate microtask to avoid blocking the UI thread
      await Future.microtask(() async {
        String itemId = saleItemModel.itemId ?? '-1';
        final itemNotifier = ref.read(itemProvider.notifier);
        ItemModel? itemModel = await itemNotifier.getItemModelById(itemId);

        if (itemModel == null) {
          OrderListSales._isProcessing = false;
          return;
        }

        String soldBy = itemModel.soldBy!;
        List<VariantOptionModel> listVariantOptions = [];
        final saleItemsRiverpod = ref.read(saleItemProvider.notifier);
        final saleItemsState = ref.read(saleItemProvider);

        switch (soldBy) {
          case ItemSoldByEnum.item || ItemSoldByEnum.measurement:
            // get list variant option from item model
            if (itemModel.variantOptionJson != null) {
              List<dynamic> listVOJson = jsonDecode(
                itemModel.variantOptionJson ?? '[]',
              );

              listVariantOptions =
                  listVOJson
                      .map((e) => VariantOptionModel.fromJson(e))
                      .toList();
            }

            // we have sale item model
            // get list sale modifier model
            List<SaleModifierModel> saleModifierModels =
                saleItemsState.saleModifiers;

            /// then get the [list  salemodifier.id] from sale modifier model where sale item id
            List<String> saleModifierIds =
                saleModifierModels
                    .where((element) {
                      return element.saleItemId == saleItemModel.id;
                    })
                    .toList()
                    .map((e) => e.id!)
                    .toList();

            ///  then use the list salemodifier.id to get the [list modifieroption.id] from saleModifierOptionModel
            List<SaleModifierOptionModel> saleModifierOptionModels =
                saleItemsState.saleModifierOptions;
            List<String> modifierOptionIds = [];

            saleModifierIds.asMap().forEach((index, saleModifierId) {
              List<String> matchingModifierOptionIds =
                  saleModifierOptionModels
                      .where(
                        (element) => element.saleModifierId == saleModifierId,
                      )
                      .map((element) => element.modifierOptionId!)
                      .toList();

              modifierOptionIds.addAll(matchingModifierOptionIds);
            });

            modifierOptionIds = modifierOptionIds.toSet().toList();

            ///  convert [modifierOptionIds]  to model to pass to [VariantAndModifierDialogue]
            List<ModifierOptionModel> selectedModifierOptionModelList = [];
            List<ModifierOptionModel> modifierOptionModelsFromNotifier =
                saleItemsState.listModifierOptionDB;

            modifierOptionIds.asMap().forEach((index, modifierOptionId) {
              List<ModifierOptionModel> matchingModifierOptionModels =
                  modifierOptionModelsFromNotifier
                      .where((element) => element.id == modifierOptionId)
                      .toList();
              selectedModifierOptionModelList.addAll(
                matchingModifierOptionModels,
              );
            });

            // Handle variant option processing (existing logic)
            if (saleItemModel.variantOptionId != null) {
              final variantOptionModel = itemNotifier.getVariantOptionModelById(
                saleItemModel.variantOptionId,
                saleItemModel.itemId,
              );
              if (variantOptionModel != null &&
                  variantOptionModel.price != null) {
                saleItemsRiverpod.setVariantOptionModel(variantOptionModel);
              } else if (variantOptionModel != null &&
                  variantOptionModel.price == null) {
                // Handle custom variant logic (existing code)
                List<Map<String, dynamic>> listCustomVariant =
                    saleItemsState.listCustomVariant;

                final customVariantMap = listCustomVariant.firstWhere(
                  (map) =>
                      map[CustomVariantMap.saleItemId] == saleItemModel.id &&
                      map[CustomVariantMap.variantOptionId] ==
                          saleItemModel.variantOptionId &&
                      map[CustomVariantMap.updatedAt] ==
                          saleItemModel.updatedAt!.toIso8601String(),
                  orElse: () => {},
                );

                bool isVariantCustom = false;
                if (customVariantMap.isNotEmpty) {
                  isVariantCustom =
                      customVariantMap[CustomVariantMap.isCustomVariant] ??
                      false;
                }

                if (isVariantCustom) {
                  List<dynamic> variantOptionJson = jsonDecode(
                    itemModel.variantOptionJson ?? '[]',
                  );
                  List<VariantOptionModel> listVOM = List.generate(
                    variantOptionJson.length,
                    (index) =>
                        VariantOptionModel.fromJson(variantOptionJson[index]),
                  );

                  VariantOptionModel findVOM = listVOM.firstWhere(
                    (vom) => vom.id == saleItemModel.variantOptionId,
                    orElse: () => VariantOptionModel(),
                  );

                  VariantOptionModel newVOM = VariantOptionModel();
                  if (findVOM.id != null) {
                    ref
                        .read(itemProvider.notifier)
                        .setTempVariantOptionModel(findVOM);

                    newVOM = findVOM.copyWith(
                      price:
                          customVariantMap[CustomVariantMap.variantOptionPrice]
                                  is double
                              ? customVariantMap[CustomVariantMap
                                  .variantOptionPrice]
                              : 0.00,
                    );
                    saleItemsRiverpod.setVariantOptionModel(newVOM);

                    int indexVOM = listVOM.indexWhere(
                      (vom) => vom.id == findVOM.id,
                    );
                    if (indexVOM != -1) {
                      listVOM[indexVOM] = newVOM;
                      listVariantOptions = listVOM;
                    }

                    String newVariantOptionJson = jsonEncode(listVOM);
                    itemModel = itemModel.copyWith(
                      variantOptionJson: newVariantOptionJson,
                    );
                  }
                }
              }
            }

            if (mounted) {
              if (kDebugMode) {
                prints('SET TEMP PRICE AND QTY TO 0');
              }
              ref.read(itemProvider.notifier).setTempPrice('0.00');
              ref.read(itemProvider.notifier).setTempQty('0.000');

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext contextDialogue) {
                  return VariantAndModifierDialogue(
                    saleItemModel: saleItemModel,
                    itemModel: itemModel ?? ItemModel(),
                    listVariantOptions: listVariantOptions,
                    isFromMenuList: false,
                    selectedModifierOptionIds: modifierOptionIds,
                    listSelectedModifierOption: selectedModifierOptionModelList,
                    onSave: (
                      modelItem,
                      varOptModel,
                      listModOpt,
                      qty,
                      existingSaleItem,
                      saleItemPrice,
                      comments,
                      listModifierOptionIds,
                      listModifierIds,
                      cost,
                    ) async {
                      VariantOptionModel? tempVOModel =
                          ref
                              .read(itemProvider.notifier)
                              .getTempVariantOptionModel;
                      bool isCustomVariant = tempVOModel?.price == null;
                      prints('SALE ITEM PRICE: $saleItemPrice');
                      Map<String, dynamic> dataToTransfer =
                          await saleItemsRiverpod.createAndUpdateSaleItems(
                            modelItem,
                            varOptModel: varOptModel,
                            listModOpt: listModOpt,
                            qty: qty,
                            existingSaleItem:
                                saleItemModel.id == modelItem.id ||
                                        saleItemModel.id ==
                                            IdUtils.generateHashId(
                                              saleItemModel.variantOptionId,
                                              modifierOptionIds,
                                              saleItemModel.comments!,
                                              modelItem.id!,
                                              cost: cost,
                                              variantPrice: varOptModel?.price,
                                            )
                                    ? existingSaleItem
                                    : saleItemModel,
                            newSaleItemUuid: null,
                            saleItemPrice: saleItemPrice,
                            comments: comments,
                            listModifierOptionIds: listModifierOptionIds,
                            pricePerItem: cost,
                            isCustomVariant: isCustomVariant,
                          );

                      // close dialogue variation and modifier first
                      // NavigationUtils.pop(context); // dah handle dekat onSave

                      await Future.delayed(const Duration(milliseconds: 100));
                      ref.read(itemProvider.notifier).setTempPrice('0.00');
                      ref.read(itemProvider.notifier).setTempQty('0.000');

                      // Handle second display update in a microtask to prevent blocking UI
                      Future.microtask(() async {
                        /// [OPTIMIZED SHOW SECOND DISPLAY] - Conditional based on parameter
                        if (updateSecondDisplayImmediately) {
                          await showOptimizedSecondDisplay(dataToTransfer);
                        } else {
                          // For debounced updates, use the scheduling mechanism
                          final String itemId =
                              saleItemModel.itemId ?? 'unknown';
                          OrderListSales._scheduleSecondDisplayUpdate(
                            itemId,
                            dataToTransfer,
                            (Map<String, dynamic> data) =>
                                showOptimizedSecondDisplay(data),
                          );
                          prints(
                            '📅 Scheduled debounced second display update for item: $itemId',
                          );
                        }
                      });
                    },
                    onDelete: (data) async {
                      await onDeleteFromVariationAndModifierDialogue(data);
                    },
                  );
                },
              );
            }

          default:
            ThemeSnackBar.showSnackBar(context, 'No Sold BY');
        }
      }); // Close the Future.microtask
    } finally {
      // Reset the processing flag after a short delay to allow operations to complete
      OrderListSales._throttleTimer = Timer(
        const Duration(milliseconds: 50),
        () {
          OrderListSales._isProcessing = false;

          // Process the next item in the queue if there is one
          if (OrderListSales._pendingOperations.isNotEmpty) {
            OrderListSales._processQueue();
          }
        },
      );
    }
  }

  Future<void> onDeleteFromVariationAndModifierDialogue(
    Map<String, dynamic> data,
  ) async {
    final saleItemsState = ref.read(saleItemProvider);
    final listSaleItems = saleItemsState.saleItems;

    /// [SHOW SECOND DISPLAY]
    prints("LIST SALE ITEMS ${listSaleItems.length}");
    if (listSaleItems.isNotEmpty) {
      final currentUser =
          ref.read(userProvider.notifier).currentUser ?? UserModel();
      SlideshowModel? currSdModel = Home.getCachedSlideshowModel();

      data.addEntries([
        MapEntry(DataEnum.userModel, currentUser.toJson()),
        MapEntry(DataEnum.slideshow, currSdModel?.toJson() ?? {}),
        const MapEntry(DataEnum.showThankYou, false),
        const MapEntry(DataEnum.isCharged, false),
      ]);

      // context = null because the dialogue already closed
      await ref.read(slideshowProvider.notifier).updateSecondaryDisplay(data);
    } else {
      // Don't await this call to prevent blocking the UI thread
      ref.read(secondDisplayProvider.notifier).showMainCustomerDisplay();
    }
  }

  Widget saveOrderAndChargeButton(BuildContext parentContext) {
    final permissionNotifier = ref.watch(permissionProvider.notifier);
    final featureCompNotifier = ref.watch(featureCompanyProvider.notifier);
    final isFeatureActive = featureCompNotifier.isOpenOrdersActive();
    final isFeatureOrderOptionActive =
        featureCompNotifier.isOrderOptionActive();
    final hasPermission = permissionNotifier.hasAcceptPaymentPermission();
    final saleItemsState = ref.watch(saleItemProvider);
    final saleItemNotifier = ref.read(saleItemProvider.notifier);
    final saleItemModels = saleItemsState.saleItems;
    final currSaleModel = saleItemsState.currSaleModel;
    String? predefinedOrderId = saleItemsState.pom?.id;
    TableModel? tableModel = saleItemsState.selectedTable;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          isFeatureActive
              ? Expanded(
                child: ButtonTertiary(
                  text: getButtonText(saleItemModels, predefinedOrderId),
                  onPressed: () async {
                    // Prevent double taps only if saleItems is not empty
                    if (saleItemsState.saleItems.isNotEmpty &&
                        OrderListSales._isProcessing) {
                      prints(
                        'Save order button tap ignored - operation in progress',
                      );
                      return;
                    }

                    // Set processing flag to prevent further taps
                    OrderListSales._isProcessing = true;

                    if (!isFeatureOrderOptionActive) {
                      if (currSaleModel?.orderOptionId == null) {
                        saleItemNotifier.setOrderOptionModel(
                          OrderOptionModel(),
                        );
                      } else {
                        // if not null, do nothing
                      }
                    }

                    // get the sale items that doesnt have sale id, because
                    // when does not have sale id, it means it is a new sale and didnt update for inventory
                    List<SaleItemModel> newListSaleItemsWithoutSaleId =
                        List<SaleItemModel>.from(
                          saleItemModels
                              .where((element) => element.saleId == null)
                              .toList(),
                        );
                    bool wantToProceed = await _inventoryNotifier
                        .checkInventoryStock(
                          context,
                          newListSaleItemsWithoutSaleId,
                        );

                    try {
                      if (wantToProceed) {
                        await Future.delayed(const Duration(milliseconds: 300));
                        // if table doesnt have predefined order id

                        if (tableModel?.id != null) {
                          prints('TABLE : ${tableModel?.name}');
                          if (tableModel?.predefinedOrderId == null) {
                            prints('CASE 11');
                            if (saleItemModels.isEmpty) {
                              await _saleNotifier.handleOpenOrder(context);
                            } else {
                              // rare case
                              // go custom order
                              prints('CASE 22');
                              if (isStaging) {
                                ThemeSnackBar.showSnackBar(
                                  context,
                                  "RARE CASE: CASE 22",
                                );
                              }

                              await handleSaveOrder();
                            }

                            /// [SHOW SECOND DISPLAY]
                            await ref
                                .read(secondDisplayProvider.notifier)
                                .showMainCustomerDisplay();

                            return;
                          }
                          prints('Saving with Table');
                          //handle saving with table
                          predefinedOrderId = tableModel?.predefinedOrderId;

                          if (predefinedOrderId != null &&
                              currSaleModel?.id != null) {
                            // handle save to same predefined order
                            currSaleModel?.tableId = tableModel?.id;
                            currSaleModel?.tableName = tableModel?.name;
                            prints('CASE 33');
                            await handleSaveToSamePredefinedOrder(
                              predefinedOrderId!,
                              currSaleModel!,
                              saleItemModels,
                            );
                          } else {
                            // kalau pilih meja, then terus save
                            prints('CASE 55');
                            await onCase55(predefinedOrderId, tableModel!);
                          }

                          /// [SHOW SECOND DISPLAY]
                          await ref
                              .read(secondDisplayProvider.notifier)
                              .showMainCustomerDisplay();
                          return;
                        }

                        prints('predefinedOrderId $predefinedOrderId');
                        prints('saleModel.id ${currSaleModel?.id}');

                        if (predefinedOrderId != null) {
                          // prints(
                          //   'handle save to same predefined order because still have predefined order id',
                          // );
                          if (currSaleModel?.id != null) {
                            prints('CASE 44');
                            await handleSaveToSamePredefinedOrder(
                              predefinedOrderId!,
                              currSaleModel!,
                              saleItemModels,
                            );
                          } else {
                            prints('CASE 66');
                            // if press from table and unlink table
                            final saleItemNotifier = ref.read(
                              saleItemProvider.notifier,
                            );
                            await handleSaveToSamePoAfterUnlinkTable(
                              saleItemNotifier,
                              saleItemsState,
                            );
                          }

                          return;
                        }
                        // ade bug bila dah save order kosong, still keluar open order

                        if (saleItemModels.isEmpty) {
                          // handle open order
                          await _saleNotifier.handleOpenOrder(context);
                        } else {
                          // handle save
                          if (predefinedOrderId != null &&
                              currSaleModel?.id != null) {
                            // handle save to same predefined order
                            prints('handle save to same predefined order');
                            await handleSaveToSamePredefinedOrder(
                              predefinedOrderId!,
                              currSaleModel!,
                              saleItemModels,
                            );

                            /// [SHOW SECOND DISPLAY]
                            await ref
                                .read(secondDisplayProvider.notifier)
                                .showMainCustomerDisplay();
                          } else {
                            prints('handle save order');
                            await handleSaveOrder();
                          }
                        }
                      } else {
                        ThemeSnackBar.showSnackBar(
                          context,
                          'notProceedForSale'.tr(),
                        );
                        return;
                      }
                    } finally {
                      // Reset processing flag after a delay to prevent rapid successive taps
                      Timer(const Duration(milliseconds: 500), () {
                        OrderListSales._isProcessing = false;
                      });
                    }
                  },
                  icon: FontAwesomeIcons.download,
                ),
              )
              : SizedBox.shrink(),
          (hasPermission && isFeatureActive) ? 10.widthBox : 0.widthBox,
          hasPermission
              ? Expanded(
                child: ButtonPrimary(
                  text: 'charge'.tr(),
                  icon: FontAwesomeIcons.moneyBill,
                  onPressed: () async {
                    // Prevent double taps
                    if (OrderListSales._isProcessing) {
                      prints(
                        'Charge button tap ignored - operation in progress',
                      );
                      return;
                    }

                    // Set processing flag to prevent further taps
                    OrderListSales._isProcessing = true;

                    try {
                      await onPressCharged(
                        currSaleModel?.id != null ? currSaleModel : null,
                      );
                    } finally {
                      // Reset processing flag after a delay to prevent rapid successive taps
                      Timer(const Duration(milliseconds: 500), () {
                        OrderListSales._isProcessing = false;
                      });
                    }
                  },
                ),
              )
              : SizedBox.shrink(),
        ],
      ),
    );
  }

  Future<void> onCase55(
    String? predefinedOrderId,
    TableModel tableModel,
  ) async {
    _saleNotifier.saveOrderIntoPredefinedOrder(
      context,
      predefinedOrderId,
      tableModel: tableModel,
      beforeSave: (saleModel) {},
      onSuccess: (saleModel) async {
        // // update table to database
        // await _tableFacade.update(updated);

        //  final currentState = ref.read(saleItemsProvider);

        // prints('Table PO Id ${tableModel.predefinedOrderId}');
      },
    );
  }

  String getButtonText(
    List<SaleItemModel> saleItemModels,
    String? predefinedOrderId,
  ) {
    if (predefinedOrderId != null) {
      return 'save'.tr();
    }
    if (saleItemModels.isEmpty) {
      return 'openOrder'.tr();
    } else {
      return 'save'.tr();
    }
  }

  Future<void> onPressCharged(SaleModel? saleModel) async {
    final permissionNotifier = ref.read(permissionProvider.notifier);
    final saleItemsNotifier = ref.read(saleItemProvider.notifier);
    final saleItemsState = ref.read(saleItemProvider);
    final List<SaleItemModel> saleItemModels = saleItemsState.saleItems;
    final paymentNotifier = ref.read(paymentProvider.notifier);

    if (!permissionNotifier.hasAcceptPaymentPermission()) {
      ThemeSnackBar.showSnackBar(
        context,
        'youDontHavePermissionForThisAction'.tr(),
      );
      return;
    }

    // get the sale items that doesnt have sale id, because
    // when does not have sale id, it means it is a new sale and didnt update for inventory
    List<SaleItemModel> newListSaleItemsWithoutSaleId =
        List<SaleItemModel>.from(
          saleItemModels.where((element) => element.saleId == null).toList(),
        );
    bool wantToProceed = await _inventoryNotifier.checkInventoryStock(
      context,
      newListSaleItemsWithoutSaleId,
    );

    if (wantToProceed) {
      if (saleItemsNotifier.hasSaleItems) {
        // Pre-initialize payment data BEFORE navigation for smooth transition
        await _preInitializePaymentData(
          saleModel,
          saleItemsNotifier,
          saleItemsState,
          paymentNotifier,
        );

        // Use optimized navigation with pre-initialization callbacks
        Navigator.push(
          context,
          NavigationUtils.createNonBlockingRoute(
            newScreen: PaymentScreen(orderListContext: context),
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
      } else {
        ThemeSnackBar.showSnackBar(context, 'noItem'.tr());
      }
    } else {
      ThemeSnackBar.showSnackBar(context, 'notProceedForSale'.tr());
      return;
    }
  }

  /// Pre-initialize payment data to ensure smooth navigation
  Future<void> _preInitializePaymentData(
    SaleModel? saleModel,
    SaleItemNotifier saleItemsNotifier,
    SaleItemState saleItemsState,
    PaymentNotifier paymentNotifier,
  ) async {
    // Use Future.microtask to avoid blocking the UI thread
    await Future.microtask(() async {
      try {
        // Set navigation flags first
        saleItemsNotifier.setCanBackToSalesPage(true);
        saleItemsNotifier.setIsSplitPayment(false);

        // Prepare sale model
        SaleModel updatedSaleModel = SaleModel();
        if (saleModel != null) {
          updatedSaleModel = saleModel.copyWith(
            totalPrice: saleItemsState.totalAfterDiscountAndTax,
          );
        }
        saleItemsNotifier.setCurrSaleModel(updatedSaleModel);

        // Set payment screen flag
        paymentNotifier.setChangeToPaymentScreen(true);

        // Calculate totals
        saleItemsNotifier.calcTotalWithAdjustedPrice();

        // Pre-initialize payment cache to reduce load time
        await _preInitializePaymentCache();

        prints('✅ Payment data pre-initialized for smooth navigation');
      } catch (e) {
        prints('❌ Error pre-initializing payment data: $e');
        // Continue with navigation even if pre-initialization fails
      }
    });
  }

  /// Pre-initialize payment cache for faster loading
  Future<void> _preInitializePaymentCache() async {
    try {
      // Pre-warm payment cache to reduce load time in payment screen
      await PaymentDetails.preWarmCache();

      prints('💾 Payment cache pre-initialized successfully');
    } catch (e) {
      prints('❌ Error pre-initializing payment cache: $e');
      // Continue even if cache initialization fails
    }
  }

  Future<void> handleSaveToSamePredefinedOrder(
    String predefinedOrderId,
    SaleModel saleModel,
    List<SaleItemModel> showedListSaleItems,
  ) async {
    final saleItemsState = ref.read(saleItemProvider);
    final saleItemsNotifier = ref.read(saleItemProvider.notifier);
    final currSelectedTable = saleItemsState.selectedTable;
    final customerNotifier = ref.read(customerProvider.notifier);

    String saleId = saleModel.id ?? '';
    if (currSelectedTable?.id != null && currSelectedTable?.saleId != null) {
      saleId = currSelectedTable!.saleId!;
    }

    if (saleId.isEmpty) {
      ThemeSnackBar.showSnackBar(context, "Sale id not found");
      return;
    }

    LoadingDialog.show(context);
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // get the cleared sale items from the notifier
      List<SaleItemModel> clearedItems = List<SaleItemModel>.from(
        saleItemsNotifier.getListSaleItemsCleared,
      );
      await Future.wait(
        clearedItems.map((si) async {
          await _saleItemNotifier.update(si);
        }),
      );

      // delete cleared items from notifier
      saleItemsNotifier.deleteAllSaleItemsCleared();

      // 🔍 STEP 1: Get existing items in database for this sale (including voided ones)
      List<SaleItemModel> existingItemsInDB = await _saleItemNotifier
          .getListSaleItemBySaleId([saleId]);
      List<SaleModifierModel> existingSaleModifiers =
          await _saleModifierNotifier.getListSaleModifierModelBySaleId(saleId);
      List<SaleModifierOptionModel> existingSaleModifierOptions =
          await _saleModifierOptionNotifier.getSaleModifierOptionModelsByIdSale(
            saleId,
          );

      /// showed items
      List<SaleModifierModel> showedSaleModifiers =
          saleItemsState.saleModifiers;
      List<SaleModifierOptionModel> showedSaleModifierOptions =
          saleItemsState.saleModifierOptions;

      prints('📊 Existing items in database: ${existingItemsInDB.length}');

      /// [get cleared sale modifiers]
      List<SaleModifierModel> clearedListSaleModifiers =
          existingSaleModifiers
              .where((item) => !showedSaleModifiers.contains(item))
              .toList();

      /// [get cleared sale modifier options]
      List<SaleModifierOptionModel> clearedListSaleModifierOptions =
          existingSaleModifierOptions
              .where((item) => !showedSaleModifierOptions.contains(item))
              .toList();

      List<SaleItemModel> newListSaleItems = [];
      List<SaleModifierModel> newListSM = [];
      List<SaleModifierOptionModel> newListSMO = [];

      /// [get new sale items]
      final List<SaleItemModel> listSaleItems = List<SaleItemModel>.from(
        showedListSaleItems
            .where(
              (item) =>
                  !existingItemsInDB.any((existing) => existing.id == item.id),
            )
            .toList(),
      );

      /// [get new sale modifiers]
      final List<SaleModifierModel> newListSaleModifiers =
          List<SaleModifierModel>.from(
            showedSaleModifiers
                .where(
                  (sm) =>
                      !existingSaleModifiers.any(
                        (existing) => existing.id == sm.id,
                      ),
                )
                .toList(),
          );

      /// [get new sale modifier options]
      List<SaleModifierOptionModel> newListSaleModifierOptions =
          showedSaleModifierOptions
              .where(
                (smo) =>
                    !existingSaleModifierOptions.any(
                      (existing) => existing.id == smo.id,
                    ),
              )
              .toList();

      // do looping
      // assign the foreign key
      for (SaleItemModel si in listSaleItems) {
        String newSaleItemId = IdUtils.generateUUID();
        // get the sale modifier list by sale item id to get the id
        List<SaleModifierModel> listSM =
            newListSaleModifiers
                .where((element) => element.saleItemId == si.id)
                .toList();

        if (listSM.isNotEmpty) {
          for (SaleModifierModel sm in listSM) {
            List<SaleModifierOptionModel> listSMO =
                newListSaleModifierOptions
                    .where((element) => element.saleModifierId == sm.id)
                    .toList();
            SaleModifierModel newSM = sm.copyWith(
              saleItemId: newSaleItemId,
              saleModifierOptionCount: listSMO.length,
            );
            newListSM.add(newSM);

            if (listSMO.isNotEmpty) {
              for (SaleModifierOptionModel smo in listSMO) {
                SaleModifierOptionModel newSMO = smo.copyWith(
                  saleModifierId: sm.id,
                );
                newListSMO.add(newSMO);
              }
            }
          }
        }

        SaleItemModel newSaleItem = si.copyWith(
          id: newSaleItemId,
          saleId: saleId,
          isVoided: false,
          saleModifierCount: listSM.length,
        );

        // yg baru ditambah, belum ada dalam DB
        newListSaleItems.add(newSaleItem);
      }

      saleItemsNotifier.setCurrSaleModel(saleModel);
      final saleItemState1 = ref.read(saleItemProvider);
      final PredefinedOrderModel pom = saleItemState1.pom!;

      if (pom.id == null) {
        // tak boleh return sebab atas dah tengah buat action
        // masukkan dalam error log je
        // rare case
        String message =
            "Predefined order id is null - ORDER LIST SALES - handelSaveToSamePredefinedOrder";
        await _errorLogNotifier.createAndInsertErrorLog(message);
      }
      List<SaleItemModel> listSI = saleItemState1.saleItems;

      if (listSI.isEmpty && pom.id == null) {
        if (kDebugMode) {
          prints('UNOCCUPIED PREDEFINED ORDER');
        }
        await _predefinedOrderNotifier.unOccupied(predefinedOrderId);
        await _saleNotifier.delete(saleModel.id!);
        LoadingDialog.hide(context);
        return;
      }
      List<SaleItemModel> mergedSaleItems = SaleItemModel.mergeWithUniqueIds(
        newListSaleItems,
        existingItemsInDB,
      );
      double totalPrice = saleItemState1.totalAfterDiscountAndTax;
      int newSaleItemCount = mergedSaleItems.length;

      /// merge [voided] itemids
      // filter to get isVoid = true, isPrintVoided = false

      // get the current [saleItemIdsToPrintVoid] from sale model

      SaleModel updatedSaleModel = saleModel.copyWith(
        id: saleId,
        predefinedOrderId: pom.id,
        totalPrice: totalPrice,
        name: pom.name,
        staffId: _staffModel.id,

        orderOptionId: saleItemState1.orderOptionModel?.id,
        outletId: _outletModel.id,
        saleItemCount: newSaleItemCount, // 🔧 FIXED!
      );

      // Reset all state
      saleItemsNotifier.setSelectedTable(TableModel());
      saleItemsNotifier.setPredefinedOrderModel(PredefinedOrderModel());
      saleItemsNotifier.setCurrSaleModel(SaleModel());
      customerNotifier.setOrderCustomerModel(null);
      saleItemsNotifier.clearOrderItems();
      saleItemsNotifier.calcTotalAfterDiscountAndTax();
      saleItemsNotifier.calcTaxAfterDiscount();
      saleItemsNotifier.calcTaxIncludedAfterDiscount();
      saleItemsNotifier.calcTotalDiscount();

      // print cache to print kitchen
      if (newListSaleItems.isNotEmpty) {
        await _printReceiptCacheNotifier.insertDetailsPrintCache(
          saleModel: updatedSaleModel,
          listSaleItemModel: newListSaleItems,
          listSM: newListSM,
          listSMO: newListSMO,
          orderOptionModel: saleItemState1.orderOptionModel!,
          pom: pom,
          printType: DepartmentTypeEnum.printKitchen,
          isForThisDevice: true,
        );
      }

      // print cache to print void
      if (clearedItems.isNotEmpty) {
        await _printReceiptCacheNotifier.insertDetailsPrintCache(
          saleModel: updatedSaleModel,
          listSaleItemModel: clearedItems,
          listSM: clearedListSaleModifiers,
          listSMO: clearedListSaleModifierOptions,
          orderOptionModel: saleItemState1.orderOptionModel!,
          pom: pom,
          printType: DepartmentTypeEnum.printVoid,
          isForThisDevice: true,
        );
      }

      LoadingDialog.hide(context);
      await attemptPrintVoidAndKitchen(
        updatedSaleModel,
        isPrintAgain: false,
        isFromLocal: true,
        onSuccessPrintReceiptCache: (listPRC) {},
      );

      prints('✅ Save to predefined order completed successfully');

      /// [SHOW SECOND DISPLAY]
      await ref.read(secondDisplayProvider.notifier).showMainCustomerDisplay();
      // print cache to print kitchen
      if (newListSaleItems.isNotEmpty) {
        await _printReceiptCacheNotifier.insertDetailsPrintCache(
          saleModel: updatedSaleModel,
          listSaleItemModel: newListSaleItems,
          listSM: newListSM,
          listSMO: newListSMO,
          pom: pom,
          orderOptionModel: saleItemState1.orderOptionModel!,
          printType: DepartmentTypeEnum.printKitchen,
          isForThisDevice: false,
        );
      }

      // print cache to print void
      if (clearedItems.isNotEmpty) {
        await _printReceiptCacheNotifier.insertDetailsPrintCache(
          saleModel: updatedSaleModel,
          listSaleItemModel: clearedItems,
          listSM: clearedListSaleModifiers,
          listSMO: clearedListSaleModifierOptions,
          orderOptionModel: saleItemState1.orderOptionModel!,
          pom: pom,
          printType: DepartmentTypeEnum.printVoid,
          isForThisDevice: false,
        );
      }

      if (currSelectedTable?.id != null) {
        updatedSaleModel = updatedSaleModel.copyWith(
          tableId: currSelectedTable?.id,
          tableName: currSelectedTable?.name,
        );
      }

      // Handle table and predefined order updates
      if (currSelectedTable?.id != null) {
        TableModel updatedTableModel = currSelectedTable!.copyWith(
          predefinedOrderId: pom.id,
          status: TableStatusEnum.OCCUPIED,
          staffId: _staffModel.id,
          saleId: saleId,
          customerId: customerNotifier.getOrderCustomerModel?.id,
          updatedAt: DateTime.now(),
        );

        PredefinedOrderModel updatedPOModel = pom.copyWith(
          tableId: updatedTableModel.id,
          tableName: updatedTableModel.name,
          isOccupied: true,
          name: pom.name ?? "null",
        );

        prints("updated predefined order model ${updatedPOModel.toJson()}}");

        await _predefinedOrderNotifier.update(updatedPOModel);
        await _tableNotifier.upsertBulk([updatedTableModel]);
        customerNotifier.setOrderCustomerModel(null);
      } else {
        PredefinedOrderModel updatedPOModel = pom.copyWith(
          tableId: null,
          tableName: null,
          isOccupied: true,
          name: pom.name ?? "null",
        );
        await _predefinedOrderNotifier.upsertBulk([updatedPOModel]);
        updatedSaleModel.tableId = null;
        updatedSaleModel.tableName = null;
      }

      // Save everything
      await _saleNotifier.upsertBulk([updatedSaleModel]);

      await Future.wait([
        _saleNotifier.unChargeSale(updatedSaleModel),
        _saleItemNotifier.upsertBulk(newListSaleItems),
        _saleModifierNotifier.upsertBulk(newListSM),
        _saleModifierOptionNotifier.upsertBulk(newListSMO),
        _deletedSaleItemNotifier.createAndInsertDeletedSaleItemModel(
          saleModel: updatedSaleModel,
        ),
      ]);

      await Future.wait([
        _inventoryNotifier.updateInventoryInSaleItem(
          newListSaleItems,
          InventoryTransactionTypeEnum.stockOut,
        ),
        _inventoryNotifier.updateInventoryInSaleItem(
          clearedItems,
          InventoryTransactionTypeEnum.stockIn,
        ),
      ]);
    } catch (e) {
      LoadingDialog.hide(context);
      if (!kDebugMode) {
        ThemeSnackBar.showSnackBar(
          context,
          "ERROR in handleSaveToSamePredefinedOrder: $e",
        );
        return;
      } else {
        rethrow;
      }
    }
  }

  Future<void> attemptPrintVoidAndKitchen(
    SaleModel updatedSaleModel, {
    required bool isPrintAgain,
    required bool isFromLocal,
    required Function(List<PrintReceiptCacheModel>) onSuccessPrintReceiptCache,
  }) async {
    List<String> errorMessages = [];
    List<String> errorIps = [];
    List<PrintReceiptCacheModel> listErrorPRC = [];

    // ✅ MODIFIED: Use the new sequential function instead of two separate calls
    await _printerSettingNotifier.onHandlePrintVoidAndKitchen(
      departmentType: null,
      onSuccessPrintReceiptCache: (listPRC) {
        onSuccessPrintReceiptCache(listPRC);

        // to handle print error because we also pass the callback when onError
        // why first? because we only have one prc when print kitchen
        if (listPRC.isNotEmpty) {
          listErrorPRC = listPRC;
        }
      },
      onSuccess: () {
        prints('SUCCESS: BOTH VOID AND KITCHEN PRINTING COMPLETED');
      },
      onError: (message, ipAddress) {
        prints('ERROR IN COMBINED PRINTING: $message at $ipAddress');
        if (message != '-1') {
          _collectPrintErrors(errorMessages, errorIps, message, ipAddress);
        }
      },
    );

    if (errorIps.isNotEmpty) {
      if (mounted) {
        _showPrintErrorDialog(
          context,
          errorMessages,
          errorIps,
          updatedSaleModel,
          listErrorPRC,
        );
      }
    }
  }

  void _collectPrintErrors(
    List<String> errorMessages,
    List<String> errorIps,
    String message,
    String ipAddress,
  ) {
    if (message == '-1') {
      DialogUtils.printerErrorDialogue(
        context,
        'connectionTimeout'.tr(),
        null,
        'pleaseAddPrinterToPrint'.tr(),
      );
      return;
    }

    if (!errorIps.contains(ipAddress)) {
      errorIps.add(ipAddress);
      errorMessages.add(message);
    }
  }

  void _showPrintErrorDialog(
    BuildContext context,
    List<String> errorMessages,
    List<String> errorIps,
    SaleModel updatedSaleModel,
    List<PrintReceiptCacheModel> listPRC,
  ) {
    prints(
      "📊📊📊📊📊📊📊📊📊📊📊📊📊📊📊📊📊📊 Error listPRC count: ${listPRC.length}📊📊📊📊📊📊📊📊📊📊📊📊",
    );
    CustomDialog.show(
      context,
      dialogType: DialogType.danger,
      icon: FontAwesomeIcons.print,
      title: 'somePrintersFailed'.tr(),
      description:
          "${'pleaseCheckYourPrinterWithIP'.tr()} ${errorIps.join(', ')} \n ${'doYouWantToPrintAgain'.tr()}",
      btnCancelText: 'cancel'.tr(),
      btnCancelOnPress: () {
        NavigationUtils.pop(context);
      },
      btnOkText: 'printAgain'.tr(),
      btnOkOnPress: () async {
        // close error dialogue
        NavigationUtils.pop(context);

        if (listPRC.isNotEmpty) {
          for (PrintReceiptCacheModel prc in listPRC) {
            SaleModel modelSale = prc.printData?.saleModel ?? SaleModel();
            List<SaleItemModel> listSI = prc.printData?.listSaleItems ?? [];
            List<SaleModifierModel> listSM = prc.printData?.listSM ?? [];
            List<SaleModifierOptionModel> listSMO =
                prc.printData?.listSMO ?? [];
            OrderOptionModel orderOptionModel =
                prc.printData?.orderOptionModel ?? OrderOptionModel();

            PredefinedOrderModel predefinedOrderModel =
                prc.printData?.predefinedOrderModel ?? PredefinedOrderModel();
            await _printReceiptCacheNotifier.insertDetailsPrintCache(
              saleModel: modelSale,
              listSaleItemModel: listSI,
              listSM: listSM,
              listSMO: listSMO,
              pom: predefinedOrderModel,
              orderOptionModel: orderOptionModel,
              printType: prc.printType ?? '',
              isForThisDevice: true,
            );
          }

          attemptPrintVoidAndKitchen(
            updatedSaleModel,
            isPrintAgain: true,
            isFromLocal: true,
            onSuccessPrintReceiptCache: (printReceiptCacheModels) {
              // kosong sebab isPrintAgain = true
            },
          );
        }
      },
    );
  }

  Future<void> handleSaveOrder() async {
    final tableModel = ref.read(saleItemProvider).selectedTable;
    final listPredefinedOrder =
        await _predefinedOrderNotifier.getListPredefinedOrderWhereOccupied0();
    if (listPredefinedOrder.isEmpty) {
      // go custom
      ref
          .read(dialogNavigatorProvider.notifier)
          .setPageIndex(DialogNavigatorEnum.customOrder);
    } else if (tableModel?.id == null) {
      ref
          .read(dialogNavigatorProvider.notifier)
          .setPageIndex(DialogNavigatorEnum.saveOrder);
    } else {
      if (tableModel?.predefinedOrderId == null) {
        // table model not set PO
        // go custom
        ref
            .read(dialogNavigatorProvider.notifier)
            .setPageIndex(DialogNavigatorEnum.customOrder);
      }
    }

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dialogueContext) {
        PrintReceiptCacheModel prcModel = PrintReceiptCacheModel();
        return SaveOrderDialogue(
          onCallbackPrintReceiptCache: (listPRC) {
            if (listPRC.isNotEmpty) {
              prcModel = listPRC.first;
            }
          },
          onPrintError: (message) {
            if (message.isNotEmpty) {
              // this callback only for custom orders
              prints('SHOW PRINTER ERROR DIALOGUE: $message');
              // ThemeSnackBar.showSnackBar(context, message);
              if (message != '-1') {
                final globalContext = navigatorKey.currentContext;
                if (globalContext == null) {
                  return;
                }
                // message will be ip address
                CustomDialog.show(
                  navigatorKey.currentContext!,
                  dialogType: DialogType.danger,
                  icon: FontAwesomeIcons.print,
                  title: message,
                  description:
                      "${'pleaseCheckYourPrinterWithIP'.tr()} $message \n ${'doYouWantToPrintAgain'.tr()}",
                  btnCancelText: 'cancel'.tr(),
                  btnCancelOnPress: () {
                    NavigationUtils.pop(navigatorKey.currentContext!);
                  },
                  btnOkText: 'printAgain'.tr(),
                  btnOkOnPress: () async {
                    // close error dialogue
                    NavigationUtils.pop(navigatorKey.currentContext!);

                    if (prcModel.id != null) {
                      SaleModel modelSale =
                          prcModel.printData?.saleModel ?? SaleModel();
                      List<SaleItemModel> listSI =
                          prcModel.printData?.listSaleItems ?? [];
                      List<SaleModifierModel> listSM =
                          prcModel.printData?.listSM ?? [];
                      List<SaleModifierOptionModel> listSMO =
                          prcModel.printData?.listSMO ?? [];
                      OrderOptionModel orderOptionModel =
                          prcModel.printData?.orderOptionModel ??
                          OrderOptionModel();

                      PredefinedOrderModel predefinedOrderModel =
                          prcModel.printData?.predefinedOrderModel ??
                          PredefinedOrderModel();

                      await _printReceiptCacheNotifier.insertDetailsPrintCache(
                        saleModel: modelSale,
                        listSaleItemModel: listSI,
                        listSM: listSM,
                        listSMO: listSMO,
                        pom: predefinedOrderModel,
                        orderOptionModel: orderOptionModel,
                        printType: DepartmentTypeEnum.printKitchen,
                        isForThisDevice: true,
                      );

                      // use back this function
                      await _saleNotifier.attemptPrintKitchen(
                        onSuccessPrintReceiptCache: (listPRC) {},
                      );
                    } else {
                      ThemeSnackBar.showSnackBar(
                        navigatorKey.currentContext!,
                        "Please open the order and reprint the order.",
                      );
                    }
                  },
                );
              } else {
                // /// [client kata tak perlu dialogue printer error, 'nampak macam sistem ada error']
                // DialogUtils.printerErrorDialogue(
                //   context,
                //   'connectionTimeout'.tr(),
                //   null,
                //   'pleaseAddPrinterToPrint'.tr(),
                // );
              }
            }
          },
        );
      },
    );
  }

  Widget total() {
    // Get the total value from Riverpod state
    final saleItemsState = ref.watch(saleItemProvider);
    final totalAfterDiscountAndTax = saleItemsState.totalAfterDiscountAndTax;
    final displayTotal =
        totalAfterDiscountAndTax <= 0 ? 0 : totalAfterDiscountAndTax;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'total'.tr(),
            style: AppTheme.normalTextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Text(
                'rm'.tr(),
                style: AppTheme.normalTextStyle(fontWeight: FontWeight.bold),
              ),
              2.5.widthBox,
              RollingNumber(
                value: displayTotal.abs(), // Use absolute value
                //prefix: 'rm'.tr(),
                style: AppTheme.normalTextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          // RollingNumber(
          //   'RM'.tr(args: [totalAfterDiscountAndTax.toStringAsFixed(2)]),
          //   style: AppTheme.normalTextStyle(fontWeight: FontWeight.bold),
          // ),
        ],
      ),
    );
  }

  Widget tax() {
    // Get the tax value from Riverpod state
    final saleItemsState = ref.watch(saleItemProvider);
    final taxAfterDiscount = saleItemsState.taxAfterDiscount;

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 15, right: 15),
      child: InkWell(
        onTap: () {
          // Show dialogue here
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return const TaxDialogue();
            },
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('tax'.tr()),
            Text(
              FormatUtils.formatNumber(
                'RM'.tr(args: [taxAfterDiscount.toStringAsFixed(2)]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget taxIncluded() {
    // Get the tax value from Riverpod state
    final saleItemsState = ref.watch(saleItemProvider);
    final taxIncludedAfterDiscount = saleItemsState.taxIncludedAfterDiscount;

    if (taxIncludedAfterDiscount > 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, left: 15, right: 15),
        child: InkWell(
          onTap: () {
            // Show dialogue here
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return const TaxDialogue();
              },
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${'tax'.tr()} (Included)",
                style: textStyleNormal(color: kTextGray),
              ),
              Text(
                FormatUtils.formatNumber(
                  'RM'.tr(args: [taxIncludedAfterDiscount.toStringAsFixed(2)]),
                ),
                style: textStyleNormal(color: kTextGray),
              ),
            ],
          ),
        ),
      );
    } else {
      return SizedBox.shrink(); // Return an empty widget or SizedBox.shrink()
    }
  }

  Future<void> handleSaveToSamePoAfterUnlinkTable(
    SaleItemNotifier saleItemsNotifier,
    SaleItemState saleItemsState,
  ) async {
    // in this function, sale id is not exist which is rare case. so we just handle to to create new sales id and save it
    final customerNotifier = ref.read(customerProvider.notifier);
    final predefinedOrderModel = saleItemsState.pom;

    double totalPrice = saleItemsState.totalAfterDiscountAndTax;

    // get staff model to get staff id
    UserModel userModel = ServiceLocator.get<UserModel>();

    if (predefinedOrderModel?.id == null) {
      // rare case
      String message = "Predefined Order id is null, cannot save custom order";
      ThemeSnackBar.showSnackBar(context, message);
      await _errorLogNotifier.createAndInsertErrorLog(message);
      return;
    }

    if (userModel.id == null) {
      // rare case
      String message = "User id is null, cannot save custom order";
      ThemeSnackBar.showSnackBar(context, message);
      await _errorLogNotifier.createAndInsertErrorLog(message);
      return;
    }

    StaffModel? staffModel = await _staffNotifier.getStaffModelByUserId(
      userModel.id!.toString(),
    );

    if (staffModel == null || staffModel.userId != userModel.id) {
      // rare case
      String message = "Staff id is conflict, cannot save custom order";
      ThemeSnackBar.showSnackBar(context, message);
      await _errorLogNotifier.createAndInsertErrorLog(message);
      return;
    }

    List<SaleItemModel> listSaleItems = saleItemsState.saleItems;
    List<SaleItemModel> newListSaleItems = [];

    List<SaleModifierModel> listSaleModifierModels =
        saleItemsState.saleModifiers;
    List<SaleModifierModel> newListSM = [];

    List<SaleModifierOptionModel> listSaleModifierOptionModels =
        saleItemsState.saleModifierOptions;
    List<SaleModifierOptionModel> newListSMO = [];
    String newSaleId = IdUtils.generateUUID();

    // last step, clear the order sale item in the notifier
    saleItemsNotifier.setSelectedTable(TableModel());
    saleItemsNotifier.setPredefinedOrderModel(PredefinedOrderModel());
    saleItemsNotifier.setCurrSaleModel(SaleModel());
    customerNotifier.setOrderCustomerModel(null);
    saleItemsNotifier.clearOrderItems();
    saleItemsNotifier.calcTotalAfterDiscountAndTax();
    saleItemsNotifier.calcTaxAfterDiscount();
    saleItemsNotifier.calcTaxIncludedAfterDiscount();
    saleItemsNotifier.calcTotalDiscount();

    List<String> listJson = [];
    if (listSaleItems.isNotEmpty) {
      for (SaleItemModel saleItemModel in listSaleItems) {
        String newSaleItemId = IdUtils.generateUUID();

        // get the sale modifier list by sale item id to get the id
        List<SaleModifierModel> listSM =
            listSaleModifierModels
                .where((element) => element.saleItemId == saleItemModel.id)
                .toList();

        if (listSM.isNotEmpty) {
          for (var currSM in listSM) {
            SaleModifierModel newSM = currSM.copyWith(
              saleItemId: newSaleItemId,
            );
            newListSM.add(newSM);

            List<SaleModifierOptionModel> listSMO =
                listSaleModifierOptionModels
                    .where((element) => element.saleModifierId == currSM.id)
                    .toList();

            if (listSMO.isNotEmpty) {
              for (var currSMO in listSMO) {
                SaleModifierOptionModel newSMO = currSMO.copyWith(
                  saleModifierId: currSM.id,
                );
                newListSMO.add(newSMO);
              }
            }
          }
        }

        String modifierJson = await _modifierNotifier.convertListModifierToJson(
          saleItemModel,
          listSaleModifierModels,
          listSaleModifierOptionModels,
        );
        //  prints(modifierJson);
        listJson.add(modifierJson);
        // return [modifierModel.toJson()];

        // generate new to avoid duplicate from list in notifier
        // prints("newSAle item id $newSaleItemId");
        SaleItemModel newSaleItemModel = saleItemModel.copyWith(
          id: newSaleItemId,
          saleId: newSaleId,
          isVoided: false,
          // isPrintedKitchen: false,
          // isPrintedVoided: false,
        );

        newListSaleItems.add(newSaleItemModel);
      }
    }

    // update running number
    int latestRunningNumber = 1;
    await _outletNotifier.incrementNextOrderNumber(
      onRunningNumber: (runningNumber) {
        latestRunningNumber = runningNumber;
      },
    );

    // generate new sale model
    SaleModel newSaleModel = SaleModel(
      id: newSaleId,
      staffId: _staffModel.id,
      outletId: _outletModel.id,
      // table id and table name null because the table is unlinked
      predefinedOrderId: predefinedOrderModel?.id,
      name: predefinedOrderModel?.name,
      remarks: predefinedOrderModel?.remarks,
      runningNumber: latestRunningNumber,
      totalPrice: double.parse(totalPrice.toStringAsFixed(2)),
      orderOptionId: saleItemsState.orderOptionModel?.id,
      saleItemCount: newListSaleItems.length,
    );

    await _printReceiptCacheNotifier.insertDetailsPrintCache(
      saleModel: newSaleModel,
      listSaleItemModel: newListSaleItems,
      listSM: newListSM,
      listSMO: newListSMO,
      pom: predefinedOrderModel!,
      orderOptionModel: saleItemsState.orderOptionModel!,
      printType: DepartmentTypeEnum.printKitchen,
      isForThisDevice: true,
    );

    /// [print to kitchen]
    await _printerSettingNotifier.onHandlePrintVoidAndKitchen(
      departmentType: null,
      onSuccessPrintReceiptCache: (listPRC) {},
      onSuccess: () {
        prints('SUCCESS PRINT VOID ORDER TO DEPARTMENT PRINTER');
      },
      onError: (message, ipAddress) {
        prints(
          'ERROR PRINT VOID ORDER TO DEPARTMENT PRINTER $ipAddress $message',
        );
        if (message != '-1') {
          _collectPrintErrors([], [], message, ipAddress);
        }
      },
    );

    /// [SHOW SECOND DISPLAY]
    await ref.read(secondDisplayProvider.notifier).showMainCustomerDisplay();

    await _printReceiptCacheNotifier.insertDetailsPrintCache(
      saleModel: newSaleModel,
      listSaleItemModel: newListSaleItems,
      listSM: newListSM,
      listSMO: newListSMO,
      orderOptionModel: saleItemsState.orderOptionModel!,
      pom: predefinedOrderModel,
      printType: DepartmentTypeEnum.printKitchen,
      isForThisDevice: false,
    );

    await _saleNotifier.insert(newSaleModel);

    await Future.wait([
      ...newListSaleItems.map((e) => _saleItemNotifier.insert(e)),
      ...newListSM.map((e) => _saleModifierNotifier.insert(e)),
      ...newListSMO.map((e) => _saleModifierOptionNotifier.insert(e)),
    ]);

    // make the PO occupeid
    // because of table is null, we need to update the table attribute in PO
    final updatePO = predefinedOrderModel.copyWith();
    updatePO.tableId = null;
    updatePO.tableName = null;
    updatePO.isOccupied = true;
    await _predefinedOrderNotifier.upsertBulk([updatePO]);

    await _inventoryNotifier.updateInventoryInSaleItem(
      newListSaleItems,
      InventoryTransactionTypeEnum.stockOut,
    );
  }

  /// Helper method to optimize data transfer to second display
  Future<void> showOptimizedSecondDisplay(
    Map<String, dynamic> dataToTransfer,
  ) async {
    if (!mounted) return;

    // Get slideshow model - this could be cached as well if it doesn't change often
    // cached in initState
    final SlideshowModel currSdModel = slideShowModel;

    // Get user model
    final currentUser =
        ref.read(userProvider.notifier).currentUser ?? UserModel();

    // Create a lightweight data package with only essential information
    Map<String, dynamic> data = {
      // Add a unique update ID to track this update
      DataEnum.cartUpdateId: IdUtils.generateUUID(),
      // Add user model and slideshow data
      DataEnum.userModel: currentUser.toJson(),
      DataEnum.slideshow: currSdModel.toJson(),
      DataEnum.showThankYou: false,
      DataEnum.isCharged: false,
    };

    // Add any specific transaction data from the original dataToTransfer
    // but avoid duplicating large data structures
    dataToTransfer.forEach((key, value) {
      if (key != DataEnum.listItems &&
          key != DataEnum.listMO &&
          !data.containsKey(key)) {
        data[key] = value;
      }
    });

    // Use cached common data instead of regenerating it every time
    if (MenuItem.getCachedCommonData().isNotEmpty) {
      prints('✅ OrderListSales._cachedCommonData.isNotEmpty');
      // Only add cached data if it's not already in the data package
      MenuItem.getCachedCommonData().forEach((key, value) {
        if (!data.containsKey(key)) {
          data[key] = value;
        }
      });
    } else {
      prints('⚠️ OrderListSales._cachedCommonData is empty');
    }

    // Use the optimized update method for the second display
    // prints("data[DataEnum.listSM] ${data[DataEnum.listSM]}");
    await updateSecondaryDisplay(data);
  }

  Future<void> updateSecondaryDisplay(Map<String, dynamic> data) async {
    try {
      await ref.read(slideshowProvider.notifier).updateSecondaryDisplay(data);
    } catch (e) {
      prints('Error updating second display: $e');
      // Fallback to basic update if there's an error
      if (mounted) {
        await ref.read(slideshowProvider.notifier).updateSecondaryDisplay(data);
      }
    }
  }
}
