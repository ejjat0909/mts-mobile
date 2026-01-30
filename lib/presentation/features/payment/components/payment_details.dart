import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/enum/tax_type_enum.dart';
import 'package:mts/core/enums/inventory_transaction_type_enum.dart';
import 'package:mts/core/utils/calc_utils.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/enum/db_response_enum.dart';
import 'package:mts/core/enum/payment_type_enum.dart';
import 'package:mts/core/enum/printer_setting_enum.dart';
import 'package:mts/core/enum/receipt_status_enum.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/data/models/category/category_model.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/data/models/default_response_model.dart';
import 'package:mts/data/models/discount/discount_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/main.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/button_primary.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/customer_display_preview/main_customer_display.dart';
import 'package:mts/presentation/features/customer_display_preview/main_customer_display_show_receipt.dart';
import 'package:mts/presentation/features/home/home_screen.dart';
import 'package:mts/presentation/features/home_receipt/components/send_email_dialogue.dart';
import 'package:mts/presentation/features/payment/components/numpad.dart';
import 'package:mts/presentation/features/sales/components/menu_item.dart';
import 'package:mts/data/services/receipt_printer_service.dart';
import 'package:mts/providers/category_discount/category_discount_providers.dart';
import 'package:mts/providers/category/category_providers.dart';
import 'package:mts/providers/customer/customer_providers.dart';
import 'package:mts/providers/device/device_providers.dart';
import 'package:mts/providers/discount/discount_providers.dart';
import 'package:mts/providers/discount_item/discount_item_providers.dart';
import 'package:mts/providers/discount_outlet/discount_outlet_providers.dart';
import 'package:mts/providers/inventory/inventory_providers.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/modifier/modifier_providers.dart';
import 'package:mts/providers/outlet/outlet_providers.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';
import 'package:mts/providers/outlet_payment_type/outlet_payment_type_providers.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';
import 'package:mts/providers/payment/payment_providers.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';
import 'package:mts/providers/receipt_item/receipt_item_providers.dart';
import 'package:mts/providers/sale/sale_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/sale_item/sale_item_state.dart';
import 'package:mts/providers/shift/shift_providers.dart';
import 'package:mts/providers/slideshow/slideshow_providers.dart';
import 'package:mts/providers/split_payment/split_payment_providers.dart';
import 'package:mts/providers/split_payment/split_payment_state.dart';
import 'package:mts/providers/staff/staff_providers.dart';
import 'package:mts/providers/table_layout/table_layout_providers.dart';
import 'package:mts/providers/tax/tax_providers.dart';
import 'package:mts/providers/user/user_providers.dart';

class PaymentDetails extends ConsumerStatefulWidget {
  // Static timer for debouncing second display updates (1.5 seconds)
  static Timer? _secondDisplayDebounceTimer;
  // Map to accumulate pending payment method changes
  static final Map<String, Map<String, dynamic>> _pendingSecondDisplayUpdates =
      {};
  // Flag to track if second display update is pending
  static bool _isSecondDisplayUpdatePending = false;

  // Cache for payment methods to avoid repeated loading
  static List<PaymentTypeModel>? _cachedPaymentMethods;
  static PaymentTypeModel? _cachedDefaultPaymentMethod;
  static bool _isCacheInitialized = false;

  // Cache for common second display data
  static Map<String, dynamic> _cachedSecondDisplayData = {};

  // Queue for initialization operations
  static final Queue<Function> _initializationQueue = Queue<Function>();
  static bool _isProcessingInitQueue = false;

  // Flag to track if we're navigating away to prevent new operations
  static bool _isNavigatingAway = false;

  final BuildContext orderListContext;
  const PaymentDetails({super.key, required this.orderListContext});

  /// Schedule a debounced second display update for payment method changes
  /// This method accumulates changes and only sends to second display after 1.5 seconds of inactivity
  static void _scheduleSecondDisplayUpdate(
    String paymentMethodId,
    Map<String, dynamic> dataToTransfer,
    Function sendToSecondDisplay,
  ) {
    // Cancel existing debounce timer
    _secondDisplayDebounceTimer?.cancel();

    // Accumulate the pending update data
    _pendingSecondDisplayUpdates[paymentMethodId] = dataToTransfer;
    _isSecondDisplayUpdatePending = true;

    prints(
      '📱 Scheduling second display update for payment method: $paymentMethodId (1.5s debounce)',
    );

    // Set new debounce timer for 1.5 seconds
    _secondDisplayDebounceTimer = Timer(
      const Duration(milliseconds: 500),
      () async {
        prints(
          '⏰ Debounce timer triggered - sending accumulated payment updates to second display',
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
        '🚀 Sending ${_pendingSecondDisplayUpdates.length} accumulated payment updates to second display',
      );

      // Get the most recent update data (last payment method that was selected)
      final String lastPaymentMethodId = _pendingSecondDisplayUpdates.keys.last;
      final Map<String, dynamic> finalData =
          _pendingSecondDisplayUpdates[lastPaymentMethodId]!;

      // Send the final accumulated state to second display
      await sendToSecondDisplay(finalData);

      prints(
        '✅ Successfully sent accumulated payment updates to second display',
      );
    } catch (e) {
      prints(
        '❌ Error sending accumulated payment updates to second display: $e',
      );
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
    prints('🚫 Cancelled pending payment second display updates');
  }

  /// Initialize cache with payment methods data
  static void initializePaymentCache(
    List<PaymentTypeModel> paymentMethods,
    PaymentTypeModel? defaultPaymentMethod,
  ) {
    prints("💾💾💾💾💾💾");
    _cachedPaymentMethods = List<PaymentTypeModel>.from(paymentMethods);
    _cachedDefaultPaymentMethod = defaultPaymentMethod;
    _isCacheInitialized = true;

    prints(
      '💾 Payment cache initialized with ${paymentMethods.length} methods',
    );
  }

  static void reInitializePaymentCache(
    List<PaymentTypeModel> paymentMethods,
    PaymentTypeModel? defaultPaymentMethod,
  ) {
    _cachedPaymentMethods = List<PaymentTypeModel>.from(paymentMethods);
    _cachedDefaultPaymentMethod = defaultPaymentMethod;

    prints(
      '💾 Payment cache RE-initialized with ${paymentMethods.length} methods',
    );
  }

  /// Update payment cache when data changes
  static void updatePaymentCache(
    List<PaymentTypeModel> paymentMethods,
    PaymentTypeModel? defaultPaymentMethod,
  ) {
    _cachedPaymentMethods = List<PaymentTypeModel>.from(paymentMethods);
    _cachedDefaultPaymentMethod = defaultPaymentMethod;
    prints('🔄 Payment cache updated with ${paymentMethods.length} methods');
  }

  /// Get cached payment methods
  static List<PaymentTypeModel>? getCachedPaymentMethods() {
    return _cachedPaymentMethods;
  }

  /// Get cached default payment method
  static PaymentTypeModel? getCachedDefaultPaymentMethod() {
    return _cachedDefaultPaymentMethod;
  }

  /// Check if cache is initialized
  static bool isCacheInitialized() {
    return _isCacheInitialized;
  }

  /// Clear payment cache
  static void clearPaymentCache() {
    _cachedPaymentMethods = null;
    _cachedDefaultPaymentMethod = null;
    _isCacheInitialized = false;
    _cachedSecondDisplayData.clear();
    prints('🗑️ Payment cache cleared');
  }

  /// Prepare for smooth transition from sales screen
  /// This method should be called when navigating to payment screen
  static void prepareForSalesTransition() {
    // Cancel any pending second display updates to prevent conflicts
    cancelPendingSecondDisplayUpdates();

    // Reduce debounce timer for faster response during payment operations
    prints('🔄 Preparing for sales transition - optimizing payment screen');
  }

  /// Reset optimization settings after transition is complete
  static void resetAfterSalesTransition() {
    // Clear any processing flags to ensure smooth operation
    PaymentDetails._isProcessingInitQueue = false;
    PaymentDetails._isNavigatingAway = false;

    prints('✅ Sales transition complete - reset payment optimization settings');
  }

  /// Clear initialization queue to prevent blocking operations during navigation
  static void clearInitializationQueue() {
    _initializationQueue.clear();
    _isProcessingInitQueue = false;
    prints('🗑️ Cleared initialization queue for navigation');
  }

  /// Set navigation flag to prevent new operations during navigation
  static void setNavigatingAway(bool isNavigating) {
    _isNavigatingAway = isNavigating;
    if (isNavigating) {
      // Also clear any pending operations
      clearInitializationQueue();
      cancelPendingSecondDisplayUpdates();
    }
    prints('🚪 Navigation flag set to: $isNavigating');
  }

  /// Check if we're currently navigating away
  static bool isNavigatingAway() {
    return _isNavigatingAway;
  }

  /// Pre-warm payment cache for smooth navigation
  /// This method can be called before navigating to payment screen
  static Future<void> preWarmCache() async {
    try {
      // Initialize cache if not already done
      if (!_isCacheInitialized) {
        // Initialize with empty data - will be populated when payment screen loads
        _cachedPaymentMethods = <PaymentTypeModel>[];
        _cachedDefaultPaymentMethod = null;
        _isCacheInitialized = true;
        prints('💾 Payment cache initialized for pre-warming');
      }

      // Pre-load common second display data
      _cachedSecondDisplayData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'preWarmed': true,
      };

      prints('🔥 Payment cache pre-warmed for smooth navigation');
    } catch (e) {
      prints('❌ Error pre-warming payment cache: $e');
    }
  }

  @override
  ConsumerState<PaymentDetails> createState() => _PaymentDetailsState();
}

class _PaymentDetailsState extends ConsumerState<PaymentDetails> {
  int _selectedPaymentType = -1;
  String? paymentTypeName;
  PaymentTypeModel? paymentTypeModel;
  bool isNewSale = false;
  final TextEditingController _inputController = TextEditingController();
  // Secondary display interactions now handled via secondDisplayProvider
  late final PredefinedOrderNotifier _predefinedOrderNotifier;
  late final SaleNotifier _saleNotifier;
  late final ReceiptNotifier _receiptNotifier;
  late final ShiftNotifier _shiftNotifier;
  late final SlideshowNotifier _slideshowNotifier;
  late final PrinterSettingNotifier _printerSettingNotifier;
  late final ItemNotifier _itemNotifier;
  late final ReceiptItemNotifier _receiptItemNotifier;
  late final StaffNotifier _staffNotifier;
  late final UserNotifier _userNotifier;
  late final ModifierNotifier _modifierNotifier;
  late final CategoryNotifier _categoryNotifier;
  late final DiscountNotifier _discountNotifier;
  late final TaxNotifier _taxNotifier;
  late final SaleItemNotifier _saleItemNotifier;
  late final InventoryNotifier _inventoryNotifier;
  late final OutletNotifier _outletNotifier;
  late final SecondDisplayNotifier _secondDisplayNotifier;
  late final DeviceNotifier _deviceNotifier;
  // splitNotifier moved to methods where needed - use ref.read(splitPaymentProvider.notifier)

  ShiftModel shiftModel = ShiftModel();
  OutletModel outletModel = ServiceLocator.get<OutletModel>();
  PosDeviceModel deviceModel = ServiceLocator.get<PosDeviceModel>();
  UserModel userModel = GetIt.instance<UserModel>();
  String buttonChargeText = 'charge'.tr();
  bool isContextActive = true;
  bool isPrinted = false;

  /// Update second display with payment method change using debounced approach
  Future<void> _updateSecondDisplayWithPaymentChange(
    SaleItemState saleItemsState,
    SplitPaymentState splitPaymentState,
    PaymentTypeModel selectedPaymentMethod,
  ) async {
    try {
      // Calculate the current totalAmountRemaining with proper cash rounding logic
      double totalAmountRemaining =
          saleItemsState.isSplitPayment
              ? splitPaymentState.paymentTypeModel != null &&
                      splitPaymentState.paymentTypeModel!.autoRounding!
                  ? CalcUtils.calcCashRounding(
                    splitPaymentState.totalWithAdjustedPrice,
                  )
                  : splitPaymentState.totalWithAdjustedPrice
              : selectedPaymentMethod.autoRounding!
              ? CalcUtils.calcCashRounding(
                saleItemsState.totalWithAdjustedPrice,
              )
              : saleItemsState.totalWithAdjustedPrice;

      prints(
        'TOTAL AMOUNT REMAINGINGGGGGGGG: ${totalAmountRemaining.toStringAsFixed(2)}',
      );

      double totalAmountPaid =
          saleItemsState.isSplitPayment
              ? splitPaymentState.totalAmountPaid
              : saleItemsState.totalAmountPaid;

      // Use microtask to defer heavy operations and avoid blocking UI
      final String paymentMethodId =
          selectedPaymentMethod.id?.toString() ??
          selectedPaymentMethod.name ??
          'unknown';

      // Defer the data preparation to avoid blocking the UI thread
      scheduleMicrotask(() async {
        // Small delay to ensure UI is fully rendered
        await Future.delayed(const Duration(milliseconds: 5));

        try {
          // Prepare data asynchronously without blocking
          Map<String, dynamic> dataToTransfer =
              await _prepareSecondDisplayDataNonBlocking(
                saleItemsState,
                totalAmountRemaining,
                totalAmountPaid,
                selectedPaymentMethod,
              );

          // Schedule the update
          PaymentDetails._scheduleSecondDisplayUpdate(
            paymentMethodId,
            dataToTransfer,
            (Map<String, dynamic> data) => _sendToSecondDisplay(data),
          );
        } catch (e) {
          prints('❌ Error in deferred second display update: $e');
        }
      });

      prints(
        '📅 Scheduled debounced second display update for payment method: $paymentMethodId',
      );
    } catch (e) {
      prints('❌ Error updating second display with payment change: $e');
    }
  }

  /// Non-blocking version of second display update for initState
  Future<void> _updateSecondDisplayWithPaymentChangeNonBlocking() async {
    try {
      // Check if secondary display is available before proceeding
      if (!hasSecondaryDisplay || secondaryDisplayId == null) {
        prints('⚠️ No secondary display available, skipping update');
        return;
      }

      await Future.delayed(const Duration(milliseconds: 150));

      // Get current state without triggering rebuilds
      final saleItemsState = ref.read(saleItemProvider);
      final splitNotifier = ref.read(splitPaymentProvider.notifier);

      // Ensure payment methods are loaded before proceeding
      if (paymentMethods.isEmpty) {
        // Try to load payment methods if not already loaded
        final newPaymentMethods = _loadPaymentMethodsSilent();
        if (newPaymentMethods != null && newPaymentMethods.isNotEmpty) {
          paymentMethods = newPaymentMethods;
        } else {
          prints('⚠️ No payment methods available for second display update');
          return;
        }
      }

      // Use default payment method if none selected yet
      PaymentTypeModel? selectedPaymentMethod;
      if (_selectedPaymentType >= 0 &&
          _selectedPaymentType < paymentMethods.length) {
        selectedPaymentMethod = paymentMethods[_selectedPaymentType];
      } else {
        // Use first available payment method as default
        selectedPaymentMethod = paymentMethods[0];
        // Optionally set this as the selected payment type for consistency
        _selectedPaymentType = 0;
        paymentTypeName = selectedPaymentMethod.name;
        paymentTypeModel = selectedPaymentMethod;
      }

      // Calculate the current totalAmountRemaining with proper cash rounding logic
      double totalAmountRemaining =
          saleItemsState.isSplitPayment
              ? splitNotifier.getPaymentTypeModel != null &&
                      splitNotifier.getPaymentTypeModel!.autoRounding!
                  ? CalcUtils.calcCashRounding(
                    splitNotifier.getTotalWithAdjustedPrice,
                  )
                  : splitNotifier.getTotalWithAdjustedPrice
              : selectedPaymentMethod.autoRounding!
              ? CalcUtils.calcCashRounding(
                saleItemsState.totalWithAdjustedPrice,
              )
              : saleItemsState.totalWithAdjustedPrice;

      double totalAmountPaid =
          saleItemsState.isSplitPayment
              ? splitNotifier.getTotalAmountPaid
              : saleItemsState.totalAmountPaid;

      // Prepare data to transfer to second display (non-blocking version)
      Map<String, dynamic> dataToTransfer =
          await _prepareSecondDisplayDataNonBlocking(
            saleItemsState,
            totalAmountRemaining,
            totalAmountPaid,
            selectedPaymentMethod,
          );

      // Send directly to second display without debouncing for initState
      await _sendToSecondDisplay(dataToTransfer);

      prints(
        '✅ Auto-triggered second display update completed for payment method: ${selectedPaymentMethod.name}',
      );
    } catch (e) {
      prints('❌ Error in non-blocking second display update: $e');
      // Don't rethrow to avoid breaking initState
    }
  }

  /// Non-blocking version of prepare data for second display transfer
  /// Uses ServiceLocator instead of context to avoid widget context issues
  /// Optimized to minimize await operations for better performance
  Future<Map<String, dynamic>> _prepareSecondDisplayDataNonBlocking(
    SaleItemState saleItemsState,
    double totalAmountRemaining,
    double totalAmountPaid,
    PaymentTypeModel selectedPaymentMethod,
  ) async {
    Map<String, dynamic> baseData;

    // Use cached slideshow model synchronously (no await needed since it's cached)
    SlideshowModel? slideshowModel = Home.getCachedSlideshowModel();

    // Only use await if we absolutely need to fetch from DB (rare case)
    if (slideshowModel == null) {
      prints(
        '⚠️ Slideshow cache not available in payment screen (non-blocking), falling back to DB call',
      );
      // Use unawaited to avoid blocking - slideshow is not critical for immediate display
      unawaited(() async {
        try {
          Map<String, dynamic> slideshowResponse =
              await _slideshowNotifier.getLatestModel();
          slideshowModel = slideshowResponse[DbResponseEnum.data];
        } catch (e) {
          prints('❌ Error fetching slideshow in background: $e');
        }
      }());
      // Continue with null slideshow to avoid blocking
      slideshowModel = null;
    } else {
      prints(
        '✅ Using cached slideshow model in payment screen (non-blocking) for consistency',
      );
    }

    if (saleItemsState.isSplitPayment) {
      // For split payment, use Riverpod provider
      final splitPaymentState = ref.read(splitPaymentProvider);

      baseData = {
        // Only serialize data that's actually needed for the display
        DataEnum.listSaleItems:
            splitPaymentState.saleItems.map((e) => e.toJson()).toList(),
        DataEnum.listSM:
            splitPaymentState.saleModifiers.map((e) => e.toJson()).toList(),
        DataEnum.listSMO:
            splitPaymentState.saleModifierOptions
                .map((e) => e.toJson())
                .toList(),

        // Add calculated totals from split payment state
        DataEnum.totalAfterDiscAndTax:
            splitPaymentState.totalAfterDiscountAndTax,
        DataEnum.totalDiscount: splitPaymentState.totalDiscount,
        DataEnum.totalTax: splitPaymentState.taxAfterDiscount,
        DataEnum.totalTaxIncluded: splitPaymentState.taxIncludedAfterDiscount,
        DataEnum.totalWithAdjustedPrice:
            splitPaymentState.paymentTypeModel != null &&
                    splitPaymentState.paymentTypeModel!.autoRounding!
                ? CalcUtils.calcCashRounding(
                  splitPaymentState.totalWithAdjustedPrice,
                )
                : splitPaymentState.totalWithAdjustedPrice,
      };

      // Add cached common data if available to avoid redundant processing
      if (MenuItem.isCacheInitialized()) {
        final cachedData = MenuItem.getCachedCommonData();
        // Use addEntries for better performance with large data
        baseData.addEntries([
          MapEntry(DataEnum.listItems, cachedData[DataEnum.listItems]),
          MapEntry(DataEnum.listMO, cachedData[DataEnum.listMO]),
        ]);
        prints('✅ CACHE DAH INITIALIZED 3 (non-blocking)');
      } else {
        prints("CACHE BELUM INITIALIZE 3 (non-blocking)");
      }
    } else {
      // For regular payment, use ref.read which should work in this context
      final saleItemNotifier = ref.read(saleItemProvider.notifier);
      baseData = saleItemNotifier.getMapDataToTransfer();

      // Optimize by using cached common data if available to avoid redundant processing
      if (MenuItem.isCacheInitialized()) {
        final cachedData = MenuItem.getCachedCommonData();
        // Use addEntries for better performance with large data
        baseData.addEntries([
          MapEntry(DataEnum.listItems, cachedData[DataEnum.listItems]),
          MapEntry(DataEnum.listMO, cachedData[DataEnum.listMO]),
        ]);
        prints('✅ CACHE DAH INITIALIZED 4 (non-blocking)');
      } else {
        prints("CACHE BELUM INITIALIZE 4 (non-blocking)");
      }
    }

    // Override the totalAmountRemaining and add payment-specific data for both cases
    baseData[DataEnum.isCharged] = true;
    baseData[DataEnum.totalAmountRemaining] = totalAmountRemaining;
    baseData[DataEnum.totalAmountPaid] = totalAmountPaid;
    baseData[DataEnum.selectedPaymentMethod] = selectedPaymentMethod.toJson();
    baseData[DataEnum.paymentMethodName] = selectedPaymentMethod.name ?? '';
    baseData[DataEnum.userModel] = userModel.toJson();
    baseData[DataEnum.slideshow] = slideshowModel?.toJson() ?? {};
    baseData['timestamp'] = DateTime.now().millisecondsSinceEpoch;

    return baseData;
  }

  /// Prepare optimized data for second display using cache approach
  Map<String, dynamic> _prepareOptimizedSecondDisplayData(
    Map<String, dynamic> originalData,
  ) {
    // Create a lightweight data package with only essential information
    Map<String, dynamic> optimizedData = {
      // Add payment-specific data that changes frequently
      DataEnum.totalAmountRemaining:
          originalData[DataEnum.totalAmountRemaining],
      DataEnum.totalAmountPaid: originalData[DataEnum.totalAmountPaid],
      DataEnum.selectedPaymentMethod:
          originalData[DataEnum.selectedPaymentMethod],
      DataEnum.paymentMethodName: originalData[DataEnum.paymentMethodName],
      DataEnum.isCharged: originalData[DataEnum.isCharged],
      'timestamp': originalData['timestamp'],

      // Add a unique update ID to track this update
      'paymentUpdateId': IdUtils.generateUUID(),
    };

    // Add only changed data from original to avoid duplicating large structures
    originalData.forEach((key, value) {
      // Include listItems and listMO if they're from cached data, skip if they're from fresh generation
      if (key == DataEnum.listItems || key == DataEnum.listMO) {
        // Only include if we have cached data (to avoid fresh serialization)
        if (MenuItem.isCacheInitialized()) {
          optimizedData[key] = value;
          prints('✅ Including cached $key in optimized data');
        } else {
          prints('⚠️ Skipping fresh $key to avoid redundant serialization');
        }
      } else if (!optimizedData.containsKey(key)) {
        optimizedData[key] = value;
      }
    });

    // Use cached common data if available to reduce transfer size
    if (PaymentDetails._cachedSecondDisplayData.isNotEmpty) {
      prints('🔥 Using cached common data PAYMENT DETAILS for second display');
      // Only add cached data if it's not already in the optimized data
      PaymentDetails._cachedSecondDisplayData.forEach((key, value) {
        if (!optimizedData.containsKey(key) &&
            key != 'timestamp' &&
            key != 'paymentUpdateId') {
          optimizedData[key] = value;
        }
      });
    }

    return optimizedData;
  }

  /// Send data to second display using optimized approach with caching
  Future<void> _sendToSecondDisplay(Map<String, dynamic> data) async {
    if (!mounted) return;

    try {
      // Use cached common data to reduce data transfer size
      Map<String, dynamic> optimizedData = _prepareOptimizedSecondDisplayData(
        data,
      );

      // Check if we're already on the receipt screen to avoid unnecessary navigation
      final String currentRouteName =
          _secondDisplayNotifier.getCurrentRouteName;

      if (currentRouteName == CustomerShowReceipt.routeName) {
        // If already on receipt screen, use optimized update
        await ref
            .read(secondDisplayProvider.notifier)
            .updateSecondaryDisplay(optimizedData);
        prints('✅ Updated second display with optimized cached method');
      } else {
        // If not on receipt screen, navigate to it
        await ref
            .read(secondDisplayProvider.notifier)
            .navigateSecondScreen(
              CustomerShowReceipt.routeName,
              data: optimizedData,
              isShowLoading: false,
            );
        prints('✅ Navigated to second display with cached payment data');
      }

      // Update cache with the sent data for future comparisons
      PaymentDetails._cachedSecondDisplayData = Map<String, dynamic>.from(
        optimizedData,
      );
    } catch (e) {
      prints('❌ Error sending data to second display: $e');
      // Fall back to navigation if update fails
      try {
        await ref
            .read(secondDisplayProvider.notifier)
            .navigateSecondScreen(
              CustomerShowReceipt.routeName,
              data: data, // Use original data as fallback
              isShowLoading: false,
            );
      } catch (fallbackError) {
        prints('❌ Fallback navigation also failed: $fallbackError');
      }
    }
  }

  // get from API

  List<PaymentTypeModel> paymentMethods = [];
  bool _isInitialized = false;
  bool _isLoading = true;

  // Static variables for post-dispose operations
  static Timer? _postDisposeTimer;
  static Map<String, dynamic>? _pendingPostDisposeData;
  static bool _hasPostDisposeOperations = false;

  @override
  void dispose() {
    isContextActive = false;

    // Execute post-dispose operations if scheduled
    if (_hasPostDisposeOperations) {
      _executePostDisposeOperations();
    }

    // Cancel any pending second display updates when disposing
    PaymentDetails.cancelPendingSecondDisplayUpdates();
    // Clear initialization queue to prevent memory leaks
    PaymentDetails._initializationQueue.clear();
    PaymentDetails._isProcessingInitQueue = false;
    // Reset navigation flag
    PaymentDetails._isNavigatingAway = false;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _predefinedOrderNotifier = ref.read(predefinedOrderProvider.notifier);
    _saleNotifier = ref.read(saleProvider.notifier);
    _receiptNotifier = ref.read(receiptProvider.notifier);
    _shiftNotifier = ref.read(shiftProvider.notifier);
    _slideshowNotifier = ref.read(slideshowProvider.notifier);
    _printerSettingNotifier = ref.read(printerSettingProvider.notifier);
    _itemNotifier = ref.read(itemProvider.notifier);
    _receiptItemNotifier = ref.read(receiptItemProvider.notifier);
    _staffNotifier = ref.read(staffProvider.notifier);
    _userNotifier = ref.read(userProvider.notifier);
    _modifierNotifier = ref.read(modifierProvider.notifier);
    _categoryNotifier = ref.read(categoryProvider.notifier);
    _discountNotifier = ref.read(discountProvider.notifier);
    _taxNotifier = ref.read(taxProvider.notifier);
    _saleItemNotifier = ref.read(saleItemProvider.notifier);
    _inventoryNotifier = ref.read(inventoryProvider.notifier);
    _outletNotifier = ref.read(outletProvider.notifier);
    _secondDisplayNotifier = ref.read(secondDisplayProvider.notifier);
    _deviceNotifier = ref.read(deviceProvider.notifier);
    // Reset navigation flag when entering payment screen
    PaymentDetails._isNavigatingAway = false;
    // Only do the absolute minimum in initState for smooth transition
    _initializeImmediately();
    // Defer everything else to after the page is fully rendered using queue approach
    _deferHeavyInitializationWithQueue();
  }

  /// Ensure slideshow cache is available for consistent data across all screens
  void _ensureSlideshowCacheAvailable() {
    // Use Future.microtask to avoid blocking initState
    Future.microtask(() async {
      if (!Home.isSlideshowCacheInitialized()) {
        prints(
          '🔄 Initializing slideshow cache from payment screen for consistency',
        );
        await Home.ensureSlideshowCacheInitialized();
      } else {
        prints('✅ Slideshow cache already available for payment screen');
      }
    });
  }

  /// Initialize immediately with cached data to prevent UI lag
  void _initializeImmediately() {
    // Only do the absolute minimum - just set basic state
    _isLoading = false; // Prevent loading spinner from showing

    // Ensure slideshow cache is initialized for consistent data across all screens
    _ensureSlideshowCacheAvailable();

    // Try to use cached data first for instant UI response
    try {
      // Check if cache was pre-warmed for even faster response
      if (PaymentDetails._cachedSecondDisplayData.containsKey('preWarmed')) {
        prints('🔥 Using pre-warmed cache for ultra-fast initialization');
      }

      if (PaymentDetails.isCacheInitialized()) {
        final cachedPaymentMethods = PaymentDetails.getCachedPaymentMethods();
        final cachedDefaultPayment =
            PaymentDetails.getCachedDefaultPaymentMethod();

        if (cachedPaymentMethods != null && cachedPaymentMethods.isNotEmpty) {
          // Use cached data without setState to avoid rebuild during transition
          paymentMethods = cachedPaymentMethods;
          if (cachedDefaultPayment != null) {
            paymentTypeModel = cachedDefaultPayment;
            paymentTypeName = cachedDefaultPayment.name;
            _selectedPaymentType = cachedPaymentMethods.indexOf(
              cachedDefaultPayment,
            );
          }
          _isInitialized = true;
          prints('⚡ Using cached payment methods for instant UI response');
          return;
        }
      }

      // Fallback to loading from notifier if cache is not available
      final outletPaymentTypeNotifier = ref.read(
        outletPaymentTypeProvider.notifier,
      );
      if (outletPaymentTypeNotifier.getOutletPaymentTypeList.isNotEmpty) {
        final newPaymentMethods =
            outletPaymentTypeNotifier.getPaymentTypeModelsForCurrentOutlet();
        if (newPaymentMethods.isNotEmpty) {
          // Set data without setState to avoid rebuild during transition
          paymentMethods = newPaymentMethods;
          _setDefaultPaymentMethodSilent(newPaymentMethods);
          _isInitialized = true;

          // Initialize cache for future use
          PaymentDetails.initializePaymentCache(
            paymentMethods,
            paymentTypeModel,
          );
        }
      }
    } catch (e) {
      // Silently continue - will be handled in deferred initialization
      prints('⚠️ Error in immediate initialization: $e');
    }
  }

  /// Defer heavy initialization using queue approach similar to menu_item.dart
  void _deferHeavyInitializationWithQueue() {
    // Use WidgetsBinding.instance.addPostFrameCallback to ensure UI is rendered first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add operations to queue instead of executing immediately
      _addInitializationToQueue(() => _initializeAsync());
      // Queue provider update
      _addInitializationToQueue(() => _updateProviderWithDefaultPayment());
      //  Queue second display update using non-blocking approach
      _addInitializationToQueue(
        () => _updateSecondDisplayWithPaymentChangeNonBlocking(),
      );
    });
  }

  /// Add initialization operation to queue for non-blocking execution
  void _addInitializationToQueue(Function operation) {
    // Don't add operations if we're navigating away
    if (PaymentDetails._isNavigatingAway) {
      prints('🚪 Skipped adding operation to queue due to navigation');
      return;
    }
    PaymentDetails._initializationQueue.add(operation);
    _processInitializationQueue();
  }

  /// Process initialization queue one operation at a time
  Future<void> _processInitializationQueue() async {
    if (PaymentDetails._isProcessingInitQueue ||
        PaymentDetails._initializationQueue.isEmpty ||
        PaymentDetails._isNavigatingAway) {
      return;
    }

    PaymentDetails._isProcessingInitQueue = true;

    while (PaymentDetails._initializationQueue.isNotEmpty &&
        mounted &&
        !PaymentDetails._isNavigatingAway) {
      final operation = PaymentDetails._initializationQueue.removeFirst();
      try {
        await operation();
      } catch (e) {
        prints('❌ Error in initialization queue operation: $e');
      }
      // Small delay between operations to allow UI to stay responsive
      await Future.delayed(const Duration(milliseconds: 50));

      // Check again if we're navigating away to exit early
      if (PaymentDetails._isNavigatingAway) {
        prints('🚪 Stopping queue processing due to navigation');
        break;
      }
    }

    PaymentDetails._isProcessingInitQueue = false;
  }

  /// Update provider with default payment method (queued operation)
  Future<void> _updateProviderWithDefaultPayment() async {
    if (!mounted ||
        paymentTypeModel == null ||
        PaymentDetails._isNavigatingAway) {
      return;
    }

    try {
      final saleItemsState = ref.read(saleItemProvider);
      final saleItemNotifier = ref.read(saleItemProvider.notifier);

      if (saleItemsState.isSplitPayment) {
        final splitNotifier = ref.read(splitPaymentProvider.notifier);
        splitNotifier.setPaymentTypeName(paymentTypeModel!);
        splitNotifier.calcTotalWithAdjustedPrice();
      } else {
        saleItemNotifier.setPaymentTypeModel(paymentTypeModel!);
        saleItemNotifier.calcTotalWithAdjustedPrice();
      }
      prints(
        '✅ Updated provider with default payment method: ${paymentTypeModel!.name}',
      );
    } catch (e) {
      prints('❌ Error updating provider with default payment method: $e');
    }
  }

  /// Load fresh data asynchronously without blocking UI
  void _initializeAsync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        bool hasChanges = false;

        // Load payment methods synchronously (no await needed)
        final newPaymentMethods = _loadPaymentMethodsSilent();
        if (newPaymentMethods != null &&
            !_arePaymentMethodsEqual(paymentMethods, newPaymentMethods)) {
          paymentMethods = newPaymentMethods;
          _setDefaultPaymentMethodSilent(newPaymentMethods);
          hasChanges = true;
        }

        // Update loading state
        if (!_isInitialized) {
          _isInitialized = true;
          hasChanges = true;
        }

        if (_isLoading) {
          _isLoading = false;
          hasChanges = true;
        }

        // Single setState call only if there are actual changes
        if (hasChanges && mounted) {
          setState(() {});
        }
      } catch (e) {
        prints('Error during async initialization: $e');
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  // Future<void> _loadShiftModel() async {
  //   try {
  //     shiftModel = await _shiftFacade.getLatestShift();
  //   } catch (e) {
  //     prints('Error loading shift model: $e');
  //   }
  // }

  /// Load payment methods silently without triggering setState
  /// Uses cached data from home screen initialization for instant loading
  List<PaymentTypeModel>? _loadPaymentMethodsSilent() {
    try {
      // First, try to use cached data from home screen initialization
      if (PaymentDetails.isCacheInitialized()) {
        final cachedMethods = PaymentDetails.getCachedPaymentMethods();
        if (cachedMethods != null && cachedMethods.isNotEmpty) {
          prints(
            '✅ Using cached payment methods from home screen initialization',
          );
          return cachedMethods;
        }
      }

      // Fallback to notifier if cache is not available
      prints('⚠️ Cache not available, loading payment methods from notifier');
      final outletPaymentTypeNotifier = ref.read(
        outletPaymentTypeProvider.notifier,
      );
      final methods =
          outletPaymentTypeNotifier.getPaymentTypeModelsForCurrentOutlet();

      // Update cache with fresh data for next time
      if (methods.isNotEmpty) {
        PaymentTypeModel? defaultMethod;
        try {
          defaultMethod = methods.firstWhere(
            (payment) => payment.name?.toLowerCase() == 'cash',
          );
        } catch (e) {
          defaultMethod = methods.first;
        }
        PaymentDetails.updatePaymentCache(methods, defaultMethod);
      } else {
        // List<PaymentTypeModel> listPT =
        //     _paymentTypeFacade.getListPaymentTypeFromHive();

        // if (listPT.isNotEmpty) {
        //   PaymentTypeModel? defaultMethod;
        //   try {
        //     defaultMethod = listPT.firstWhere(
        //       (payment) => payment.name?.toLowerCase() == 'cash',
        //     );
        //   } catch (e) {
        //     defaultMethod = listPT.first;
        //   }
        //   PaymentDetails.updatePaymentCache(listPT, defaultMethod);
        // }
      }

      return methods;
    } catch (e) {
      prints('Error loading payment methods: $e');
      return null;
    }
  }

  /// Legacy method - now calls silent version and triggers setState
  void _loadPaymentMethods() {
    try {
      final newPaymentMethods = _loadPaymentMethodsSilent();
      if (newPaymentMethods != null &&
          !_arePaymentMethodsEqual(paymentMethods, newPaymentMethods)) {
        paymentMethods = newPaymentMethods;
        setDefaultPaymentMethod(paymentMethods);
      }
    } catch (e) {
      prints('Error loading payment methods: $e');
    }
  }

  /// Compare payment methods to avoid unnecessary updates
  bool _arePaymentMethodsEqual(
    List<PaymentTypeModel> list1,
    List<PaymentTypeModel> list2,
  ) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  /// Legacy method for backward compatibility - now optimized
  // Future<void> getShiftModel() async {
  //   await _loadShiftModel();
  //   if (mounted) setState(() {});
  // }

  /// Legacy method for backward compatibility - now optimized
  void getPaymentMethods() {
    final oldPaymentMethods = List<PaymentTypeModel>.from(paymentMethods);
    _loadPaymentMethods();

    // Only call setState if data actually changed
    if (mounted &&
        !_arePaymentMethodsEqual(oldPaymentMethods, paymentMethods)) {
      setState(() {});
    }
  }

  /// Cache calculation to avoid repeated computation in build method
  double _calculateTotalAmountRemaining(
    SaleItemState saleItemsState,
    SplitPaymentState splitPaymentState,
  ) {
    final double rawAmount =
        saleItemsState.isSplitPayment
            ? splitPaymentState.totalAmountRemaining
            : saleItemsState.totalAmountRemaining;

    return double.parse(rawAmount.toStringAsFixed(2));
  }

  /// Update UI immediately for better button responsiveness
  void _setSelectedImmediate(int newSelected) {
    setState(() {
      _selectedPaymentType = newSelected;
      paymentTypeName = paymentMethods[newSelected].name;
      paymentTypeModel = paymentMethods[newSelected];
    });
  }

  /// Handle async operations without blocking UI
  void _setSelectedAsync(
    int newSelected,
    SaleItemNotifier saleItemNotifier,
    SaleItemState saleItemsState,
  ) {
    // Run async operations in the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        if (saleItemsState.isSplitPayment) {
          final splitNotifier = ref.read(splitPaymentProvider.notifier);
          splitNotifier.setPaymentTypeName(paymentMethods[newSelected]);
          splitNotifier.calcTotalWithAdjustedPrice();
        } else {
          saleItemNotifier.setPaymentTypeModel(paymentMethods[newSelected]);
          saleItemNotifier.calcTotalWithAdjustedPrice();
        }

        // Transfer totalAmountRemaining to second display with debouncing
        final splitPaymentState = ref.read(splitPaymentProvider);
        await _updateSecondDisplayWithPaymentChange(
          saleItemsState,
          splitPaymentState,
          paymentMethods[newSelected],
        );
      } catch (e) {
        prints('Error in async payment selection: $e');
      }
    });
  }

  /// Set default payment method silently without triggering provider updates
  /// Uses cached default payment method from home screen initialization for instant loading
  void _setDefaultPaymentMethodSilent(List<PaymentTypeModel> paymentMethods) {
    if (paymentMethods.isEmpty) {
      return;
    }

    PaymentTypeModel? defaultMethod;

    // First, try to use cached default payment method from home screen initialization
    if (PaymentDetails.isCacheInitialized()) {
      defaultMethod = PaymentDetails.getCachedDefaultPaymentMethod();
      if (defaultMethod != null) {
        prints(
          '✅ Using cached default payment method from home screen initialization',
        );
      }
    }

    // Fallback to finding cash method if cache is not available
    if (defaultMethod == null) {
      prints('⚠️ Cache not available, finding default payment method');
      defaultMethod = paymentMethods.firstWhere(
        (method) => method.name!.toLowerCase() == 'cash',
        orElse: () => paymentMethods[0],
      );
    }

    // Only update if different from current selection
    final newSelectedIndex = paymentMethods.indexOf(defaultMethod);
    if (_selectedPaymentType == newSelectedIndex &&
        paymentTypeModel?.id == defaultMethod.id) {
      return; // No change needed
    }

    // Set default payment method (UI state only)
    if (defaultMethod.id != null) {
      paymentTypeName = defaultMethod.name;
      paymentTypeModel = defaultMethod;
      _selectedPaymentType = newSelectedIndex;
    }
  }

  /// Public method that updates providers - used for external calls
  void setDefaultPaymentMethod(List<PaymentTypeModel> paymentMethods) {
    _setDefaultPaymentMethodSilent(paymentMethods);

    // Update providers after UI state is set
    if (paymentMethods.isNotEmpty && paymentTypeModel != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        try {
          final saleItemsState = ref.read(saleItemProvider);
          final saleItemNotifier = ref.read(saleItemProvider.notifier);

          if (saleItemsState.isSplitPayment) {
            final splitNotifier = ref.read(splitPaymentProvider.notifier);
            splitNotifier.setPaymentTypeName(paymentTypeModel!);
            splitNotifier.calcTotalWithAdjustedPrice();
          } else {
            saleItemNotifier.setPaymentTypeModel(paymentTypeModel!);
            saleItemNotifier.calcTotalWithAdjustedPrice();
          }
        } catch (e) {
          prints('Error setting default payment method: $e');
        }
      });
    }
  }

  //   {
  //     "name": "Cash",
  //     "icon": Icons.money,
  //     "iconColor": Colors.green,
  //   },
  //   {
  //     "name": "Card",
  //     "icon": Icons.credit_card,
  //     "iconColor": null, // Default color
  //   },
  //   {
  //     "name": "E-Wallet",
  //     "icon": FontAwesomeIcons.wallet,
  //     "iconColor": Colors.orange,
  //   },
  //   {
  //     "name": "Cash",
  //     "icon": Icons.money,
  //     "iconColor": Colors.green,
  //   },
  //   {
  //     "name": "Card",
  //     "icon": Icons.credit_card,
  //     "iconColor": null, // Default color
  //   },
  //   {
  //     "name": "E-Wallet",
  //     "icon": FontAwesomeIcons.wallet,
  //     "iconColor": Colors.orange,
  //   },
  // ];

  @override
  Widget build(BuildContext context) {
    // Show loading state if not initialized
    if (_isLoading && !_isInitialized) {
      return const Expanded(
        flex: 5,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final permissionNotifier = ref.read(permissionProvider.notifier);
    final hasPermission = permissionNotifier.hasAcceptPaymentPermission();
    final splitPaymentState = ref.watch(splitPaymentProvider);

    final saleItemNotifier = ref.read(saleItemProvider.notifier);
    final saleItemsState = ref.watch(saleItemProvider);

    // Cache calculations to avoid repeated computation
    final double totalAmountRemaining = _calculateTotalAmountRemaining(
      saleItemsState,
      splitPaymentState,
    );

    final double totalAmountPaid =
        saleItemsState.isSplitPayment
            ? splitPaymentState.totalAmountPaid
            : saleItemsState.totalAmountPaid;
    return Expanded(
      flex: 5,
      child: Column(
        children: [
          const Space(20),
          paymentTypeName == null ||
                  paymentTypeName!.toLowerCase().contains('cash')
              ? Column(
                children: [
                  Text(
                    'totalAmountRemaining'.tr(),
                    style: AppTheme.normalTextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    FormatUtils.formatNumber(
                      'RM'.tr(
                        args: [(totalAmountRemaining.toStringAsFixed(2))],
                      ),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // const Text(
                  //   'fkjghdfjkgh',
                  //   textAlign: TextAlign.center,
                  //   style: TextStyle(
                  //       fontSize: 40, fontWeight: FontWeight.bold),
                  // ),
                  const Divider(),
                ],
              )
              : const SizedBox.shrink(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 60, // Adjust height as needed
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: paymentMethods.length,
                itemBuilder: (context, index) {
                  final method = paymentMethods[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor:
                            _selectedPaymentType == index
                                ? kPrimaryBgColor
                                : null,
                        minimumSize: const Size(160, 0),
                        side: BorderSide(
                          color:
                              _selectedPaymentType == index
                                  ? kPrimaryColor
                                  : kLightGray,
                        ),
                      ),
                      onPressed: () {
                        // Update UI immediately for better responsiveness
                        _setSelectedImmediate(index);
                        // Handle async operations without blocking UI
                        _setSelectedAsync(
                          index,
                          saleItemNotifier,
                          saleItemsState,
                        );
                      },
                      icon: Icon(getIcon(method), color: getIconColor(method)),
                      label: Text(
                        method.name!,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          paymentTypeName == null ||
                  paymentTypeName!.toLowerCase().contains('cash')
              ? Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 30,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      'cashReceived'.tr(),
                      style: const TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 50),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: kLightGray),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'RM'.tr(args: ['']),
                              style: const TextStyle(fontSize: 20),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              height: 40,
                              width: 2,
                              color: kLightGray,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _inputController,
                                readOnly: true,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: const BorderSide(
                                      color: Colors.transparent,
                                    ),
                                    gapPadding: 10,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.transparent,
                                    ),
                                    gapPadding: 10,
                                  ),
                                  contentPadding: const EdgeInsets.fromLTRB(
                                    15,
                                    10,
                                    15,
                                    10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : const Space(40),
          paymentTypeName == null ||
                  paymentTypeName!.toLowerCase().contains('cash')
              ? Expanded(child: Numpad(controller: _inputController))
              : Expanded(
                child:
                    !isNewSale
                        ?
                        //   before press charge
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'totalAmountRemaining'.tr(),
                              style: AppTheme.normalTextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              FormatUtils.formatNumber(
                                'RM'.tr(
                                  args: [
                                    (totalAmountRemaining.toStringAsFixed(2)),
                                  ],
                                ),
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                        :
                        // after press charge
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              FontAwesomeIcons.circleCheck,
                              size: 75,
                              color: kPrimaryBgColor,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              FormatUtils.formatNumber(
                                'RM'.tr(
                                  args: [(totalAmountPaid.toStringAsFixed(2))],
                                ),
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'totalPaid'.tr(),
                              style: AppTheme.normalTextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
              ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(width: isPrinted ? 10 : 0),
              // reprint button
              isPrinted ? reprintButton(context) : const SizedBox.shrink(),

              SizedBox(width: isPrinted ? 10 : 0),
              isPrinted ? sendEmailButton(context) : const SizedBox.shrink(),
              // share button
              const Expanded(flex: 2, child: SizedBox()),
              hasPermission
                  ? Expanded(
                    flex: isPrinted ? 8 : 6,
                    child: buildChargeButton(
                      saleItemsState,
                      splitPaymentState,
                      context,
                      totalAmountRemaining,
                      saleItemNotifier,
                    ),
                  )
                  : const SizedBox.shrink(),
              // const Expanded(flex: 2, child: SizedBox()),
              // Container(
              //   padding: const EdgeInsets.all(10.0),
              //   decoration: const BoxDecoration(
              //     shape: BoxShape.circle,
              //     color: Colors.transparent,
              //   ),
              //   child: const Center(
              //     child: Icon(
              //       FontAwesomeIcons.prints,
              //       color: Colors.transparent,
              //       size: 30,
              //     ),
              //   ),
              // ),
              const SizedBox(width: 10),
            ],
          ),
          Space(10.h),
        ],
      ),
    );
  }

  ButtonPrimary buildChargeButton(
    SaleItemState saleItemsState,
    SplitPaymentState splitPaymentState,
    BuildContext context,
    double totalAmountRemaining,
    SaleItemNotifier saleItemNotifier,
  ) {
    return ButtonPrimary(
      onPressed: () async {
        // check sale item first
        if (!isNewSale) {
          List<SaleItemModel> selectedSaleItems =
              saleItemsState.isSplitPayment
                  ? splitPaymentState.saleItems
                  : saleItemsState.saleItems;

          if (selectedSaleItems.isEmpty) {
            ThemeSnackBar.showSnackBar(context, 'noItemsFound'.tr());
            return;
          }
          // check payment type first
          if (_selectedPaymentType == -1) {
            ThemeSnackBar.showSnackBar(context, 'pleaseSelectPaymentType'.tr());
            return;
          }

          if (paymentTypeName!.toLowerCase().contains('cash')) {
            if (_inputController.text != '') {
              final charge = double.parse(_inputController.text);
              if (charge < totalAmountRemaining) {
                ThemeSnackBar.showSnackBar(
                  context,
                  'cashReceivedIsNotEnough'.tr(),
                );
              } else {
                await onPressCharge(
                  splitPaymentState,
                  saleItemsState,
                  saleItemNotifier,
                  charge,
                  totalAmountRemaining,
                );

                // showDialog(
                //     context: context,
                //     barrierDismissible: false,
                //     builder: (context) {
                //       return BalancePaymentDialogue(change: change);
                //     });
              }
            } else {
              ThemeSnackBar.showSnackBar(
                context,
                'cashReceivedIsNotEnough'.tr(),
              );
            }
          } else {
            // online payment (other than cash)
            await onPressCharge(
              splitPaymentState,
              saleItemsState,
              saleItemNotifier,
              totalAmountRemaining,
              totalAmountRemaining,
            );
          }
        } else {
          prints('back  to newsale');

          // Set navigation flag to prevent any new operations
          PaymentDetails.setNavigatingAway(true);

          // Cancel any pending second display updates immediately
          PaymentDetails.cancelPendingSecondDisplayUpdates();

          // Prepare menu items for optimized transition
          MenuItem.prepareForPaymentTransition();

          // Schedule post-dispose secondary display update BEFORE popping
          _schedulePostDisposeSecondaryDisplayUpdate();

          // Perform ALL state cleanup synchronously but efficiently
          saleItemNotifier.setPredefinedOrderModel(PredefinedOrderModel());
          saleItemNotifier.setIsSplitPayment(false);
          saleItemNotifier.setSelectedTable(TableModel());
          saleItemNotifier.setCurrSaleModel(SaleModel());
          saleItemNotifier.setPredefinedOrderModel(PredefinedOrderModel());
          ref.read(paymentProvider.notifier).setChangeToPaymentScreen(false);

          // Pop navigation IMMEDIATELY with zero delay
          NavigationUtils.pop(context);

          // Only secondary display update will be handled post-dispose
        }
      },
      text: buttonChargeText,
      icon:
          !isNewSale
              ? FontAwesomeIcons.moneyBill1
              : FontAwesomeIcons.checkToSlot,
      size: const Size.fromWidth(500),
    );
  }

  InkWell reprintButton(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (mounted) {
          // dah handle, only printer that printReceiptBills only
          await _receiptNotifier.printLatestReceipt(
            mounted,
            context,
            ref: ref,
            onSuccess: () {},
            onError: (errorIps) {
              if (errorIps == '-1') {
                // printerNotAvailableDialogue(
                //   context,
                //   'noPrinterAvailable'.tr(),
                //   'pleaseAddPrinterToPrint'.tr(),
                // );
                return;
              }
              DialogUtils.printerErrorDialogue(
                context,
                'connectionTimeout'.tr(),
                errorIps,
                null,
              );
              return;
            },
          );
        }
      },
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: const BoxDecoration(
          // shape: BoxShape.circle,
          borderRadius: BorderRadius.all(Radius.circular(5)),
          color: canvasColor,
        ),
        child: Center(
          child: Icon(FontAwesomeIcons.print, color: kWhiteColor, size: 30),
        ),
      ),
    );
  }

  InkWell sendEmailButton(BuildContext context) {
    return InkWell(
      onTap: () async {
        await showDialogueSendEmail(context);
      },
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: const BoxDecoration(
          // shape: BoxShape.circle,
          borderRadius: BorderRadius.all(Radius.circular(5)),
          color: kSuccessColor,
        ),
        child: const Center(
          child: Icon(FontAwesomeIcons.envelope, color: kWhiteColor, size: 30),
        ),
      ),
    );
  }

  Color getIconColor(PaymentTypeModel method) {
    if (method.name!.toLowerCase().contains('cash')) {
      return Colors.green;
    } else if (method.paymentTypeCategory == PaymentTypeEnum.card) {
      return Colors.red;
    } else if (method.paymentTypeCategory == PaymentTypeEnum.cheque) {
      return Colors.blue;
    } else {
      return Colors.black;
    }
  }

  IconData getIcon(PaymentTypeModel method) {
    if (method.name!.toLowerCase().contains('cash')) {
      return Icons.money;
    } else if (method.paymentTypeCategory == PaymentTypeEnum.card) {
      // card enum
      return Icons.credit_card;
    } else if (method.paymentTypeCategory == PaymentTypeEnum.cheque) {
      // check  enum
      return FontAwesomeIcons.wallet;
    } else {
      return Icons.money;
    }
  }

  Future<void> onPressCharge(
    SplitPaymentState splitPaymentState,
    SaleItemState saleItemsState,
    SaleItemNotifier saleItemNotifier,
    double charge,
    double payableAmount,
  ) async {
    PosDeviceModel? deviceModel = await _deviceNotifier.getLatestDeviceModel();
    final permissionNotifier = ref.read(permissionProvider.notifier);
    final customerNotifier = ref.read(customerProvider.notifier);
    String showUUID = await IdUtils.generateReceiptId();
    String newReceiptId = IdUtils.generateUUID();
    StaffModel staffModel = ServiceLocator.get<StaffModel>();
    List<SaleItemModel> newListSaleItemsWithoutSaleId =
        []; // use for direct charge only

    // check permission accept payment
    if (!permissionNotifier.hasAcceptPaymentPermission()) {
      ThemeSnackBar.showSnackBar(
        context,
        'youDontHavePermissionForThisAction'.tr(),
      );
      return;
    }
    // to get who is the one is charge the order
    // basically the current user in this POS
    UserModel? userCharge = await _userNotifier.getUserModelByIdUser(
      staffModel.userId!,
    );
    bool isSplit = saleItemsState.isSplitPayment;
    // double totalTaxAfterDiscount = saleItemNotifier.getTaxAfterDiscount;
    CustomerModel? orderCustomerModel = customerNotifier.getOrderCustomerModel;

    TableModel? tableModel = saleItemsState.selectedTable;
    PredefinedOrderModel? poNoti = saleItemsState.pom;
    PredefinedOrderModel? predefinedOrderModel;
    if (tableModel?.id != null && tableModel?.predefinedOrderId != null) {
      //get predefined order from model
      predefinedOrderModel = await _predefinedOrderNotifier
          .getPredefinedOrderById(tableModel!.predefinedOrderId!);
    }

    bool useRounding = paymentTypeModel?.autoRounding ?? false;
    SaleModel? currentSaleModel = saleItemsState.currSaleModel;
    // to get who is the one that take order this menu
    UserModel? userOrder = await _staffNotifier.getUserModelByStaffId(
      currentSaleModel!.staffId ?? staffModel.id!,
    );

    shiftModel = await _shiftNotifier.getLatestShift();
    // create receipt model
    ReceiptModel newReceiptModel = ReceiptModel(
      id: newReceiptId,
      showUUID: showUUID,
      staffId: staffModel.id,
      staffName: userCharge!.name,
      orderedByStaffId: currentSaleModel.staffId ?? staffModel.id!,
      orderedByStaffName: userOrder!.name,
      shiftId:
          shiftModel.id ??
          await _staffNotifier.getCurrentShiftFromStaffId(
            currentSaleModel.staffId ?? staffModel.id!,
          ),
      tableName: saleItemsState.selectedTable!.name,
      outletId: outletModel.id,
      posDeviceId: deviceModel!.id,
      posDeviceName: deviceModel.name,
      customerId: orderCustomerModel?.id,
      customerName: orderCustomerModel?.name,
      cash: charge,
      adjustedPrice:
          isSplit
              ? splitPaymentState.adjustedPrice
              : saleItemsState.adjustedPrice,
      orderOption: saleItemsState.orderOptionModel!.name,
      openOrderName: poNoti!.name ?? predefinedOrderModel?.name,
      receiptStatus: ReceiptStatusEnum.normal,
      totalDiscount:
          isSplit
              ? double.parse(splitPaymentState.totalDiscount.toStringAsFixed(2))
              : double.parse(saleItemsState.totalDiscount.toStringAsFixed(2)),
      totalTaxes:
          isSplit
              ? splitPaymentState.taxAfterDiscount
              : saleItemsState.taxAfterDiscount,
      totalIncludedTaxes:
          isSplit
              ? splitPaymentState.taxIncludedAfterDiscount
              : saleItemsState.taxIncludedAfterDiscount,
      taxPercentage: getTaxPercentage(saleItemsState, splitPaymentState),
      cost:
          isSplit
              ? double.parse(
                ref
                    .read(splitPaymentProvider.notifier)
                    .getTotalCosts()
                    .toStringAsFixed(2),
              )
              : double.parse(
                saleItemNotifier.getTotalCosts().toStringAsFixed(2),
              ),
      paymentType: paymentTypeName,
      payableAmount: double.parse(payableAmount.toStringAsFixed(2)),
      grossSale:
          isSplit
              ? ref.read(splitPaymentProvider.notifier).getGrossSales()
              : saleItemNotifier.getGrossSales(),
      netSale:
          isSplit
              ? double.parse(
                ref
                    .read(splitPaymentProvider.notifier)
                    .getNetSales()
                    .toStringAsFixed(2),
              )
              : double.parse(saleItemNotifier.getNetSales().toStringAsFixed(2)),
      totalCollected: charge,
      grossProfit:
          isSplit
              ? double.parse(
                (ref.read(splitPaymentProvider.notifier).getNetSales() -
                        ref.read(splitPaymentProvider.notifier).getTotalCosts())
                    .toStringAsFixed(2),
              )
              : double.parse(
                (saleItemNotifier.getNetSales() -
                        saleItemNotifier.getTotalCosts())
                    .toStringAsFixed(2),
              ),
      totalCashRounding:
          useRounding
              ? double.parse(
                _shiftNotifier
                    .calcChangeCashRounding(
                      isSplit
                          ? ref
                              .read(splitPaymentProvider.notifier)
                              .getNetSales()
                          : saleItemNotifier.getNetSales(),
                    )
                    .toStringAsFixed(2),
              )
              : 0.00,
    );
    // insert receipt model
    await _receiptNotifier.upsertBulk([newReceiptModel]);
    // create receipt item based on the sale item

    CategoryModel? categoryModel;

    List<SaleItemModel> listSaleItems =
        isSplit ? splitPaymentState.saleItems : saleItemsState.saleItems;
    String? newSaleId = IdUtils.generateUUID();

    // extract list sale items that doesnt have sale id
    newListSaleItemsWithoutSaleId = List<SaleItemModel>.from(
      listSaleItems.where((element) => element.saleId == null).toList(),
    );

    // generate receipt item
    await Future.wait(
      listSaleItems.map(
        (e) => insertOneReceiptItem(
          newSaleId,
          e,
          categoryModel,
          newReceiptId,
          saleItemNotifier,
          saleItemsState,
          splitPaymentState,
        ),
      ),
    );

    // clear the customer
    if (orderCustomerModel != null) {
      customerNotifier.setOrderCustomerModel(null);
    }

    _inputController.clear();
    setDefaultPaymentMethod(paymentMethods);

    /// [UPDATE EXPECTED CASH SHIFT MODEL]
    await _shiftNotifier.updateExpectedCash();

    double change = charge - payableAmount;
    if (change > 0.00) {
      if (mounted) {
        CustomDialog.show(
          context,
          icon: Icons.money_off_rounded,
          title:
              "${'change'.tr()} : ${'RM'.tr(args: [change.toStringAsFixed(2)])}",
          btnOkText: 'ok'.tr(),
          btnOkOnPress: () {
            NavigationUtils.pop(context);
          },
        );
      }
    }

    // context.read<ReceiptItemNotifier>().addBulkReceiptItems(listReceiptItems);

    // cari sale model untuk dapatkakn  predefined_order_id
    // refresh state because can split
    final saleItemsState1 = ref.watch(saleItemProvider);
    SaleModel? currSaleModel = saleItemsState1.currSaleModel;
    //prints(jsonEncode(currSaleModel));
    String? predefinedOrderId = currSaleModel!.predefinedOrderId;
    if (currSaleModel.id != null) {
      // cari sales.id to update the charged at to not null
      // because when  to open order, it will find from sale where charged at is null
      predefinedOrderModel = await _predefinedOrderNotifier
          .getPredefinedOrderById(predefinedOrderId);
      ReceiptModel updateReceiptModel = newReceiptModel.copyWith(
        runningNumber: currSaleModel.runningNumber.toString(),
        remarks: predefinedOrderModel!.remarks,
      );
      await _receiptNotifier.upsertBulk([updateReceiptModel]);

      /// [before clear the sale item]
      /// [create new sale model]
      /// [assign new saleId into current sale item]
      ///
      // create mew sale model
      // udpate running number
      // int latestRunningNumber = 1;
      // await _outletFacade.incrementNextOrderNumber(
      //   onRunningNumber: (int runningNumber) {
      //     latestRunningNumber = runningNumber;
      //   },
      // );
      // int latestRunningNumber = await _saleFacade.getLatestRunningNumber();
      // latestRunningNumber = latestRunningNumber == 0 ? 1 : latestRunningNumber;

      List<SaleItemModel> saleItemsWithSaleId = List<SaleItemModel>.from(
        listSaleItems.where((element) => element.saleId != null).toList(),
      );
      await _saleNotifier.createNewSaleAndInsert(
        currSaleModel.id!,
        saleItemsState1.orderOptionModel!.id,
        currSaleModel.runningNumber ?? 1,
        predefinedOrderModel,
        newReceiptModel,
        listSaleItems.length,
      );
      // assign new sale id into current sale item

      final now = DateTime.now();
      await Future.wait([
        ...saleItemsWithSaleId.map((saleItem) {
          SaleItemModel updateSaleItem = saleItem.copyWith(
            saleId: currSaleModel.id!,
            updatedAt: now,
          );
          return _saleItemNotifier.update(updateSaleItem);
        }),
        ...newListSaleItemsWithoutSaleId.map((saleItem) {
          SaleItemModel newSaleItem = saleItem.copyWith(
            saleId: currSaleModel.id!,
            updatedAt: now,
          );
          return _saleItemNotifier.insert(newSaleItem);
        }),
      ]);

      if (isSplit) {
        prints('MASUK SINIII');
        final splitNotifier = ref.read(splitPaymentProvider.notifier);
        splitNotifier.clearSelectedSaleItems();
        splitNotifier.calcTotalAfterDiscountAndTax();
        splitNotifier.calcTaxAfterDiscount();
        splitNotifier.calcTotalDiscount();
        splitNotifier.calcTotalWithAdjustedPrice();
        splitNotifier.calcTaxIncludedAfterDiscount();
      } else {
        prints('TAK LAHH MASUK SINIIIIIIIII');
        saleItemNotifier.clearOrderItems();
        saleItemNotifier.calcTotalAfterDiscountAndTax();
        saleItemNotifier.calcTaxAfterDiscount();
        saleItemNotifier.calcTotalDiscount();
        saleItemNotifier.calcTotalWithAdjustedPrice();
        saleItemNotifier.calcTaxIncludedAfterDiscount();
      }

      //refresh sale item state
      final newSaleItemsState = ref.read(saleItemProvider);
      if (newSaleItemsState.saleItems.isEmpty) {
        await _saleNotifier.updateChargedAt(currSaleModel.id!);
        // insert running number to current receipt
        // update the predefined order
        if (predefinedOrderModel.isOccupied!) {
          if (predefinedOrderModel.isCustom!) {
            await _predefinedOrderNotifier.delete(predefinedOrderModel.id!);
          } else {
            // guna predefined_order_id to unOccupied
            prints('JADIKAN 0000000');
            await _predefinedOrderNotifier.unOccupied(predefinedOrderModel.id!);
          }
        } else {
          prints('ERROR: THIS PREDEFINED ORDER IS NOT OCCUPIED');
        }
      } else {
        prints('sale item belum habis');
      }

      /// ```
      /// ========================= FEATURE BARU BOLEH HUTANG BILA SPLIT PAYMENT======================

      // if (predefinedOrderModel != null) {
      //   await _predefinedOrderFacade.unOccupied(predefinedOrderModel.id!);
      // }

      // // remove predefinedOrderId, name, table_id, table_name from sale model
      // SaleModel updateSaleModel = currSaleModel.copyWith(
      //   predefinedOrderId: "",
      //   name: "",
      //   tableId: "",
      //   tableName: "",
      // );

      // String message = await _saleFacade.update(updateSaleModel);
      // prints("MESSAGE UPDATE SALE MODEL $message");
      ///```
      /// ===========================================================================================
    } else {
      // the sale is direct charged, doesnt have predefined_order_id
      // so we create new sale model
      prints('DIRECT CHARGE CHARGECHARGECHARGECHARGECHARGECHARGE');
      // update latest running number
      int latestRunningNumber = 1;
      await _outletNotifier.incrementNextOrderNumber(
        onRunningNumber: (runningNumber) {
          latestRunningNumber = runningNumber;
        },
      );

      ReceiptModel updateReceiptModel = newReceiptModel.copyWith(
        runningNumber: latestRunningNumber.toString(),
      );

      await _receiptNotifier.upsertBulk([updateReceiptModel]);

      await _saleNotifier.createNewSaleAndInsert(
        newSaleId,
        saleItemsState.orderOptionModel?.id,
        latestRunningNumber,
        predefinedOrderModel,
        newReceiptModel,
        listSaleItems.length,
      );

      // insert sale items
      //save sale item
      await Future.wait(
        listSaleItems.map((saleItem) {
          SaleItemModel newSaleItem = saleItem.copyWith(saleId: newSaleId);
          return _saleItemNotifier.insert(newSaleItem);
        }),
      );
    }

    if (tableModel?.id != null && tableModel?.predefinedOrderId != null) {
      final saleItemsState2 = ref.read(saleItemProvider);
      if (saleItemsState2.saleItems.isEmpty) {
        final container = ServiceLocator.get<ProviderContainer>();
        await container
            .read(tableLayoutProvider.notifier)
            .resetTableById(
              tableModel!.id!,
              clearOpenOrder: predefinedOrderModel?.isCustom ?? false,
            );
        // dah buat masa tekan new sale button
        // // reset selected table
        // saleItemNotifier.setSelectedTable(TableModel());
        // // reset current sale model
        // saleItemNotifier.setCurrSaleModel(SaleModel());
        // // reset predefined order model
        // saleItemNotifier.setPredefinedOrderModel(PredefinedOrderModel());
      }
    }

    // clear item in sale item notifier
    if (isSplit) {
      prints('MASUK SINIII');
      final splitNotifier = ref.read(splitPaymentProvider.notifier);
      splitNotifier.clearSelectedSaleItems();
      splitNotifier.calcTotalAfterDiscountAndTax();
      splitNotifier.calcTaxAfterDiscount();
      splitNotifier.calcTaxIncludedAfterDiscount();
      splitNotifier.calcTotalDiscount();
      splitNotifier.calcTotalWithAdjustedPrice();
    } else {
      prints('TAK LAHH MASUK SINIIIIIIIII');
      saleItemNotifier.clearOrderItems();
      saleItemNotifier.calcTotalAfterDiscountAndTax();
      saleItemNotifier.calcTaxAfterDiscount();
      saleItemNotifier.calcTotalDiscount();
      saleItemNotifier.calcTotalWithAdjustedPrice();
      saleItemNotifier.calcTaxIncludedAfterDiscount();
    }
    final newSaleItemsState = ref.read(saleItemProvider);
    if (currSaleModel.id != null) {}

    if (isSplit) {
      ref.read(splitPaymentProvider.notifier).setAdjustedPrice(0);
    } else {
      saleItemNotifier.setAdjustedPrice(0);
    }

    if (newSaleItemsState.saleItems.isEmpty) {
      isNewSale = true;
      buttonChargeText = 'newSale'.tr();

      saleItemNotifier.setCanBackToSalesPage(false);
    } else {
      saleItemNotifier.setCanBackToSalesPage(true);
    }

    // saleItemNotifier.setPaymentTypeModel(PaymentTypeModel());
    // splitPaymentNotifier.setPaymentTypeName(null);
    getPaymentMethods();

    // setState(() {});

    /// [PRINT SALES RECEIPT]
    if (!isContextActive) return;

    await printSalesReceipt(
      newReceiptId,
      onError: (ipAd) {
        // prints('onnerror');
        if (mounted) {
          DialogUtils.printerErrorDialogue(
            context,
            'connectionTimeout'.tr(),
            ipAd,
            null,
          );
          isPrinted = true;
          setState(() {});
        } else {
          prints('NOTTTTTT MOUNTED');
          DialogUtils.printerErrorDialogue(
            widget.orderListContext,
            'connectionTimeout'.tr(),
            ipAd,
            null,
          );
          isPrinted = true;
        }
      },
      onSuccess: () {
        isPrinted = true;
        if (mounted) {
          setState(() {});
        }
      },
    );

    // set isSplit to false only when saleItem.getSaleItems is not empty
    // because total amount paid will be read based on state isSplitPayment
    if (ref.read(splitPaymentProvider).saleItems.isEmpty) {
      saleItemNotifier.setIsSplitPayment(false);
    }

    /// [RECALCULATE TOTAL]
    saleItemNotifier.calcTotalAfterDiscountAndTax();
    saleItemNotifier.calcTaxAfterDiscount();
    saleItemNotifier.calcTaxIncludedAfterDiscount();
    saleItemNotifier.calcTotalDiscount();

    saleItemNotifier.calcTotalWithAdjustedPrice();

    /// [TRANSFER DATA TO SECOND DISPLAY]
    /// [DATA TO TRANSFER TO SECOND DISPLAY]

    List<SaleItemModel> listSI = newSaleItemsState.saleItems;
    UserModel userModel = GetIt.instance<UserModel>();

    // Use cached slideshow model from home_screen.dart to avoid DB calls and ensure consistency
    SlideshowModel? currSdModel = Home.getCachedSlideshowModel();

    // If cache is not available, fallback to DB call (should be rare)
    if (currSdModel == null) {
      prints(
        '⚠️ Slideshow cache not available during payment processing, falling back to DB call',
      );
      final Map<String, dynamic> slideshowMap =
          await _slideshowNotifier.getLatestModel();
      currSdModel = slideshowMap[DbResponseEnum.data];
    } else {
      prints(
        '✅ Using cached slideshow model during payment processing for consistency',
      );
    }

    Map<String, dynamic> dataReceipt = saleItemNotifier.getMapDataToTransfer();
    dataReceipt.addEntries([
      MapEntry(DataEnum.userModel, userModel.toJson()),
      MapEntry(DataEnum.slideshow, currSdModel?.toJson() ?? {}),
      const MapEntry(DataEnum.showThankYou, false),
      const MapEntry(DataEnum.isCharged, true),
    ]);

    //      _showSecondaryDisplayFacade.getDataToTransfer(
    //   context,
    //   sin: sin,
    //   isShowThankYou: false,
    //   totalPaid: null,
    //   change: null,
    // );

    Map<String, dynamic> dataThankYou = saleItemNotifier.getMapDataToTransfer();
    dataThankYou.addEntries([
      MapEntry(DataEnum.userModel, userModel.toJson()),
      MapEntry(DataEnum.slideshow, currSdModel?.toJson() ?? {}),
      const MapEntry(DataEnum.showThankYou, true),
      MapEntry(DataEnum.totalPaid, payableAmount),
      MapEntry(DataEnum.change, change),
    ]);

    /// [SHOW SECOND SCREEN: CUSTOMER SHOW RECEIPT SCREEN]
    await ref
        .read(secondDisplayProvider.notifier)
        .navigateSecondScreen(
          CustomerShowReceipt.routeName,
          data: listSI.isNotEmpty ? dataReceipt : dataThankYou,
        );

    prints("dataReceipt");

    // only use the sale item that doesn't have sale id because
    // when does not have sale id, it means it is a new sale and didnt update for inventory
    await _inventoryNotifier.updateInventoryInSaleItem(
      newListSaleItemsWithoutSaleId,
      InventoryTransactionTypeEnum.stockOut,
    );
    // prints(dataReceipt);
  }

  Future<void> printSalesReceipt(
    String newReceiptId, {
    required Function() onSuccess,
    required Function(String message) onError,
  }) async {
    try {
      prints('=== PAYMENT SALES RECEIPT PRINT START ===');
      List<PrinterSettingModel> listPsm =
          await _printerSettingNotifier.getListPrinterSetting();

      prints('Payment Type Name: $paymentTypeName');
      prints(
        'Should Open Cash Drawer: ${paymentTypeName != null && paymentTypeName!.toLowerCase().contains('cash')}',
      );

      // filter the printer in the design sebab nak auto tendang cash drawer
      // jangan filter sini kalau tak printer tak tendang sebab printer dah kene filter
      // listPsm = listPsm.where((ps) => ps.automaticallyPrintReceipt!).toList();

      // listPsm = listPsm.where((ps) => ps.identifierAddress == '0.0.0.0').toList();

      if (listPsm.isNotEmpty) {
        List<String> errorIps = [];
        int completedTask = 0;

        for (PrinterSettingModel psm in listPsm) {
          try {
            prints('Current ip ${psm.identifierAddress}');
            prints('Printer Interface: ${psm.interface}');

            Future<void> printTask;

            if (psm.interface == PrinterSettingEnum.bluetooth) {
              prints('BLUETOOTH PRINT TASK FOR: ${psm.identifierAddress}');
              printTask = _receiptNotifier.printSalesReceipt(
                newReceiptId,
                isInterfaceBluetooth: true,
                ipAddress: psm.identifierAddress ?? '',
                paperWidth: ReceiptPrinterService.getPaperWidth(psm.paperWidth),
                onError: (message, ipAd) {
                  prints('BLUETOOTH PRINT ERROR: $message - $ipAd');
                  if (!errorIps.contains(ipAd)) {
                    errorIps.add(ipAd);
                  }
                },
                isShouldOpenCashDrawer:
                    (paymentTypeName != null &&
                        paymentTypeName!.toLowerCase().contains('cash')),
                listPrinterSettings: listPsm,
                isAutomaticPrint: true,
              );
            } else if (psm.interface == PrinterSettingEnum.ethernet &&
                psm.identifierAddress != null) {
              prints('ETHERNET PRINT TASK FOR: ${psm.identifierAddress}');
              printTask = _receiptNotifier.printSalesReceipt(
                newReceiptId,
                isInterfaceBluetooth: false,
                ipAddress: psm.identifierAddress!,
                paperWidth: ReceiptPrinterService.getPaperWidth(psm.paperWidth),
                onError: (message, ipAd) {
                  prints('ETHERNET PRINT ERROR: $message - $ipAd');
                  if (!errorIps.contains(ipAd)) {
                    errorIps.add(ipAd);
                  }
                },
                isShouldOpenCashDrawer:
                    (paymentTypeName != null &&
                        paymentTypeName!.toLowerCase().contains('cash')),
                listPrinterSettings: listPsm,
                isAutomaticPrint: true,
              );
            } else {
              prints(
                'SKIPPING PRINTER WITH UNKNOWN INTERFACE: ${psm.interface}',
              );
              continue;
            }

            await printTask;
            prints('PRINT TASK COMPLETED FOR: ${psm.identifierAddress}');
            completedTask++;
          } catch (e) {
            prints('ERROR DURING PRINT TASK: $e');
            prints('Stack trace: ${StackTrace.current}');
            if (!errorIps.contains(psm.identifierAddress)) {
              errorIps.add(psm.identifierAddress ?? 'unknown');
            }
            completedTask++;
          }
        }

        if (kDebugMode) {
          prints('Completed Task: $completedTask');
          prints('Total Printers: ${listPsm.length}');
          prints('Error IPs: $errorIps');
        }

        if (completedTask == listPsm.length) {
          if (errorIps.isNotEmpty) {
            prints('All printers have been attempted, but some failed.');
            onError(errorIps.join(', '));
          } else {
            prints('All printers have been attempted successfully.');
            prints('=== PAYMENT SALES RECEIPT PRINT SUCCESS ===');
            onSuccess();
          }
        } else {
          onSuccess();
          return;
        }
      } else {
        prints('NO PRINTERS FOUND');
        onSuccess();
        return;
      }
    } catch (e) {
      prints('=== PAYMENT SALES RECEIPT PRINT FATAL ERROR: $e ===');
      prints('Stack trace: ${StackTrace.current}');
      onError(e.toString());
    }
  }

  Future<ReceiptItemModel> insertOneReceiptItem(
    String newSaleId,
    SaleItemModel saleItem,
    CategoryModel? categoryModel,
    String receiptUUID,
    SaleItemNotifier saleItemNotifier,
    SaleItemState saleItemsState,
    SplitPaymentState splitPaymentState,
  ) async {
    ItemModel? itemModel = await _itemNotifier.getItemModelById(
      saleItem.itemId!,
    );
    String? soldBy;
    soldBy = itemModel!.soldBy;

    /// convert list modifier to json

    String listModifierJson = await _modifierNotifier.convertListModifierToJson(
      saleItem,
      saleItemsState.saleModifiers,
      saleItemsState.saleModifierOptions,
    );

    /// convert variant option to json
    final itemNotifier = ref.read(itemProvider.notifier);
    String listVariantOptionJson = itemNotifier.convertVariantOptionToJson(
      saleItem,
      saleItemsState.isSplitPayment
          ? splitPaymentState.saleItems
          : saleItemsState.saleItems,
    );

    if (itemModel.categoryId != null) {
      categoryModel = await _categoryNotifier.getCategoryModelById(
        itemModel.categoryId!,
      );
    }
    // Get discount lists from providers for getAllDiscountModelsForThatItem
    final discountList = ref.read(discountProvider).items;
    final discountOutletList = ref.read(discountOutletProvider).items;
    final discountItemList = ref.read(discountItemProvider).items;
    final categoryDiscountList = ref.read(categoryDiscountProvider).items;

    List<DiscountModel> listDiscountModel = [];
    listDiscountModel = _discountNotifier.getAllDiscountModelsForThatItem(
      itemModel,
      listDiscountModel,
      originDiscountList: discountList,
      discountOutletList: discountOutletList,
      discountItemList: discountItemList,
      categoryDiscountList: categoryDiscountList,
    );

    List<TaxModel> listTaxModel = [];
    listTaxModel = _taxNotifier.getAllTaxModelsForThatItem(
      itemModel,
      listTaxModel,
    );

    // Find the taxAfterDiscount value for this specific saleItem
    double taxAfterDiscountValue = 0.0;
    var taxAfterDiscountEntry = saleItemsState.listTaxAfterDiscount.firstWhere(
      (entry) => entry['saleItemId'] == saleItem.id,
      orElse: () => <String, dynamic>{},
    );
    if (taxAfterDiscountEntry.isNotEmpty) {
      taxAfterDiscountValue = taxAfterDiscountEntry['taxAfterDiscount'] ?? 0.0;
    }

    // Find the taxIncludedAfterDiscount value for this specific saleItem
    double taxIncludedAfterDiscountValue = 0.0;
    var taxIncludedAfterDiscountEntry = saleItemsState
        .listTaxIncludedAfterDiscount
        .firstWhere(
          (entry) => entry['saleItemId'] == saleItem.id,
          orElse: () => <String, dynamic>{},
        );
    if (taxIncludedAfterDiscountEntry.isNotEmpty) {
      taxIncludedAfterDiscountValue =
          taxIncludedAfterDiscountEntry['taxIncludedAfterDiscount'] ?? 0.0;
    }

    // Add the taxAfterDiscount value to each tax model
    List<Map<String, dynamic>> enrichedTaxList =
        listTaxModel.map((taxModel) {
          Map<String, dynamic> taxJson = taxModel.toJson();

          if (taxModel.type == TaxTypeEnum.Added) {
            taxJson['totalTaxAmount'] = taxAfterDiscountValue;
          } else if (taxModel.type == TaxTypeEnum.Included) {
            // If single tax, assign the full amount
            taxJson['totalTaxAmount'] = taxIncludedAfterDiscountValue;
          }

          return taxJson;
        }).toList();

    ReceiptItemModel receiptItem = ReceiptItemModel(
      id: IdUtils.generateUUID(),
      receiptId: receiptUUID,
      sku: itemModel.sku,
      barcode: itemModel.barcode,
      name: itemModel.name!,
      itemId: saleItem.itemId ?? itemModel.id,
      price: saleItem.price ?? 0, // price from item
      comment: saleItem.comments,
      cost: itemModel.cost,
      quantity: saleItem.quantity,
      totalDiscount: saleItem.discountTotal,
      totalTax: saleItem.taxAfterDiscount,
      taxIncludedAfterDiscount: saleItem.taxIncludedAfterDiscount,
      grossAmount:
          saleItemsState.isSplitPayment
              ? ref
                  .read(splitPaymentProvider.notifier)
                  .getGrossAmountPerSaleItem(saleItem)
              : saleItemNotifier.getGrossAmountPerSaleItem(saleItem),
      netSale:
          saleItemsState.isSplitPayment
              ? ref
                  .read(splitPaymentProvider.notifier)
                  .getNetSalePerSaleItem(saleItem)
              : saleItemNotifier.getNetSalePerSaleItem(saleItem),
      categoryId: categoryModel?.id,
      soldBy: soldBy,
      totalRefunded: 0,
      modifiers: listModifierJson,
      variants: listVariantOptionJson != '' ? listVariantOptionJson : null,
      discounts: jsonEncode(listDiscountModel),
      taxes: jsonEncode(enrichedTaxList),
      createdAt: DateTime.now(),
    );

    prints(enrichedTaxList);

    return await _receiptItemNotifier
        .upsertBulk([receiptItem])
        .then((value) => receiptItem);
  }

  int getTaxPercentage(
    SaleItemState saleItemsState,
    SplitPaymentState splitPaymentState,
  ) {
    double afterTax =
        saleItemsState.isSplitPayment
            ? splitPaymentState.totalWithAdjustedPrice
            : saleItemsState.totalWithAdjustedPrice;

    double tax =
        saleItemsState.isSplitPayment
            ? splitPaymentState.taxAfterDiscount
            : saleItemsState.taxAfterDiscount;

    double beforeTax = afterTax - tax;

    // Prevent divide-by-zero or negative edge cases
    if (beforeTax <= 0) {
      prints('beforeTax is zero or negative, returning 0');
      return 0;
    }

    double percentage = (tax / beforeTax) * 100;

    if (percentage.isNaN || percentage.isInfinite) {
      prints('percentage is NaN or Infinite, returning 0');
      return 0;
    }

    prints('percentage $percentage');
    return percentage.toInt();
  }

  Future<void> showDialogueSendEmail(BuildContext context) async {
    // get latest receipt
    ReceiptModel latestRM = await _receiptNotifier.getLatestReceiptModel();
    // pass to notifier
    if (latestRM.id != null) {
      ref.read(receiptProvider.notifier).setTempReceiptModel(latestRM);
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return SendEmailDialogue(
          isFluidDialogue: false,
          onSuccess: (response) {
            NavigationUtils.pop(context, response);
          },
          onError: (message) {
            NavigationUtils.pop(context, message);
          },
        );
      },
    ).then((result) {
      if (result is DefaultResponseModel) {
        // success
        CustomDialog.show(
          context,
          icon: FontAwesomeIcons.paperPlane,
          title: 'success'.tr(),
          description: result.message,
          btnOkText: 'ok'.tr(),
          btnOkOnPress: () => NavigationUtils.pop(context),
        );
      } else if (result is String) {
        // error
        CustomDialog.show(
          context,
          dialogType: DialogType.danger,
          icon: FontAwesomeIcons.circleExclamation,
          title: 'error'.tr(),
          description: result,
          btnOkText: 'ok'.tr(),
          btnOkOnPress: () => NavigationUtils.pop(context),
        );
      }
    });
  }

  /// Schedule post-dispose secondary display update for ultra-smooth navigation
  /// This method prepares data for secondary display but defers execution until after dispose
  void _schedulePostDisposeSecondaryDisplayUpdate() {
    try {
      // Get slideshow data from cache before passing to isolate
      final cachedSlideshowModel = Home.getCachedSlideshowModel();

      // Prepare minimal data needed for secondary display update
      _pendingPostDisposeData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'source': 'payment_screen_exit',
        'slideshowData':
            cachedSlideshowModel?.toJson(), // Pass slideshow data to isolate
      };

      _hasPostDisposeOperations = true;

      prints(
        '📋 Post-dispose secondary display update scheduled for smooth navigation',
      );
    } catch (e) {
      prints('❌ Error scheduling post-dispose secondary display update: $e');
      // Fallback to immediate async update if scheduling fails
      _updateSecondaryDisplayAsync();
    }
  }

  /// Execute post-dispose operations in background without blocking UI
  void _executePostDisposeOperations() {
    // Use a timer to ensure this runs after dispose is complete
    _postDisposeTimer = Timer(const Duration(milliseconds: 100), () async {
      try {
        prints(
          '🚀 Executing post-dispose secondary display update in background',
        );

        // Update secondary display in background using compute
        await _performPostDisposeSecondaryDisplayUpdate();

        // Reset menu item optimization
        MenuItem.resetAfterPaymentTransition();

        prints(
          '✅ Post-dispose secondary display update completed successfully',
        );
      } catch (e) {
        prints('❌ Error in post-dispose secondary display update: $e');
      } finally {
        // Clean up
        _pendingPostDisposeData = null;
        _hasPostDisposeOperations = false;
        _postDisposeTimer?.cancel();
        _postDisposeTimer = null;
      }
    });
  }

  /// Perform secondary display update in background after dispose
  Future<void> _performPostDisposeSecondaryDisplayUpdate() async {
    try {
      // Use compute for heavy secondary display operations
      final Map<String, dynamic> displayData = await compute(
        _prepareSecondaryDisplayDataInIsolate,
        _pendingPostDisposeData,
      );

      // Update secondary display with prepared data
      await _updateSecondaryDisplayWithData(displayData);

      prints('📺 Secondary display updated in background');
    } catch (e) {
      prints('❌ Error in background secondary display update: $e');
    }
  }

  /// Update secondary display with prepared data
  Future<void> _updateSecondaryDisplayWithData(
    Map<String, dynamic> displayData,
  ) async {
    try {
      // Use fire-and-forget approach to prevent any blocking
      ref
          .read(secondDisplayProvider.notifier)
          .navigateSecondScreen(
            MainCustomerDisplay.routeName,
            data: displayData,
          )
          .catchError((error) {
            prints('❌ Error in secondary display navigation: $error');
          });
    } catch (e) {
      prints('❌ Error updating secondary display: $e');
    }
  }

  /// Asynchronously updates the secondary display without blocking the UI
  /// This method runs in the background after navigation pop to prevent lag
  void _updateSecondaryDisplayAsync() {
    // Use Future.delayed with minimal delay to ensure UI transition completes first
    // This prevents any blocking during the critical navigation transition
    Future.delayed(const Duration(milliseconds: 50), () async {
      // Check if widget is still mounted before proceeding
      if (!mounted) return;

      // Run the update in a separate isolate-like execution to prevent any UI blocking
      await _performSecondaryDisplayUpdate();
    });
  }

  /// Performs the actual secondary display update
  /// This method is separated to allow for better error handling and testing
  Future<void> _performSecondaryDisplayUpdate() async {
    try {
      // Check if widget is still mounted before starting any heavy operations
      if (!mounted) return;

      // Use cached slideshow model from home_screen.dart to avoid DB calls and ensure consistency
      SlideshowModel? slideshowModel = Home.getCachedSlideshowModel();

      Map<String, dynamic> response;
      if (slideshowModel != null) {
        prints('✅ Using cached slideshow model for secondary display update');
        response = {DbResponseEnum.data: slideshowModel};
      } else {
        prints(
          '⚠️ Slideshow cache not available for secondary display update, falling back to DB call',
        );
        // Use a timeout to prevent hanging operations that could affect UI
        response = await _slideshowNotifier.getLatestModel().timeout(
          const Duration(seconds: 3),
          onTimeout: () => {DbResponseEnum.data: null},
        );
      }

      // Check mounted state again after async operation
      if (!mounted) return;

      // Process the response data in an isolate if it's heavy
      final Map<String, dynamic> dataWelcome = await compute(
        _processSlideShowResponse,
        response,
      );

      // Final mounted check before updating secondary display
      if (mounted) {
        // Use a fire-and-forget approach for the secondary display update
        // This prevents any potential blocking from the display manager
        ref
            .read(secondDisplayProvider.notifier)
            .navigateSecondScreen(
              MainCustomerDisplay.routeName,
              data: dataWelcome,
            )
            .catchError((error) {
              prints('❌ Error in secondary display navigation: $error');
            });

        prints('✅ Secondary display update initiated successfully');
      }
    } catch (error) {
      // Handle errors gracefully without affecting the main UI
      prints('⚠️ Error updating secondary display: $error');

      // Attempt lightweight fallback with empty slideshow data
      if (mounted) {
        try {
          final Map<String, dynamic> fallbackData = {DataEnum.slideshow: {}};

          // Use fire-and-forget for fallback as well
          ref
              .read(secondDisplayProvider.notifier)
              .navigateSecondScreen(
                MainCustomerDisplay.routeName,
                data: fallbackData,
              )
              .catchError((fallbackNavError) {
                prints(
                  '❌ Error in fallback secondary display navigation: $fallbackNavError',
                );
              });

          prints('🔄 Fallback secondary display update initiated');
        } catch (fallbackError) {
          prints(
            '❌ Error in fallback secondary display update: $fallbackError',
          );
        }
      }
    }
  }

  /// Static function to process slideshow response in an isolate
  /// This function runs in a separate isolate to avoid blocking the UI
  static Map<String, dynamic> _processSlideShowResponse(
    Map<String, dynamic> response,
  ) {
    try {
      // Import the required enum and model classes for the isolate
      // Note: We need to handle the data processing without direct model dependencies

      // Extract slideshow data from response
      final dynamic slideshowData =
          response['data']; // DbResponseEnum.data equivalent

      Map<String, dynamic> slideshowJson = {};

      if (slideshowData != null) {
        // If slideshowData has a toJson method or is already a Map
        if (slideshowData is Map<String, dynamic>) {
          slideshowJson = slideshowData;
        } else {
          // Try to convert to JSON if it has a toJson method
          try {
            slideshowJson = slideshowData.toJson() as Map<String, dynamic>;
          } catch (e) {
            // If conversion fails, use empty map
            slideshowJson = {};
          }
        }
      }

      return {
        'slideshow': slideshowJson, // DataEnum.slideshow equivalent
      };
    } catch (error) {
      // Return empty data if processing fails
      return {'slideshow': {}};
    }
  }

  /// Static function to prepare secondary display data in an isolate
  /// This function runs in a separate isolate to avoid blocking the UI
  /// Note: Static variables from main isolate (like Home.getCachedSlideshowModel())
  /// are not accessible here, so slideshow data must be passed via pendingData
  static Map<String, dynamic> _prepareSecondaryDisplayDataInIsolate(
    Map<String, dynamic>? pendingData,
  ) {
    try {
      if (pendingData == null) {
        return {'slideshow': {}};
      }

      // Prepare secondary display data in isolate
      // This simulates the heavy data preparation that would normally block the UI

      final int timestamp =
          pendingData['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;

      // Use slideshow data passed from main isolate (since static cache is not accessible in isolates)
      final Map<String, dynamic> slideshowData =
          pendingData['slideshowData'] as Map<String, dynamic>? ??
          {
            'id': 'default_slideshow',
            'title': 'Welcome Screen',
            'description': '',
            'greetings': '',
            'images': [],
            'download_urls': [],
            'created_at':
                DateTime.fromMillisecondsSinceEpoch(
                  timestamp,
                ).toIso8601String(),
            'updated_at':
                DateTime.fromMillisecondsSinceEpoch(
                  timestamp,
                ).toIso8601String(),
          };

      // Prepare the final data structure for secondary display
      final Map<String, dynamic> displayData = {
        'slideshow': slideshowData,
        'timestamp': timestamp,
        'source': 'post_dispose_cleanup',
      };

      return displayData;
    } catch (error) {
      // Return fallback data if preparation fails
      return {
        'slideshow': {},
        'error': error.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }
}
