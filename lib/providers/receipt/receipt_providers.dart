import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/data/models/default_response_model.dart';
import 'package:mts/data/models/receipt/receipt_list_response_model.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:mts/domain/repositories/local/receipt_repository.dart';
import 'package:mts/domain/repositories/remote/receipt_repository.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';
import 'package:mts/providers/receipt/receipt_state.dart';
import 'package:mts/providers/receipt_item/receipt_item_providers.dart';
import 'package:mts/providers/refund/refund_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:mts/core/enum/print_cache_status_enum.dart';
import 'package:mts/core/enum/printer_setting_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/services/receipt_printer_service.dart';
import 'package:mts/domain/repositories/local/cash_management_repository.dart';
import 'package:mts/domain/repositories/local/payment_type_repository.dart';
import 'package:mts/domain/repositories/local/print_receipt_cache_repository.dart';
import 'package:mts/domain/repositories/local/receipt_item_repository.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/shift/shift_providers.dart';

/// StateNotifier for Receipt domain
///
/// Migrated from: receipt_facade_impl.dart
///
class ReceiptNotifier extends StateNotifier<ReceiptState> {
  final LocalReceiptRepository _localRepository;
  final LocalCashManagementRepository _localCashManagementRepository;
  final ReceiptRepository _remoteRepository;
  final IWebService _webService;
  final LocalReceiptItemRepository _localReceiptItemRepository;
  final LocalPaymentTypeRepository _localPaymentTypeRepository;
  final LocalPrintReceiptCacheRepository _localPrintReceiptCacheRepository;
  final Ref _ref;

  ReceiptNotifier({
    required LocalReceiptRepository localRepository,
    required LocalReceiptItemRepository localReceiptItemRepository,
    required LocalPaymentTypeRepository localPaymentTypeRepository,
    required ReceiptRepository remoteRepository,
    required IWebService webService,
    required LocalCashManagementRepository localCashManagementRepository,
    required LocalPrintReceiptCacheRepository localPrintReceiptCacheRepository,
    required Ref ref,
  }) : _localRepository = localRepository,
       _localReceiptItemRepository = localReceiptItemRepository,
       _localPaymentTypeRepository = localPaymentTypeRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _localCashManagementRepository = localCashManagementRepository,
       _localPrintReceiptCacheRepository = localPrintReceiptCacheRepository,
       _ref = ref,
       super(const ReceiptState());

  // ============================================================
  // Business logic migrated from receipt_facade_impl.dart
  // ============================================================

  /// Insert a single receipt into local storage
  Future<int> insert(ReceiptModel model) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(model, true);

      if (result > 0) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Update a single receipt in local storage
  Future<int> update(ReceiptModel model) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.update(model, true);

      if (result > 0) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<ReceiptModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Get all items from local storage
  Future<List<ReceiptModel>> getListReceiptModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListReceiptModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Get list of receipt models by shift ID
  Future<List<ReceiptModel>> getListReceiptModelByShiftId() async {
    try {
      return await _localRepository.getListReceiptModelByShiftId();
    } catch (e) {
      return [];
    }
  }

  /// Search receipts from database
  Future<List<ReceiptModel>> searchReceiptIDFromDb(
    String query,
    DateTimeRange? dateRange,
    int page,
    int pageSize,
    String? typePayment,
    String? orderOption,
  ) async {
    try {
      return await _localRepository.searchReceiptIDFromDb(
        query,
        dateRange,
        page,
        pageSize,
        typePayment,
        orderOption,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get receipt model from ID
  Future<ReceiptModel?> getReceiptModelFromId(String idReceipt) async {
    try {
      return await _localRepository.getReceiptModelFromId(idReceipt);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Get latest receipt model
  Future<ReceiptModel> getLatestReceiptModel() async {
    try {
      return await _localRepository.getLatestReceiptModel();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return ReceiptModel();
    }
  }

  /// Calculate payable amount not refunded
  Future<double> calcPayableAmountNotRefunded() async {
    try {
      return await _localRepository.calcPayableAmountNotRefunded();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return 0.0;
    }
  }

  /// Calculate payable amount refunded
  Future<double> calcPayableAmountRefunded() async {
    try {
      return await _localRepository.calcPayableAmountRefunded();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return 0.0;
    }
  }

  /// Calculate all amount refunded
  Future<double> calcAllAmountRefunded() async {
    try {
      return await _localRepository.calcAllAmountRefunded();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return 0.0;
    }
  }

  /// Calculate gross sales
  Future<String> calcGrossSales() async {
    try {
      return await _localRepository.calcGrossSales();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return '0';
    }
  }

  /// Calculate net sales
  Future<String> calcNetSales() async {
    try {
      return await _localRepository.calcNetSales();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return '0';
    }
  }

  /// Calculate adjustment
  Future<String> calcAdjustment() async {
    try {
      return await _localRepository.calcAdjustment();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return '0';
    }
  }

  /// Calculate total discount
  Future<String> calcTotalDiscount() async {
    try {
      return await _localRepository.calcTotalDiscount();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return '0';
    }
  }

  /// Calculate total tax
  Future<String> calcTotalTax() async {
    try {
      return await _localRepository.calcTotalTax();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return '0';
    }
  }

  /// Calculate total cash rounding
  Future<String> calcTotalCashRounding() async {
    try {
      return await _localRepository.calcTotalCashRounding();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return '0';
    }
  }

  /// Send receipt to email
  Future<DefaultResponseModel> sendReceiptToEmail(
    String email,
    String receiptId,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _webService.post(
        _remoteRepository.sendReceiptToEmail(email, receiptId),
      );

      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return DefaultResponseModel({});
    }
  }

  /// Get receipts from API with pagination
  Future<List<ReceiptModel>> syncFromRemote() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      List<ReceiptModel> allReceipts = [];
      int currentPage = 1;
      int? lastPage;

      do {
        ReceiptListResponseModel responseModel = await _webService.get(
          _remoteRepository.getReceiptList(currentPage.toString()),
        );

        if (responseModel.isSuccess && responseModel.data != null) {
          await insertBulk(responseModel.data!, isInsertToPending: false);
          allReceipts.addAll(responseModel.data!);

          if (responseModel.paginator != null) {
            lastPage = responseModel.paginator!.lastPage;
          } else {
            break;
          }

          currentPage++;
        } else {
          break;
        }
      } while (lastPage != null && currentPage <= lastPage);

      state = state.copyWith(isLoading: false);
      return allReceipts;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<ReceiptModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete all items from local storage
  Future<bool> deleteAll() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteAll();

      if (result) {
        state = state.copyWith(items: []);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete a single item by ID
  Future<int> delete(String id, {bool isInsertToPending = true}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.delete(
        id,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Find an item by its ID
  Future<ReceiptModel?> getReceiptModelById(String itemId) async {
    try {
      final items = await _localRepository.getListReceiptModel();

      try {
        final item = items.firstWhere((item) => item.id == itemId);
        return item;
      } catch (e) {
        return null;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<ReceiptModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.replaceAllData(
        newData,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        state = state.copyWith(items: newData);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Upsert bulk items to Hive box without replacing all items
  Future<bool> upsertBulk(
    List<ReceiptModel> list, {
    bool isInsertToPending = true,
    bool isQueue = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Internal helper to load items and update state
  Future<void> _loadItems() async {
    try {
      final items = await _localRepository.getListReceiptModel();

      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ============================================================================
  // OLD NOTIFIER METHODS - For UI backward compatibility
  // ============================================================================

  // Getters
  List<ReceiptItemModel> get getIncomingRefundReceiptItems =>
      state.incomingRefundReceiptItems;
  List<ReceiptItemModel> get getReceiptItemsForRefund =>
      state.receiptItemsForRefund;
  List<ReceiptItemModel> get getInitialListReceiptItems =>
      state.initialListReceiptItems;
  // Note: getListReceiptModel conflicts with method from facade - using state.listReceiptModel directly
  List<ReceiptModel> get getListReceiptModelOldNotifier =>
      state.listReceiptModel;
  int get getPageIndex => state.pageIndex;
  String? get receiptIdTitle => state.receiptIdTitle;
  String get getTempReceiptId => state.tempReceiptId;
  ReceiptModel? get getTempReceiptModel => state.tempReceiptModel;
  double get getTotalDiscount => state.totalDiscount;
  double get getTaxAfterDiscount => state.taxAfterDiscount;
  double get getTaxIncludedAfterDiscount => state.taxIncludedAfterDiscount;
  double get getTotalAfterDiscountAndTax => state.totalAfterDiscountAndTax;
  List<Map<String, dynamic>> get getListTotalAfterDiscAndTax =>
      state.listTotalAfterDiscAndTax;
  PagingController<int, ReceiptModel>? get getListReceiptPagingController =>
      state.listReceiptPagingController;
  int? get getSelectedReceiptIndex => state.selectedReceiptIndex;
  int get getReceiptDialogueNavigator => state.receiptDialogueNavigator;
  DateTimeRange? get getSelectedDateRange => state.selectedDateRange;
  DateTimeRange? get getLastSelectedDateRange => state.lastSelectedDateRange;
  String get getFormattedDateRange => state.formattedDateRange;
  String? get getTempPaymentType => state.tempPaymentType;
  String? get getPreviousPaymentType => state.previousPaymentType;
  String? get getSelectedPaymentType => state.selectedPaymentType;
  int get getTempPaymentTypeIndex => state.tempPaymentTypeIndex;
  int get getPreviousPaymentTypeIndex => state.previousPaymentTypeIndex;
  int get getSelectedPaymentTypeIndex => state.selectedPaymentTypeIndex;
  String? get getTempOrderOption => state.tempOrderOption;
  String? get getPreviousOrderOption => state.previousOrderOption;
  String? get getSelectedOrderOption => state.selectedOrderOption;
  int get getTempOrderOptionIndex => state.tempOrderOptionIndex;
  int get getPreviousOrderOptionIndex => state.previousOrderOptionIndex;
  int get getSelectedOrderOptionIndex => state.selectedOrderOptionIndex;

  // Order option methods
  void setTempOrderOption(String? orderOption, int? index) {
    state = state.copyWith(
      tempOrderOption: orderOption,
      tempOrderOptionIndex: index ?? -1,
    );
    setSelectedOrderOption(orderOption, index);
  }

  void applyPreviousOrderOption() {
    state = state.copyWith(
      previousOrderOption: state.tempOrderOption,
      previousOrderOptionIndex: state.tempOrderOptionIndex,
    );
    setSelectedOrderOption(
      state.previousOrderOption,
      state.previousOrderOptionIndex,
    );
  }

  void resetPreviousOrderOption() {
    state = state.copyWith(
      tempOrderOption: state.previousOrderOption,
      tempOrderOptionIndex: state.previousOrderOptionIndex,
    );
  }

  void setSelectedOrderOption(String? orderOption, int? index) {
    state = state.copyWith(
      selectedOrderOption: orderOption,
      selectedOrderOptionIndex: index ?? -1,
    );
  }

  // Payment type methods
  void setTempPaymentType(String? paymentType, int? index) {
    state = state.copyWith(
      tempPaymentType: paymentType,
      tempPaymentTypeIndex: index ?? -1,
    );
    setSelectedPaymentType(paymentType, index);
  }

  void applyPreviousPaymentType() {
    state = state.copyWith(
      previousPaymentType: state.tempPaymentType,
      previousPaymentTypeIndex: state.tempPaymentTypeIndex,
    );
    setSelectedPaymentType(
      state.previousPaymentType,
      state.previousPaymentTypeIndex,
    );
  }

  void resetPreviousPaymentType() {
    state = state.copyWith(
      tempPaymentType: state.previousPaymentType,
      tempPaymentTypeIndex: state.previousPaymentTypeIndex,
    );
  }

  void setSelectedPaymentType(String? paymentType, int? index) {
    state = state.copyWith(
      selectedPaymentType: paymentType,
      selectedPaymentTypeIndex: index ?? -1,
    );
  }

  // Date range methods
  void setSelectedDateRange(DateTimeRange? newdDateRange) {
    state = state.copyWith(selectedDateRange: newdDateRange);
    dateFormatting(newdDateRange);
  }

  void applyLastSelectedDateRange() {
    state = state.copyWith(lastSelectedDateRange: state.selectedDateRange);
    dateFormatting(state.lastSelectedDateRange);
  }

  void resetSelectedDateRange() {
    state = state.copyWith(selectedDateRange: state.lastSelectedDateRange);
    dateFormatting(state.selectedDateRange);
  }

  void dateFormatting(DateTimeRange? dateRange) {
    if (dateRange == null) {
      state = state.copyWith(formattedDateRange: '');
      return;
    }
    final formatter = DateFormat('dd MMM yyyy HH:mm', 'en_US');
    String formattedStart = formatter.format(dateRange.start);
    String formattedEnd = formatter.format(dateRange.end);

    String formatted = '$formattedStart - $formattedEnd';
    state = state.copyWith(formattedDateRange: formatted);
  }

  // Navigation and UI state methods
  void setReceiptDialogueNavigator(int index) {
    state = state.copyWith(receiptDialogueNavigator: index);
  }

  void setSelectedReceiptIndex(int? index) {
    if (index == 0 && state.listReceiptPagingController != null) {
      state = state.copyWith(
        selectedReceiptIndex: state.listReceiptPagingController!.firstPageKey,
      );
    } else {
      state = state.copyWith(selectedReceiptIndex: index);
    }
  }

  void setPagingController(
    PagingController<int, ReceiptModel> pagingController,
  ) {
    state = state.copyWith(
      listReceiptPagingController: pagingController,
      selectedDateRange: null,
    );
  }

  void refreshPagingController() {
    if (state.listReceiptPagingController != null) {
      state.listReceiptPagingController!.refresh();
    }
  }

  // Calculation methods (Old notifier versions - for UI state management)
  void calcTotalAfterDiscountAndTaxUI() {
    double total = state.listTotalAfterDiscAndTax.fold(0, (total, map) {
      total += map['totalAfterDiscAndTax'] ?? 0;
      return total;
    });
    state = state.copyWith(totalAfterDiscountAndTax: total);
  }

  void calcTotalDiscountUI() {
    double total = state.listTotalDiscount.fold(0, (total, discountMap) {
      total += discountMap['discountTotal'] ?? 0;
      return total;
    });
    state = state.copyWith(totalDiscount: total);
  }

  void calcTaxAfterDiscountUI() {
    double total = state.listTaxAfterDiscount.fold(0, (total, taxMap) {
      total += taxMap['taxAfterDiscount'] ?? 0;
      return total;
    });
    state = state.copyWith(taxAfterDiscount: total);
  }

  void calcTaxIncludedAfterDiscountUI() {
    double total = state.listTaxIncludedAfterDiscount.fold(0, (total, taxMap) {
      total += taxMap['taxIncludedAfterDiscount'] ?? 0;
      return total;
    });
    state = state.copyWith(taxIncludedAfterDiscount: total);
  }

  Future<void> setReceiptItems(List<ReceiptItemModel> receiptItems) async {
    final listTotalDiscount = List<Map<String, dynamic>>.from(
      state.listTotalDiscount,
    );
    final listTaxAfterDiscount = List<Map<String, dynamic>>.from(
      state.listTaxAfterDiscount,
    );
    final listTaxIncludedAfterDiscount = List<Map<String, dynamic>>.from(
      state.listTaxIncludedAfterDiscount,
    );
    final listTotalAfterDiscAndTax = List<Map<String, dynamic>>.from(
      state.listTotalAfterDiscAndTax,
    );

    for (ReceiptItemModel ri in receiptItems) {
      Map<String, dynamic> discountMap = {
        'receiptItemId': ri.id,
        'discountTotal': ri.totalDiscount!,
        'updatedAt': ri.updatedAt!.toIso8601String(),
      };
      Map<String, dynamic> taxAfterDiscountMap = {
        'receiptItemId': ri.id,
        'taxAfterDiscount': ri.totalTax!,
        'updatedAt': ri.updatedAt!.toIso8601String(),
      };

      Map<String, dynamic> taxIncludedAfterDiscountMap = {
        'receiptItemId': ri.id,
        'taxIncludedAfterDiscount': ri.taxIncludedAfterDiscount!,
        'updatedAt': ri.updatedAt!.toIso8601String(),
      };

      double totalAfterDiscountAndTax = calcEachTotalAfterDiscountAndTax(ri);
      Map<String, dynamic> totalAfterDiscAndTaxMap = {
        'receiptItemId': ri.id,
        'totalAfterDiscAndTax': totalAfterDiscountAndTax,
        'updatedAt': ri.updatedAt!.toIso8601String(),
      };

      listTotalAfterDiscAndTax.add(totalAfterDiscAndTaxMap);
      listTaxAfterDiscount.add(taxAfterDiscountMap);
      listTaxIncludedAfterDiscount.add(taxIncludedAfterDiscountMap);
      listTotalDiscount.add(discountMap);
    }

    state = state.copyWith(
      receiptItemsForRefund: receiptItems,
      listTotalDiscount: listTotalDiscount,
      listTaxAfterDiscount: listTaxAfterDiscount,
      listTaxIncludedAfterDiscount: listTaxIncludedAfterDiscount,
      listTotalAfterDiscAndTax: listTotalAfterDiscAndTax,
    );

    calcTaxAfterDiscountUI();
    calcTaxIncludedAfterDiscountUI();
    calcTotalAfterDiscountAndTaxUI();
    calcTotalDiscountUI();
  }

  void clearAll() {
    state = state.copyWith(
      listTotalDiscount: [],
      listTaxAfterDiscount: [],
      listTaxIncludedAfterDiscount: [],
      listTotalAfterDiscAndTax: [],
      receiptItemsForRefund: [],
    );
    calcTaxAfterDiscountUI();
    calcTotalAfterDiscountAndTaxUI();
    calcTotalDiscountUI();
    calcTaxIncludedAfterDiscountUI();
  }

  double calcEachTotalAfterDiscountAndTax(ReceiptItemModel receiptItem) {
    double total =
        (receiptItem.price!) +
        receiptItem.totalTax! -
        (receiptItem.totalDiscount!);

    return total;
  }

  void setTempReceiptModel(ReceiptModel receiptModel) {
    state = state.copyWith(
      tempReceiptId: receiptModel.id!,
      tempReceiptModel: receiptModel,
    );
  }

  void clearTempReceiptId() {
    state = state.copyWith(tempReceiptId: '-1', tempReceiptModel: null);
  }

  void setReceiptIdTitle(String title) {
    state = state.copyWith(receiptIdTitle: title);
  }

  void setPageIndex(int index) {
    state = state.copyWith(pageIndex: index);
  }

  void addBulkInitialListReceiptItems(List<ReceiptItemModel> receiptItems) {
    state = state.copyWith(initialListReceiptItems: receiptItems);
  }

  // Complex methods with calculation logic
  void removeReceiptItemAndMoveToRefund(
    BuildContext context,
    ReceiptItemModel receiptItem,
  ) {
    final receiptItemsForRefund = List<ReceiptItemModel>.from(
      state.receiptItemsForRefund,
    );
    final listTotalDiscount = List<Map<String, dynamic>>.from(
      state.listTotalDiscount,
    );
    final listTaxAfterDiscount = List<Map<String, dynamic>>.from(
      state.listTaxAfterDiscount,
    );
    final listTaxIncludedAfterDiscount = List<Map<String, dynamic>>.from(
      state.listTaxIncludedAfterDiscount,
    );
    final listTotalAfterDiscAndTax = List<Map<String, dynamic>>.from(
      state.listTotalAfterDiscAndTax,
    );

    ReceiptItemModel selectedRI = receiptItemsForRefund.firstWhere(
      (ri) => ri.id == receiptItem.id,
      orElse: () => ReceiptItemModel(),
    );

    if (selectedRI.id != null) {
      // save/lock origin receiptItem to pass to addRefund
      final originReceiptItem = receiptItem.copyWith();

      double perPrice =
          selectedRI.soldBy == ItemSoldByEnum.item
              ? (selectedRI.grossAmount! / selectedRI.quantity!)
              : selectedRI.grossAmount!;
      double perDiscount = selectedRI.totalDiscount! / selectedRI.quantity!;
      // to get the price per tax to re calculate the new tax after discount
      double pricePerTax = selectedRI.totalTax! / selectedRI.quantity!; // =1.90
      double pricePerTaxIncluded =
          selectedRI.taxIncludedAfterDiscount! / selectedRI.quantity!;

      /// check if the qty and totalrefund is same, cannot tap, cannot remove or decrease the qty
      double qty = selectedRI.quantity!;
      double totalRefund = selectedRI.totalRefunded;

      if (qty == totalRefund) {
        return;
      }

      // check qty
      if (selectedRI.quantity! > 1 &&
          receiptItem.soldBy == ItemSoldByEnum.item) {
        // minus one qty
        selectedRI.quantity = selectedRI.quantity! - 1;
        selectedRI.price = selectedRI.price! - perPrice;
        selectedRI.grossAmount = perPrice * selectedRI.quantity!;
        selectedRI.totalDiscount = selectedRI.totalDiscount! - perDiscount;
        selectedRI.totalTax = selectedRI.totalTax! - pricePerTax;
        selectedRI.taxIncludedAfterDiscount =
            selectedRI.taxIncludedAfterDiscount! - pricePerTaxIncluded;

        double newTotalDiscount = selectedRI.totalDiscount!;
        double newTotalTax = selectedRI.totalTax!;
        double newTaxIncluded = selectedRI.taxIncludedAfterDiscount!;

        /// update the [discountTotal] and [taxAfterDiscount] and [taxIncludedAfterDiscount] and [totalAfterDiscAndTax]
        /// find [discountTotal]
        final discountMap = listTotalDiscount.firstWhere(
          (element) =>
              element['receiptItemId'] == selectedRI.id &&
              element['updatedAt'] == selectedRI.updatedAt!.toIso8601String(),
          orElse: () => {},
        );

        /// find [taxAfterDiscount]
        final taxAfterDiscountMap = listTaxAfterDiscount.firstWhere(
          (element) =>
              element['receiptItemId'] == selectedRI.id &&
              element['updatedAt'] == selectedRI.updatedAt!.toIso8601String(),
          orElse: () => {},
        );

        /// find [taxIncludedAfterDiscount]
        final taxIncludedAfterDiscountMap = listTaxIncludedAfterDiscount
            .firstWhere(
              (element) =>
                  element['receiptItemId'] == selectedRI.id &&
                  element['updatedAt'] ==
                      selectedRI.updatedAt!.toIso8601String(),
              orElse: () => {},
            );

        /// find [totalAfterDiscAndTax]
        final totalAfterDiscAndTaxMap = listTotalAfterDiscAndTax.firstWhere(
          (element) =>
              element['receiptItemId'] == selectedRI.id &&
              element['updatedAt'] == selectedRI.updatedAt!.toIso8601String(),
          orElse: () => {},
        );

        /// assign new values to the [discountTotal] and [totalAfterDiscAndTax] and [taxIncludedAfterDiscount]  and [taxAfterDiscount]
        if (discountMap.isNotEmpty) {
          double totalDiscount = newTotalDiscount;
          discountMap['receiptItemId'] = selectedRI.id;
          discountMap['updatedAt'] = selectedRI.updatedAt!.toIso8601String();
          discountMap['discountTotal'] = totalDiscount;
        }

        if (taxAfterDiscountMap.isNotEmpty) {
          double taxAfterDiscount = newTotalTax; // 5 * 1.90
          taxAfterDiscountMap['receiptItemId'] = selectedRI.id;
          taxAfterDiscountMap['updatedAt'] =
              selectedRI.updatedAt!.toIso8601String();
          taxAfterDiscountMap['taxAfterDiscount'] = taxAfterDiscount;

          // continue update the selectedSI
          selectedRI.totalTax = taxAfterDiscount;
        }

        if (taxIncludedAfterDiscountMap.isNotEmpty) {
          double taxIncludedAfterDiscount = newTaxIncluded; // 5 * 1.90
          taxIncludedAfterDiscountMap['receiptItemId'] = selectedRI.id;
          taxIncludedAfterDiscountMap['updatedAt'] =
              selectedRI.updatedAt!.toIso8601String();
          taxIncludedAfterDiscountMap['taxIncludedAfterDiscount'] =
              taxIncludedAfterDiscount;

          selectedRI.taxIncludedAfterDiscount = taxIncludedAfterDiscount;
        }

        if (totalAfterDiscAndTaxMap.isNotEmpty) {
          double totalAfterDiscAndTax = calcEachTotalAfterDiscountAndTax(
            selectedRI,
          );

          totalAfterDiscAndTaxMap['receiptItemId'] = selectedRI.id;
          totalAfterDiscAndTaxMap['updatedAt'] =
              selectedRI.updatedAt!.toIso8601String();
          totalAfterDiscAndTaxMap['totalAfterDiscAndTax'] =
              totalAfterDiscAndTax;
        }

        // find index of the saleItem to update it
        int indexSaleItem = receiptItemsForRefund.indexWhere(
          (element) =>
              element.id == selectedRI.id &&
              element.updatedAt == selectedRI.updatedAt,
        );

        if (indexSaleItem != -1) {
          receiptItemsForRefund[indexSaleItem] = selectedRI;
        }

        state = state.copyWith(
          receiptItemsForRefund: receiptItemsForRefund,
          listTotalDiscount: listTotalDiscount,
          listTaxAfterDiscount: listTaxAfterDiscount,
          listTaxIncludedAfterDiscount: listTaxIncludedAfterDiscount,
          listTotalAfterDiscAndTax: listTotalAfterDiscAndTax,
        );

        calcTotalAfterDiscountAndTaxUI();
        calcTaxAfterDiscountUI();
        calcTotalDiscountUI();
        calcTaxIncludedAfterDiscountUI();

        /// [PROCESS ADD ITEM TO REFUND NOTIFIER]
        _ref
            .read(refundProvider.notifier)
            .addItemToRefund(selectedRI, originReceiptItem);
      } else {
        selectedRI.totalDiscount = selectedRI.totalDiscount! - perDiscount;
        selectedRI.totalTax = selectedRI.totalTax! - pricePerTax;
        selectedRI.taxIncludedAfterDiscount =
            selectedRI.taxIncludedAfterDiscount! - pricePerTaxIncluded;

        // remove all the item from the right side because the qty is 1
        _ref
            .read(refundProvider.notifier)
            .addItemToRefund(selectedRI, originReceiptItem);
        selectedRI.quantity = selectedRI.quantity! - 1;
        selectedRI.grossAmount = perPrice * selectedRI.quantity!;
        selectedRI.price = selectedRI.price! - perPrice;

        removeReceiptItemFromNotifier(selectedRI.id!, selectedRI.updatedAt!);
        reCalculateAllTotal(selectedRI.id!, selectedRI.updatedAt!);
      }
    }
  }

  void addItemToReceipt(
    ReceiptItemModel receiptItem,
    ReceiptItemModel originRI,
  ) async {
    final receiptItemsForRefund = List<ReceiptItemModel>.from(
      state.receiptItemsForRefund,
    );
    final listTotalDiscount = List<Map<String, dynamic>>.from(
      state.listTotalDiscount,
    );
    final listTaxAfterDiscount = List<Map<String, dynamic>>.from(
      state.listTaxAfterDiscount,
    );
    final listTaxIncludedAfterDiscount = List<Map<String, dynamic>>.from(
      state.listTaxIncludedAfterDiscount,
    );
    final listTotalAfterDiscAndTax = List<Map<String, dynamic>>.from(
      state.listTotalAfterDiscAndTax,
    );

    ReceiptItemModel selectedRI = receiptItemsForRefund.firstWhere(
      (element) =>
          element.id == receiptItem.id &&
          element.updatedAt == receiptItem.updatedAt,
      orElse: () => ReceiptItemModel(),
    );

    if (selectedRI.id != null) {
      // means receipt item is exist, update qty, price, discountTotal, totalAfterDiscAndTax, taxAfterDiscount
      double perPrice = selectedRI.grossAmount! / selectedRI.quantity!;
      double newTotalDiscount =
          originRI.totalDiscount! - receiptItem.totalDiscount!;

      double newTaxAfterDiscount = originRI.totalTax! - receiptItem.totalTax!;
      double newTaxIncludedAfterDiscount =
          originRI.taxIncludedAfterDiscount! -
          receiptItem.taxIncludedAfterDiscount!;
      if (selectedRI.soldBy == ItemSoldByEnum.item) {
        selectedRI.quantity = selectedRI.quantity! + 1;
        selectedRI.price = selectedRI.price! + perPrice;
        selectedRI.grossAmount = perPrice * selectedRI.quantity!;
      } else if (selectedRI.soldBy == ItemSoldByEnum.measurement) {
        selectedRI.quantity = receiptItem.quantity!;
        selectedRI.grossAmount = selectedRI.price! * selectedRI.quantity!;
        selectedRI.price = selectedRI.price! + perPrice;
      }

      selectedRI.totalDiscount = newTotalDiscount;
      selectedRI.totalTax = newTaxAfterDiscount;
      selectedRI.taxIncludedAfterDiscount = newTaxIncludedAfterDiscount;

      /// update the [discountTotal] and [taxAfterDiscount] and [totalAfterDiscAndTax]
      /// find [discountTotal]
      final discountMap = listTotalDiscount.firstWhere(
        (element) =>
            element['receiptItemId'] == selectedRI.id &&
            element['updatedAt'] == selectedRI.updatedAt!.toIso8601String(),
        orElse: () => {},
      );

      /// find [taxAfterDiscount]
      final taxAfterDiscountMap = listTaxAfterDiscount.firstWhere(
        (element) =>
            element['receiptItemId'] == selectedRI.id &&
            element['updatedAt'] == selectedRI.updatedAt!.toIso8601String(),
        orElse: () => {},
      );

      /// find [taxIncludedAfterDiscount]
      final taxIncludedAfterDiscountMap = listTaxIncludedAfterDiscount
          .firstWhere(
            (element) =>
                element['receiptItemId'] == selectedRI.id &&
                element['updatedAt'] == selectedRI.updatedAt!.toIso8601String(),
            orElse: () => {},
          );

      /// find [totalAfterDiscAndTax]
      final totalAfterDiscAndTaxMap = listTotalAfterDiscAndTax.firstWhere(
        (element) =>
            element['receiptItemId'] == selectedRI.id &&
            element['updatedAt'] == selectedRI.updatedAt!.toIso8601String(),
        orElse: () => {},
      );

      /// assign new values to the [discountTotal] and [totalAfterDiscAndTax]  and [taxAfterDiscount]
      if (discountMap.isNotEmpty) {
        double totalDiscount = newTotalDiscount;
        discountMap['receiptItemId'] = selectedRI.id;
        discountMap['updatedAt'] = selectedRI.updatedAt!.toIso8601String();
        discountMap['discountTotal'] = totalDiscount;

        selectedRI.totalDiscount = totalDiscount;
      }

      if (taxAfterDiscountMap.isNotEmpty) {
        double taxAfterDiscount = newTaxAfterDiscount; // 5 * 1.90
        taxAfterDiscountMap['receiptItemId'] = selectedRI.id;
        taxAfterDiscountMap['updatedAt'] =
            selectedRI.updatedAt!.toIso8601String();
        taxAfterDiscountMap['taxAfterDiscount'] = taxAfterDiscount;

        // continue update the selectedSI
        selectedRI.totalTax = taxAfterDiscount;
      }

      if (taxIncludedAfterDiscountMap.isNotEmpty) {
        double taxIncludedAfterDiscount = newTaxIncludedAfterDiscount;
        taxIncludedAfterDiscountMap['receiptItemId'] = selectedRI.id;
        taxIncludedAfterDiscountMap['updatedAt'] =
            selectedRI.updatedAt!.toIso8601String();
        taxIncludedAfterDiscountMap['taxIncludedAfterDiscount'] =
            taxIncludedAfterDiscount;

        // continue update the selectedSI
        selectedRI.taxIncludedAfterDiscount = taxIncludedAfterDiscount;
      }

      if (totalAfterDiscAndTaxMap.isNotEmpty) {
        double totalAfterDiscAndTax = calcEachTotalAfterDiscountAndTax(
          selectedRI,
        );

        totalAfterDiscAndTaxMap['receiptItemId'] = selectedRI.id;
        totalAfterDiscAndTaxMap['updatedAt'] =
            selectedRI.updatedAt!.toIso8601String();
        totalAfterDiscAndTaxMap['totalAfterDiscAndTax'] = totalAfterDiscAndTax;
      }

      int indexReceiptItem = receiptItemsForRefund.indexWhere(
        (element) =>
            element.id == selectedRI.id &&
            element.updatedAt == selectedRI.updatedAt,
      );

      if (indexReceiptItem != -1) {
        receiptItemsForRefund[indexReceiptItem] = selectedRI;
      }

      state = state.copyWith(
        receiptItemsForRefund: receiptItemsForRefund,
        listTotalDiscount: listTotalDiscount,
        listTaxAfterDiscount: listTaxAfterDiscount,
        listTaxIncludedAfterDiscount: listTaxIncludedAfterDiscount,
        listTotalAfterDiscAndTax: listTotalAfterDiscAndTax,
      );

      calcTotalAfterDiscountAndTaxUI();
      calcTaxAfterDiscountUI();
      calcTotalDiscountUI();
      calcTaxIncludedAfterDiscountUI();
    } else {
      // means receipt item is not exist, add to list
      double perPrice =
          receiptItem.soldBy == ItemSoldByEnum.item
              ? (receiptItem.grossAmount! / receiptItem.quantity!)
              : receiptItem.grossAmount!;

      double newQty =
          receiptItem.soldBy == ItemSoldByEnum.item ? 1 : receiptItem.quantity!;

      double newTotalDiscount =
          originRI.totalDiscount! - receiptItem.totalDiscount!;

      double newTaxAfterDiscount = originRI.totalTax! - receiptItem.totalTax!;
      double newTaxIncludedAfterDiscount =
          originRI.taxIncludedAfterDiscount! -
          receiptItem.taxIncludedAfterDiscount!;
      double newTotalPrice = perPrice + newTaxAfterDiscount - newTotalDiscount;

      // generate new discountTotal, taxAfterDiscount, totalAfterDiscAndTax
      /// get [discountTotal]
      double totalDiscount = newTotalDiscount;
      Map<String, dynamic> totalDiscountMap = {
        'receiptItemId': receiptItem.id,
        'updatedAt': receiptItem.updatedAt!.toIso8601String(),
        'discountTotal': totalDiscount,
      };

      /// get [totalTaxAfterDiscount]
      double taxAfterDiscount = newTaxAfterDiscount;
      Map<String, dynamic> taxAfterDiscountMap = {
        'receiptItemId': receiptItem.id,
        'updatedAt': receiptItem.updatedAt!.toIso8601String(),
        'taxAfterDiscount': taxAfterDiscount,
      };

      /// get [totalTaxIncludedAfterDiscount]
      double taxIncludedAfterDiscount = newTaxIncludedAfterDiscount;
      Map<String, dynamic> taxIncludedAfterDiscountMap = {
        'receiptItemId': receiptItem.id,
        'updatedAt': receiptItem.updatedAt!.toIso8601String(),
        'taxIncludedAfterDiscount': taxIncludedAfterDiscount,
      };

      /// get [totalAfterDiscAndTax]
      double newTotalAfterDiscAndTax = newTotalPrice;
      Map<String, dynamic> totalAfterDiscAndTaxMap = {
        'receiptItemId': receiptItem.id,
        'updatedAt': receiptItem.updatedAt!.toIso8601String(),
        'totalAfterDiscAndTax': newTotalAfterDiscAndTax,
      };

      ReceiptItemModel newRI = receiptItem.copyWith(
        quantity: newQty,
        price: perPrice,
        grossAmount: perPrice,
        totalTax: newTaxAfterDiscount,
        taxIncludedAfterDiscount: newTaxIncludedAfterDiscount,
      );

      listTotalDiscount.add(totalDiscountMap);
      listTaxAfterDiscount.add(taxAfterDiscountMap);
      listTaxIncludedAfterDiscount.add(taxIncludedAfterDiscountMap);
      listTotalAfterDiscAndTax.add(totalAfterDiscAndTaxMap);

      receiptItemsForRefund.add(newRI);

      state = state.copyWith(
        receiptItemsForRefund: receiptItemsForRefund,
        listTotalDiscount: listTotalDiscount,
        listTaxAfterDiscount: listTaxAfterDiscount,
        listTaxIncludedAfterDiscount: listTaxIncludedAfterDiscount,
        listTotalAfterDiscAndTax: listTotalAfterDiscAndTax,
      );

      calcTaxAfterDiscountUI();
      calcTotalAfterDiscountAndTaxUI();
      calcTotalDiscountUI();
      calcTaxIncludedAfterDiscountUI();
    }
  }

  void removeReceiptItemFromNotifier(String receiptItemId, DateTime updatedAt) {
    final receiptItemsForRefund = List<ReceiptItemModel>.from(
      state.receiptItemsForRefund,
    );
    receiptItemsForRefund.removeWhere(
      (element) =>
          element.id == receiptItemId && element.updatedAt == updatedAt,
    );
    state = state.copyWith(receiptItemsForRefund: receiptItemsForRefund);
  }

  void removeDiscountTaxAndTotal(String receiptItemId, DateTime updatedAt) {
    final listTotalDiscount = List<Map<String, dynamic>>.from(
      state.listTotalDiscount,
    );
    final listTaxAfterDiscount = List<Map<String, dynamic>>.from(
      state.listTaxAfterDiscount,
    );
    final listTaxIncludedAfterDiscount = List<Map<String, dynamic>>.from(
      state.listTaxIncludedAfterDiscount,
    );
    final listTotalAfterDiscAndTax = List<Map<String, dynamic>>.from(
      state.listTotalAfterDiscAndTax,
    );

    listTotalDiscount.removeWhere(
      (element) =>
          element['receiptItemId'] == receiptItemId &&
          element['updatedAt'] == updatedAt.toIso8601String(),
    );
    listTaxAfterDiscount.removeWhere(
      (element) =>
          element['receiptItemId'] == receiptItemId &&
          element['updatedAt'] == updatedAt.toIso8601String(),
    );
    listTaxIncludedAfterDiscount.removeWhere(
      (element) =>
          element['receiptItemId'] == receiptItemId &&
          element['updatedAt'] == updatedAt.toIso8601String(),
    );
    listTotalAfterDiscAndTax.removeWhere(
      (element) =>
          element['receiptItemId'] == receiptItemId &&
          element['updatedAt'] == updatedAt.toIso8601String(),
    );

    state = state.copyWith(
      listTotalDiscount: listTotalDiscount,
      listTaxAfterDiscount: listTaxAfterDiscount,
      listTaxIncludedAfterDiscount: listTaxIncludedAfterDiscount,
      listTotalAfterDiscAndTax: listTotalAfterDiscAndTax,
    );
  }

  void reCalculateAllTotal(String receiptItemId, DateTime updatedAt) {
    removeDiscountTaxAndTotal(receiptItemId, updatedAt);

    calcTaxAfterDiscountUI();
    calcTotalAfterDiscountAndTaxUI();
    calcTotalDiscountUI();
    calcTaxIncludedAfterDiscountUI();
  }

  // ============================================================================
  // END OLD NOTIFIER METHODS
  // ============================================================================

  Future<void> printSalesReceipt(
    String receiptID, {
    required bool isInterfaceBluetooth,
    required String ipAddress,
    required String paperWidth,
    required Function(String, String) onError,
    required bool isShouldOpenCashDrawer,
    required List<PrinterSettingModel> listPrinterSettings,
    required bool isAutomaticPrint,
  }) async {
    ReceiptModel? receiptModel = await getReceiptModelFromId(receiptID);

    if (receiptModel?.id != null) {
      final paymentTypeName = receiptModel!.paymentType;

      List<ReceiptItemModel> receiptItems = [];

      receiptItems = await _localReceiptItemRepository
          .getListReceiptItemsByReceiptId(receiptModel.id!);

      bool isOpenCashDrawer = false;
      if (paymentTypeName != null &&
          paymentTypeName.toLowerCase().contains('cash') &&
          isShouldOpenCashDrawer) {
        // open cash drawer
        isOpenCashDrawer = true;
      }

      await _ref
          .read(printerSettingProvider.notifier)
          .printSalesReceipt(
            isOpenCashDrawer: isOpenCashDrawer,
            receiptModel: receiptModel,
            receiptItems: receiptItems,
            isInterfaceBluetooth: isInterfaceBluetooth,
            ipAddress: ipAddress,
            paperWidth: paperWidth,
            onError: onError,
            listPrinterSettings: listPrinterSettings,
            isAutomaticPrint: isAutomaticPrint,
            activityFrom: 'Print Sales Receipt - ${receiptModel.showUUID}',
          );
    } else {
      prints('❌❌❌❌❌❌❌❌ReceiptModel is null in print sales receipt');
    }
  }

  Future<void> printRefundReceipt(
    String receiptID, {
    required bool isInterfaceBluetooth,
    required String ipAddress,
    required String paperWidth,
    required Function(String message, String ipAdd) onError,
    required bool isShouldOpenCashDrawer,
    required List<PrinterSettingModel> listPrinterSettings,
    required bool isAutomaticPrint,
    required WidgetRef ref,
  }) async {
    ReceiptModel? receiptModel = await getReceiptModelFromId(receiptID);

    List<ReceiptItemModel> receiptItems = [];

    if (receiptModel != null) {
      final paymentTypeName = receiptModel.paymentType;
      receiptItems = await _localReceiptItemRepository
          .getListReceiptItemsByReceiptId(receiptModel.id!);

      bool isOpenCashDrawer = false;
      if (paymentTypeName!.toLowerCase().contains('cash') &&
          isShouldOpenCashDrawer) {
        // open cash drawer
        isOpenCashDrawer = true;
      }
      await _ref
          .read(printerSettingProvider.notifier)
          .printRefundReceipt(
            isOpenCashDrawer: isOpenCashDrawer,
            receiptModel: receiptModel,
            receiptItems: receiptItems,
            isInterfaceBluetooth: isInterfaceBluetooth,
            ipAddress: ipAddress,
            paperWidth: paperWidth,

            onError: onError,
            listPrinterSettings: listPrinterSettings,
            isAutomaticPrint: isAutomaticPrint,
            activityFrom:
                'Print Refund Receipt - ${receiptModel.refundedReceiptId}',
            ref: ref,
          );
    } else {
      prints('ReceiptModel is null in print sales receipt');
    }
  }

  Future<void> printKitchenReceipt(
    SaleModel saleModel, {
    required List<SaleItemModel> listSaleItem,
    required List<SaleModifierModel> listSM,
    required List<SaleModifierOptionModel> listSMO,
    required OrderOptionModel? receivingOrderOption,
    required PredefinedOrderModel? pom,
    required String ipAddress,
    required bool isinterfaceBluetooth,
    required String paperWidth,
    required DepartmentPrinterModel dpm,
    required Function(String message, String ipAdd) onError,
    required Function(List<PrintReceiptCacheModel> listSaleItems)
    onSuccessPrintReceiptCache,

    required PrinterSettingModel printerSetting,
    required PrintReceiptCacheModel printCacheModel,
  }) async {
    final printerSettingNotifier = _ref.read(printerSettingProvider.notifier);
    List<SaleModifierModel> saleModifiers = [];
    List<SaleModifierOptionModel> saleModifierOptions = [];

    OrderOptionModel? orderOptionModel;

    saleModifiers = listSM;
    saleModifierOptions = listSMO;
    orderOptionModel = receivingOrderOption;

    if (saleModel.id != null) {
      // find order number
      int orderNumber = saleModel.runningNumber ?? 0;

      // find table number using predefined order id

      if (pom?.id == null) {
        // prints("pom is null");
        // prints(saleModel.predefinedOrderId);
        return;
      }

      //   prints("LIST SALE ITTEM FOR KITCHEN PRINT");
      //   prints(listSaleItem.map((e) => e.id));

      /// [filter list sale item by isPrinted = false]
      // if (!isPrintAgain) {
      //   listSaleItem =
      //       listSaleItem
      //           .where(
      //             (saleItem) =>
      //                 !saleItem.isPrintedKitchen! && !saleItem.isPrintedVoided!,
      //           )
      //           .toList();
      // }

      // List<SaleModifierModel> saleModifiers = result.modifiers;
      // List<SaleModifierOptionModel> saleModifierOptions = result.options;

      if (listSaleItem.isNotEmpty) {
        await printerSettingNotifier.printKitchenOrderDesign(
          isInterfaceBluetooth: isinterfaceBluetooth,
          ipAddress: ipAddress,
          paperWidth: paperWidth,
          orderNumber: orderNumber,
          saleModel: saleModel,
          tableNumber: pom?.name ?? '-',
          listSM: saleModifiers,
          listSMO: saleModifierOptions,
          listSaleItems: listSaleItem,
          orderOptionModel: orderOptionModel,
          dpm: dpm,
          onError: (message, ip) async {
            if (printCacheModel.id != null) {
              final updatePrc = printCacheModel.copyWith(
                status: PrintCacheStatusEnum.failed,
                printedAttempts:
                    printCacheModel.printedAttempts != null
                        ? printCacheModel.printedAttempts! + 1
                        : 1,
                printedAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              await _localPrintReceiptCacheRepository.update(updatePrc, true);
              // delete the success print cache to clean up the database
              await _localPrintReceiptCacheRepository
                  .deleteBySuccessAndCancelStatusAndFailed();
            }
            onError(message, ip);
          },
          printerSetting: printerSetting,
          onSuccess: () async {
            // handle update print cache to success for pending changes
            if (printCacheModel.id != null) {
              final updatePRC = printCacheModel.copyWith(
                status: PrintCacheStatusEnum.success,
                printedAttempts:
                    printCacheModel.printedAttempts != null
                        ? printCacheModel.printedAttempts! + 1
                        : 1,
                printedAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              // await _localPrintReceiptCacheRepository.update(updatePRC, true);
              // then delete the print cache with false insertToPending to maintain the database in the server
              await _localPrintReceiptCacheRepository.delete(
                printCacheModel.id!,
                false,
              );
              // delete the success print cache to clean up the database
              await _localPrintReceiptCacheRepository
                  .deleteBySuccessAndCancelStatusAndFailed();
              await _localPrintReceiptCacheRepository.onlyInsertToPending(
                updatePRC,
              );
            }

            final saleItemsNotifier = _ref.read(saleItemProvider.notifier);
            final saleItemsState = _ref.read(saleItemProvider);

            /// [after print, update the sale items to isPrinted = true]
            // List<SaleItemModel> updatedListSI = [];
            // for (SaleItemModel si in listSaleItem) {
            //   SaleItemModel updSI = si.copyWith(isPrintedKitchen: true);
            //   updatedListSI.add(updSI);
            // }
            // await Future.delayed(const Duration(seconds: pusherPeriodTime));

            // get sale item ids to print to compare with updatedListSI
            // List<String> saleItemIdsToPrintPrevious =
            //     SaleModel.decodeSaleItemIds(saleModel.saleItemIdsToPrint);

            // List<String> updatedListSIIds =
            //     updatedListSI.map((si) => si.id!).toList();

            // List<String> newSaleItemIdsToPrint =
            //     saleItemIdsToPrintPrevious
            //         .toSet()
            //         .difference(updatedListSIIds.toSet())
            //         .toList();
            // change to onSuccess
            // if (isPrintAgain) {
            //   await Future.wait(
            //     updatedListSI.map((si) async {
            //       await _localSaleItemRepository.update(si, true);
            //     }),
            //   );
            // }

            // await _localSaleRepository.update(
            //   saleModel.copyWith(
            //     saleItemIdsToPrint: jsonEncode(newSaleItemIdsToPrint),
            //   ),
            //   true,
            // );

            // check list order empty or not
            final listShowedSI = saleItemsState.saleItems;
            if (listShowedSI.isNotEmpty) {
              // merge but unique

              final List<SaleItemModel> mergedListSI = [...listShowedSI];

              // remove duplicate
              final Set<String?> seenIds = {};
              final List<SaleItemModel> uniqueListSI =
                  mergedListSI.where((item) {
                    return seenIds.add(item.id);
                  }).toList();

              // assign the new updated list SI to the state
              saleItemsNotifier.setSaleItems(uniqueListSI);
            }
            if (printCacheModel.id != null) {
              onSuccessPrintReceiptCache([printCacheModel]);
            }
          },
        );
      }
    } else {
      prints('sale model is null, cannot print KITCHEN receipt');
      return;
    }
  }

  Future<void> printVoidReceipt(
    SaleModel saleModel, {
    required String ipAddress,
    required bool isInterfaceBluetooth,
    required String paperWidth,
    required DepartmentPrinterModel dpm,
    required List<SaleItemModel> listSaleItems,
    required List<SaleModifierModel> listSM,
    required List<SaleModifierOptionModel> listSMO,
    required OrderOptionModel? receivingOrderOption,
    required PredefinedOrderModel? pom,
    required Function(String message, String ipAdd) onError,
    required Function(List<PrintReceiptCacheModel>) onSuccessPrintReceiptCache,

    required PrintReceiptCacheModel printCacheModel,
  }) async {
    // find sale model using sale id
    final printerSettingNotifier = _ref.read(printerSettingProvider.notifier);

    List<SaleModifierModel> saleModifiers = [];
    List<SaleModifierOptionModel> saleModifierOptions = [];

    OrderOptionModel? orderOptionModel;

    saleModifiers = listSM;
    saleModifierOptions = listSMO;
    orderOptionModel = receivingOrderOption;

    if (saleModel.id != null) {
      // find order number
      int orderNumber = saleModel.runningNumber ?? 0;

      if (pom?.id == null) {
        prints(
          "❌ PredefinedOrder is null for ID: ${saleModel.predefinedOrderId}",
        );
        prints("❌ Cannot print VOID receipt without PredefinedOrder");
        return;
      }

      // only print if list is not empty
      if (listSaleItems.isNotEmpty) {
        prints(
          '✅ list items for void is not empty: ${listSaleItems.length} items',
        );

        await printerSettingNotifier.printVoidReceipt(
          isInterfaceBluetooth: isInterfaceBluetooth,
          ipAddress: ipAddress,
          paperWidth: paperWidth,
          orderNumber: orderNumber,
          tableNumber: pom?.name ?? '-',
          saleModel: saleModel,
          listSaleItems: listSaleItems,
          listSM: saleModifiers,
          listSMO: saleModifierOptions,
          orderOptionModel: orderOptionModel,
          dpm: dpm,
          onError: (msg, ipAdd) {
            prints('❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌Error printing VOID receipt: $msg');
            onError(msg, ipAdd);
          },
          onSuccess: (listSI) async {
            await updateListSiIsPrintedVoided(
              saleModel,
              printCacheModel,
              onSuccessPrintReceiptCache: onSuccessPrintReceiptCache,
            );
          },
        );
      } else {
        prints('list items for void is empty');
      }
    } else {
      prints('sale model is null, cannot print VOID receipt');
      return;
    }
  }

  Future<void> updateListSiIsPrintedVoided(
    SaleModel saleModel,
    PrintReceiptCacheModel printCacheModel, {
    required Function(List<PrintReceiptCacheModel>) onSuccessPrintReceiptCache,
  }) async {
    // handle update print cache to success for pending changes
    if (printCacheModel.id != null) {
      final updatePRC = printCacheModel.copyWith(
        status: PrintCacheStatusEnum.success,
        printedAttempts:
            printCacheModel.printedAttempts != null
                ? printCacheModel.printedAttempts! + 1
                : 1,
        printedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // then delete the print cache with false insertToPending to maintain the database in the server
      await _localPrintReceiptCacheRepository.delete(
        printCacheModel.id!,
        false,
      );
      // delete the success print cache to clean up the database
      await _localPrintReceiptCacheRepository
          .deleteBySuccessAndCancelStatusAndFailed();
      await _localPrintReceiptCacheRepository.onlyInsertToPending(updatePRC);
    }
    // final saleItemFacade = ServiceLocator.get<SaleItemFacade>();

    /// [after print, update the sale items to isPrintedVoided = true]
    List<SaleItemModel> listUpdatedSaleItems = [];

    if (printCacheModel.id != null && printCacheModel.printData != null) {
      printCacheModel.printData!.listSaleItems = listUpdatedSaleItems;
      onSuccessPrintReceiptCache([printCacheModel]);
    }
  }

  Future<Map<String, dynamic>> dataCloseShift(
    bool isForBackOffice, {
    required ShiftModel? shiftModel,
  }) async {
    String totalGrossSales = '0.00';
    String totalNetSales = '0.00';
    String totalReceiptItemsNotRefundedSoldByItem = '0';
    String totalReceiptItemsNotRefundedSoldByMeasurement = '0.000';
    String totalAdjustment = '0.00';
    String totalDiscount = '0.00';
    String totalTaxes = '0.00';
    String totalCashRounding = '0.00';
    String totalRefunds = '0.00';
    String totalPayIn = '0.00';
    String totalPayOut = '0.00';
    String cashRefunds = '0.00';
    String cashPayments = '0.00';
    String expectedCash = '0.00';
    List<ReceiptItemModel> listReceiptItemModelsNotRefunded = [];
    List<PaymentTypeModel> listPaymentTypeModels = [];
    List<ReceiptModel> listReceiptModels = [];
    final shiftNotifier = _ref.read(shiftProvider.notifier);

    totalPayIn = (await _localCashManagementRepository
            .getSumAmountPayInNotSynced())
        .toStringAsFixed(2);
    totalPayOut = (await _localCashManagementRepository
            .getSumAmountPayOutNotSynced())
        .toStringAsFixed(2);

    totalGrossSales = await calcGrossSales();
    totalNetSales = await calcNetSales();
    totalReceiptItemsNotRefundedSoldByItem =
        await _localReceiptItemRepository
            .calcTotalQuantityNotRefundedSoldByItem();

    totalReceiptItemsNotRefundedSoldByMeasurement =
        await _localReceiptItemRepository
            .calcTotalQuantityNotRefundedSoldByMeasurement();
    totalRefunds = (await calcAllAmountRefunded()).toStringAsFixed(2);
    cashRefunds = (await calcPayableAmountRefunded()).toStringAsFixed(2);
    cashPayments = (await calcPayableAmountNotRefunded()).toStringAsFixed(2);
    expectedCash =
        shiftModel?.expectedCash != null
            ? shiftModel!.expectedCash!.toStringAsFixed(2)
            : (await shiftNotifier.getLatestExpectedCash()).toStringAsFixed(2);
    totalAdjustment = await calcAdjustment();
    totalDiscount = await calcTotalDiscount();
    totalTaxes = await calcTotalTax();
    totalCashRounding = await calcTotalCashRounding();
    listReceiptItemModelsNotRefunded =
        await _localReceiptItemRepository.getListReceiptItemsNotRefunded();
    listPaymentTypeModels =
        await _localPaymentTypeRepository.getListPaymentType();
    listReceiptModels = await getListReceiptModelByShiftId();

    if (!isForBackOffice) {
      return {
        'totalGrossSales': totalGrossSales,
        'totalNetSales': totalNetSales,
        'totalReceiptItemsNotRefundedSoldByItem':
            totalReceiptItemsNotRefundedSoldByItem,
        'totalReceiptItemsNotRefundedSoldByMeasurement':
            totalReceiptItemsNotRefundedSoldByMeasurement,
        'totalAdjustment': totalAdjustment,
        'totalDiscount': totalDiscount,
        'totalTaxes': totalTaxes,
        'totalCashRounding': totalCashRounding,
        'totalRefunds': totalRefunds,
        'listReceiptItemModelsNotRefunded': listReceiptItemModelsNotRefunded,
        'listPaymentTypeModels': listPaymentTypeModels,
        'listReceiptModels': listReceiptModels,
        'totalPayIn': totalPayIn,
        'totalPayOut': totalPayOut,
        'cashRefunds': cashRefunds,
        'cashPayments': cashPayments,
        'expectedCash': expectedCash,
      };
    } else {
      Map<String, dynamic> paymentTypeAmounts = {};
      for (PaymentTypeModel paymentType in listPaymentTypeModels) {
        paymentTypeAmounts[paymentType.name ?? ''] = 0.00;
      }

      // Sum the netsales amounts for each payment type from the receipts
      for (ReceiptModel receipt in listReceiptModels) {
        if (receipt.paymentType != null &&
            paymentTypeAmounts.containsKey(receipt.paymentType)) {
          paymentTypeAmounts[receipt.paymentType ?? ''] =
              (paymentTypeAmounts[receipt.paymentType] ?? 0.0) +
              (receipt.netSale ?? 0.0);
        }
      }
      // Prepare the list of payment type amounts
      List<Map<String, double>> paymentTypeList = [];
      for (String key in paymentTypeAmounts.keys) {
        paymentTypeList.add({key: paymentTypeAmounts[key] ?? 0.0});
      }
      // Initialize the map with values
      Map<String, dynamic> result = {
        'gross_sales': double.tryParse(totalGrossSales) ?? 0.00,
        'refunds': double.tryParse(totalRefunds) ?? 0.00,
        'cash_refunds': double.tryParse(cashRefunds) ?? 0.00,
        'cash_payments': double.tryParse(cashPayments) ?? 0.00,
        'net_sales': double.tryParse(totalNetSales) ?? 0.00,
        'discounts': double.tryParse(totalDiscount) ?? 0.00,
        'taxes': double.tryParse(totalTaxes) ?? 0.00,
        'adjustment': double.tryParse(totalAdjustment) ?? 0.00,
        'rounding': double.tryParse(totalCashRounding) ?? 0.00,
        'pay_in': double.tryParse(totalPayIn) ?? 0.00,
        'pay_out': double.tryParse(totalPayOut) ?? 0.00,
        'payment_type': paymentTypeList,
        'expected_cash': double.tryParse(expectedCash) ?? 0.00,
      };

      // Check if all values are 0.00 and paymentTypeList is empty
      bool allZeroValues = result.values.whereType<double>().every(
        (value) => value == 0.00,
      );

      bool isPaymentTypeEmpty = paymentTypeList.isEmpty;

      if (allZeroValues && isPaymentTypeEmpty) {
        return {};
      }

      return result;
    }
  }

  Future<void> handleOnPressPrintReceipt(
    ReceiptModel receiptModel, {
    required List<PrinterSettingModel> listPsm,
    required Function(String errorIps) onError,
    required Function() onSuccess,
    required bool isAutomaticPrint,
    bool isShouldOpenCashDrawer = true,
    required WidgetRef ref,
  }) async {
    List<String> errorIps = []; // Store all error IPs
    int completedTask = 0;

    /// [PRINT SALES RECEIPT]
    for (PrinterSettingModel psm in listPsm) {
      Future<void> printTask;

      if (psm.interface == PrinterSettingEnum.bluetooth) {
        printTask = printSalesReceipt(
          receiptModel.id!,
          isInterfaceBluetooth: true,
          ipAddress: psm.identifierAddress ?? '',
          paperWidth: ReceiptPrinterService.getPaperWidth(psm.paperWidth),
          onError: (message, ipAddress) {
            errorIps.add(ipAddress);
          },
          isShouldOpenCashDrawer: isShouldOpenCashDrawer,
          listPrinterSettings: listPsm,
          isAutomaticPrint: isAutomaticPrint,
        );
      } else if (psm.interface == PrinterSettingEnum.ethernet &&
          psm.identifierAddress != null) {
        printTask = printSalesReceipt(
          receiptModel.id!,
          isInterfaceBluetooth: false,
          ipAddress: psm.identifierAddress!,
          paperWidth: ReceiptPrinterService.getPaperWidth(psm.paperWidth),
          onError: (message, ipAddress) {
            errorIps.add(ipAddress);
          },
          isShouldOpenCashDrawer: isShouldOpenCashDrawer,
          listPrinterSettings: listPsm,
          isAutomaticPrint: isAutomaticPrint,
        );
      } else {
        continue;
      }

      await printTask;
      completedTask++;
    }

    if (kDebugMode) {
      prints('Completed Task: $completedTask');
      prints('Total Printers: ${listPsm.length}');
      prints('Error IPs: $errorIps');
    }

    if (completedTask == listPsm.length) {
      if (errorIps.isNotEmpty) {
        onError(errorIps.join(', '));
        return;
      } else {
        onSuccess();
        return;
      }
    } else {
      onSuccess();
      return;
    }
  }

  Future<void> printLatestReceipt(
    bool mounted,
    BuildContext context, {
    required Function() onSuccess,
    required Function(String message) onError,
    required WidgetRef ref,
  }) async {
    // get latest receipt model
    ReceiptModel receiptModel = await getLatestReceiptModel();
    List<PrinterSettingModel> listPsm =
        await _ref
            .read(printerSettingProvider.notifier)
            .getListPrinterSetting();
    // already do the filtering in the SalesDesignPrint
    // listPsm = listPsm.where((ps) => ps.printReceiptBills!).toList();

    if (receiptModel.id == null) {
      onError('noReceiptFound'.tr());
      return;
    }

    if (mounted) {
      await handleOnPressPrintReceipt(
        receiptModel,
        listPsm: listPsm,
        onError: onError,
        onSuccess: onSuccess,
        isAutomaticPrint: false,
        isShouldOpenCashDrawer: false, // Reprint should NOT open cash drawer
        ref: ref,
      );
    }
  }

  Resource getReceiptList(String page) {
    return _remoteRepository.getReceiptList(page);
  }

  Future<Map<String, dynamic>> getDataForReceiptDetails(
    String receiptId,
  ) async {
    final receiptNotifier = _ref.read(receiptItemProvider.notifier);
    ReceiptModel receiptModel =
        await getReceiptModelFromId(receiptId) ?? ReceiptModel();
    double totalTaxIncluded = 0;
    totalTaxIncluded = await receiptNotifier
        .calcTaxIncludedAfterDiscountByReceiptId(receiptId);
    return {'receiptModel': receiptModel, 'totalTaxIncluded': totalTaxIncluded};
  }
}

/// Provider for sorted items (computed provider)
final sortedReceiptsProvider = Provider<List<ReceiptModel>>((ref) {
  final items = ref.watch(receiptProvider).items;
  final sorted = List<ReceiptModel>.from(items);
  sorted.sort((a, b) {
    if (a.createdAt == null && b.createdAt == null) return 0;
    if (a.createdAt == null) return 1;
    if (b.createdAt == null) return -1;
    return b.createdAt!.compareTo(a.createdAt!);
  });
  return sorted;
});

/// Provider for receipt domain
final receiptProvider = StateNotifierProvider<ReceiptNotifier, ReceiptState>((
  ref,
) {
  return ReceiptNotifier(
    localRepository: ServiceLocator.get<LocalReceiptRepository>(),
    localPaymentTypeRepository:
        ServiceLocator.get<LocalPaymentTypeRepository>(),
    remoteRepository: ServiceLocator.get<ReceiptRepository>(),
    webService: ServiceLocator.get<IWebService>(),
    localPrintReceiptCacheRepository:
        ServiceLocator.get<LocalPrintReceiptCacheRepository>(),
    localCashManagementRepository:
        ServiceLocator.get<LocalCashManagementRepository>(),
    localReceiptItemRepository:
        ServiceLocator.get<LocalReceiptItemRepository>(),
    ref: ref,
  );
});

/// Provider for receipt by ID (family provider for indexed lookups)
final receiptByIdProvider = FutureProvider.family<ReceiptModel?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(receiptProvider.notifier);
  return notifier.getReceiptModelById(id);
});

/// Provider for receipt by ID (sync version - computed provider)
final receiptByIdSyncProvider = Provider.family<ReceiptModel?, String>((
  ref,
  id,
) {
  final items = ref.watch(receiptProvider).items;
  try {
    return items.firstWhere((item) => item.id == id);
  } catch (e) {
    return null;
  }
});

/// Provider for receipts count
final receiptsCountProvider = Provider<int>((ref) {
  final items = ref.watch(receiptProvider).items;
  return items.length;
});

/// Provider for receipt refund items
final receiptRefundItemsProvider = Provider<List<ReceiptItemModel>>((ref) {
  return ref.watch(receiptProvider).receiptItemsForRefund;
});

/// Provider for incoming refund receipt items
final incomingRefundReceiptItemsProvider = Provider<List<ReceiptItemModel>>((
  ref,
) {
  return ref.watch(receiptProvider).incomingRefundReceiptItems;
});

/// Provider for receipt total after discount and tax
final receiptTotalAfterDiscountAndTaxProvider = Provider<double>((ref) {
  return ref.watch(receiptProvider).totalAfterDiscountAndTax;
});

/// Provider for receipt total discount
final receiptTotalDiscountProvider = Provider<double>((ref) {
  return ref.watch(receiptProvider).totalDiscount;
});

/// Provider for receipt tax after discount
final receiptTaxAfterDiscountProvider = Provider<double>((ref) {
  return ref.watch(receiptProvider).taxAfterDiscount;
});

/// Provider for selected receipt index
final selectedReceiptIndexProvider = Provider<int?>((ref) {
  return ref.watch(receiptProvider).selectedReceiptIndex;
});

/// Provider for receipt dialogue navigator
final receiptDialogueNavigatorProvider = Provider<int>((ref) {
  return ref.watch(receiptProvider).receiptDialogueNavigator;
});

/// Provider for selected date range
final selectedDateRangeProvider = Provider<DateTimeRange?>((ref) {
  return ref.watch(receiptProvider).selectedDateRange;
});

/// Provider for selected payment type
final selectedPaymentTypeProvider = Provider<String?>((ref) {
  return ref.watch(receiptProvider).selectedPaymentType;
});

/// Provider for selected order option
final selectedOrderOptionProvider = Provider<String?>((ref) {
  return ref.watch(receiptProvider).selectedOrderOption;
});
