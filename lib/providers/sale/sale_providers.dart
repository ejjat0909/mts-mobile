import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/enum/db_response_enum.dart';
import 'package:mts/core/enum/department_type_enum.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/core/enum/table_status_enum.dart';
import 'package:mts/core/enums/inventory_transaction_type_enum.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_model.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/data/models/sale/sale_list_response_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/core/services/secondary_display_service.dart';
import 'package:mts/domain/repositories/local/order_option_repository.dart';
import 'package:mts/domain/repositories/local/predefined_order_repository.dart';
import 'package:mts/domain/repositories/local/sale_item_repository.dart';
import 'package:mts/domain/repositories/local/sale_modifier_option_repository.dart';
import 'package:mts/domain/repositories/local/sale_modifier_repository.dart';
import 'package:mts/domain/repositories/local/sale_repository.dart';
import 'package:mts/domain/repositories/remote/sale_repository.dart';
import 'package:mts/main.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/dialogs/loading_dialogue.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/features/customer_display_preview/main_customer_display_show_receipt.dart';
import 'package:mts/presentation/features/open_and_move_order/open_and_move_order_dialogue.dart';
import 'package:mts/presentation/features/sales/components/menu_item.dart';
import 'package:mts/providers/customer/customer_providers.dart';
import 'package:mts/providers/deleted_sale_item/deleted_sale_item_providers.dart';
import 'package:mts/providers/dialog_navigator/dialog_navigator_providers.dart';
import 'package:mts/providers/inventory/inventory_providers.dart';
import 'package:mts/providers/modifier/modifier_providers.dart';
import 'package:mts/providers/order_option/order_option_providers.dart';
import 'package:mts/providers/outlet/outlet_providers.dart';
import 'package:mts/providers/print_receipt_cache/print_receipt_cache_providers.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';
import 'package:mts/providers/sale/sale_state.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/sale_modifier/sale_modifier_providers.dart';
import 'package:mts/providers/sale_modifier_option/sale_modifier_option_providers.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';
import 'package:mts/providers/slideshow/slideshow_providers.dart';
import 'package:mts/providers/staff/staff_providers.dart';
import 'package:mts/providers/table_layout/table_layout_providers.dart';
import 'package:mts/providers/user/user_providers.dart';

/// StateNotifier for Sale domain
///
/// Migrated from: sale_facade_impl.dart
class SaleNotifier extends StateNotifier<SaleState> {
  final LocalSaleRepository _localRepository;
  final LocalSaleItemRepository _localSaleItemRepository;
  final LocalSaleModifierRepository _localSaleModifierRepository;
  final LocalSaleModifierOptionRepository _localSaleModifierOptionRepository;
  final LocalPredefinedOrderRepository _localPredefinedOrderRepository;
  final LocalOrderOptionRepository _localOrderOptionRepository;
  final SaleRepository _remoteRepository;
  final IWebService _webService;
  final Ref _ref;

  SaleNotifier(
    this._ref, {
    required LocalSaleRepository localRepository,
    required LocalSaleItemRepository localSaleItemRepository,
    required LocalSaleModifierRepository localSaleModifierRepository,
    required LocalSaleModifierOptionRepository
    localSaleModifierOptionRepository,
    required LocalPredefinedOrderRepository localPredefinedOrderRepository,
    required LocalOrderOptionRepository localOrderOptionRepository,
    required SaleRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _localSaleItemRepository = localSaleItemRepository,
       _localSaleModifierRepository = localSaleModifierRepository,
       _localSaleModifierOptionRepository = localSaleModifierOptionRepository,
       _localPredefinedOrderRepository = localPredefinedOrderRepository,
       _localOrderOptionRepository = localOrderOptionRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const SaleState());

  // ============================================================
  // CRUD Operations - Optimized for Riverpod
  // ============================================================

  /// Insert a single sale
  Future<int> insert(SaleModel saleModel) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(saleModel, true);

      if (result > 0) {
        final currentItems = List<SaleModel>.from(state.items);
        final index = currentItems.indexWhere(
          (item) => item.id == saleModel.id,
        );
        if (index >= 0) {
          currentItems[index] = saleModel;
        } else {
          currentItems.add(saleModel);
        }
        state = state.copyWith(items: currentItems, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Update a single sale
  Future<String> update(
    SaleModel saleModel, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.update(
        saleModel,
        isInsertToPending,
      );

      if (result.isNotEmpty) {
        final currentItems = List<SaleModel>.from(state.items);
        final index = currentItems.indexWhere(
          (item) => item.id == saleModel.id,
        );
        if (index >= 0) {
          currentItems[index] = saleModel;
        } else {
          currentItems.add(saleModel);
        }
        state = state.copyWith(items: currentItems, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return '';
    }
  }

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<SaleModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<SaleModel>.from(state.items);
        for (final newItem in list) {
          final index = currentItems.indexWhere(
            (item) => item.id == newItem.id,
          );
          if (index >= 0) {
            currentItems[index] = newItem;
          } else {
            currentItems.add(newItem);
          }
        }
        state = state.copyWith(items: currentItems, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Get all items from local storage
  Future<List<SaleModel>> getListSaleModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListSaleModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<SaleModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        final idsToRemove = list.map((item) => item.id).toSet();
        final updatedItems =
            state.items
                .where((item) => !idsToRemove.contains(item.id))
                .toList();
        state = state.copyWith(items: updatedItems, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

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
        final updatedItems =
            state.items.where((item) => item.id != id).toList();
        state = state.copyWith(items: updatedItems, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Find an item by its ID
  Future<SaleModel?> getSaleModelById(String itemId) async {
    try {
      final items = await _localRepository.getListSaleModel();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => SaleModel(),
        );
        return item.id != null ? item : null;
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
    List<SaleModel> newData, {
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
    List<SaleModel> list, {
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
        final existingItems = List<SaleModel>.from(state.items);
        for (final item in list) {
          final index = existingItems.indexWhere((e) => e.id == item.id);
          if (index >= 0) {
            existingItems[index] = item;
          } else {
            existingItems.add(item);
          }
        }
        state = state.copyWith(items: existingItems, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ============================================================
  // Query Methods
  // ============================================================

  /// Get list of sales based on staff ID and charged at
  Future<List<SaleModel>> getListSalesBasedOnStaffIdChargedAt() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items =
          await _localRepository.getListSalesBasedOnStaffIdAndChargedAt();
      state = state.copyWith(isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Get sale model by sale ID (with order option enrichment)
  Future<SaleModel?> getSaleModelBySaleId(String id) async {
    try {
      final orderOptionNotifier = _ref.read(orderOptionProvider.notifier);
      SaleModel? sale = await _localRepository.getSaleModelBySaleId(id);

      if (sale != null &&
          sale.orderOptionId != null &&
          sale.orderOptionId!.isNotEmpty) {
        String? orderOptionName = await orderOptionNotifier
            .getOrderOptionNameById(sale.orderOptionId!);
        sale.orderOptionName = orderOptionName;
      }

      return sale;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Get sale model by predefined order ID (with order option enrichment)
  Future<SaleModel?> getSaleModelByPredefinedOrderId(String? poId) async {
    try {
      final orderOptionNotifier = _ref.read(orderOptionProvider.notifier);
      SaleModel? sale = await _localRepository.getSaleModelByPredefinedOrderId(
        poId,
      );

      if (sale != null &&
          sale.orderOptionId != null &&
          sale.orderOptionId!.isNotEmpty) {
        String? orderOptionName = await orderOptionNotifier
            .getOrderOptionNameById(sale.orderOptionId!);
        sale.orderOptionName = orderOptionName;
      }

      return sale;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Get list of saved orders (with staff and order option info)
  Future<List<SaleModel>> getListSavedOrders() async {
    try {
      final userNotifier = _ref.read(userProvider.notifier);
      final orderOptionNotifier = _ref.read(orderOptionProvider.notifier);
      List<SaleModel> listSavedOrders =
          await getListSalesBasedOnStaffIdChargedAt();

      for (SaleModel sale in listSavedOrders) {
        // get userModel from staff id
        UserModel? userModel = await userNotifier.getUserModelFromStaffId(
          sale.staffId ?? '',
        );
        if (userModel?.id != null) {
          sale.staffName = userModel!.name ?? 'No Staff';
        }

        // get order option name from order option id
        if (sale.orderOptionId != null && sale.orderOptionId!.isNotEmpty) {
          String? orderOptionName = await orderOptionNotifier
              .getOrderOptionNameById(sale.orderOptionId!);
          sale.orderOptionName = orderOptionName;
        }
      }
      return listSavedOrders;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get paginated list of saved orders
  Future<List<SaleModel>> getListSavedOrdersPaginated({
    required int page,
    required int pageSize,
  }) async {
    try {
      final userNotifier = _ref.read(userProvider.notifier);
      final orderOptionNotifier = _ref.read(orderOptionProvider.notifier);

      // Get all saved orders
      List<SaleModel> allOrders = await getListSalesBasedOnStaffIdChargedAt();

      // Calculate pagination
      final startIndex = page * pageSize;
      final endIndex = startIndex + pageSize;

      // Get the page slice
      List<SaleModel> pageOrders =
          allOrders.length > startIndex
              ? allOrders.sublist(
                startIndex,
                endIndex > allOrders.length ? allOrders.length : endIndex,
              )
              : [];

      // Enrich the page data with staff and order option info
      for (SaleModel sale in pageOrders) {
        // get userModel from staff id
        UserModel? userModel = await userNotifier.getUserModelFromStaffId(
          sale.staffId ?? '',
        );
        if (userModel?.id != null) {
          sale.staffName = userModel!.name ?? 'No Staff';
        }

        // get order option name from order option id
        if (sale.orderOptionId != null && sale.orderOptionId!.isNotEmpty) {
          String? orderOptionName = await orderOptionNotifier
              .getOrderOptionNameById(sale.orderOptionId!);
          sale.orderOptionName = orderOptionName;
        }
      }

      return pageOrders;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get total count of saved orders
  Future<int> getTotalSavedOrdersCount() async {
    try {
      final allOrders = await getListSalesBasedOnStaffIdChargedAt();
      return allOrders.length;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return 0;
    }
  }

  /// Get saved orders by predefined order IDs
  Future<List<SaleModel>> getSavedOrdersByPredefinedOrderIds(
    List<String> predefinedOrderIds,
  ) async {
    try {
      return await _localRepository.getSavedOrdersByPredefinedOrderIds(
        predefinedOrderIds,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get available saved orders to assign to table with pagination
  Future<List<SaleModel>> getAvailableSavedOrdersToAssignTableWithPagination({
    required int page,
    required int pageSize,
  }) async {
    try {
      final userNotifier = _ref.read(userProvider.notifier);
      final orderOptionNotifier = _ref.read(orderOptionProvider.notifier);

      // get list predefined order to get the ids
      List<PredefinedOrderModel> listPredefinedOrders =
          await _localPredefinedOrderRepository
              .getPredefinedOrderThatHaveNoTableAndOccupied();
      List<String> predefinedOrderIds =
          listPredefinedOrders.map((po) => po.id!).toList();

      List<SaleModel> allOrders = await getSavedOrdersByPredefinedOrderIds(
        predefinedOrderIds,
      );

      // calculate pagination
      final startIndex = page * pageSize;
      final endIndex = startIndex + pageSize;

      // Get the page slice
      List<SaleModel> pageOrders =
          allOrders.length > startIndex
              ? allOrders.sublist(
                startIndex,
                endIndex > allOrders.length ? allOrders.length : endIndex,
              )
              : [];

      // Enrich the page data with staff and order option info
      for (SaleModel sale in pageOrders) {
        // get userModel from staff id
        UserModel? userModel = await userNotifier.getUserModelFromStaffId(
          sale.staffId ?? '',
        );
        if (userModel?.id != null) {
          sale.staffName = userModel!.name ?? 'No Staff';
        }

        // get order option name from order option id
        if (sale.orderOptionId != null && sale.orderOptionId!.isNotEmpty) {
          String? orderOptionName = await orderOptionNotifier
              .getOrderOptionNameById(sale.orderOptionId!);
          sale.orderOptionName = orderOptionName;
        }
      }

      return pageOrders;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // ============================================================
  // Update Operations
  // ============================================================

  /// Update chargedAt timestamp for a sale
  Future<int> updateChargedAt(String idSaleModel) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.updateChargedAt(idSaleModel);
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Clear table reference by table ID
  Future<bool> clearTableReferenceByTableId(String targetTableId) async {
    try {
      return await _localRepository.clearTableReferenceByTableId(targetTableId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Un-charge a sale (remove chargedAt timestamp)
  Future<bool> unChargeSale(SaleModel saleModel) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.unChargeSale(saleModel);
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ============================================================
  // Business Logic Methods
  // ============================================================

  /// Create new sale and insert
  Future<SaleModel> createNewSaleAndInsert(
    String newSaleId,
    String? orderOptionId,
    int runningNumber,
    PredefinedOrderModel? predefinedOrderModel,
    ReceiptModel newReceiptModel,
    int? saleItemCount,
  ) async {
    try {
      StaffModel staffModel = ServiceLocator.get<StaffModel>();
      OutletModel outletModel = ServiceLocator.get<OutletModel>();
      SaleModel saleModel = SaleModel(
        id: newSaleId,
        staffId: staffModel.id,
        orderOptionId: orderOptionId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        chargedAt: DateTime.now(),
        remarks: predefinedOrderModel?.remarks ?? 'na'.tr(),
        predefinedOrderId: predefinedOrderModel?.id,
        name: predefinedOrderModel?.name ?? 'na'.tr(),
        runningNumber: runningNumber,
        totalPrice: double.parse(newReceiptModel.grossSale!.toStringAsFixed(2)),
        outletId: outletModel.id,
        saleItemCount: saleItemCount,
      );
      // dont use upsertBulk because of the timing issue
      await insert(saleModel);
      return saleModel;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Get possible payment amounts based on total
  List<String> getPossiblePaymentAmounts(double totalAmount) {
    List<double> possibleAmounts = [totalAmount];

    if (totalAmount == 0.00) {
      return ['0.00', '1.00', '5.00', '10.00'];
    }

    double nextMultipleOf5 = ((totalAmount / 5).ceil() * 5).toDouble();
    if (nextMultipleOf5 <= totalAmount) {
      nextMultipleOf5 += 5;
    }
    if (!possibleAmounts.contains(nextMultipleOf5)) {
      possibleAmounts.add(nextMultipleOf5);
    }

    double nextMultipleOf50 = ((totalAmount / 50).ceil() * 50).toDouble();
    if (nextMultipleOf50 <= totalAmount) {
      nextMultipleOf50 += 50;
    }
    if (!possibleAmounts.contains(nextMultipleOf50)) {
      possibleAmounts.add(nextMultipleOf50);
    }

    double nextMultipleOf100 = ((totalAmount / 100).ceil() * 100).toDouble();
    if (nextMultipleOf100 <= totalAmount) {
      nextMultipleOf100 += 100;
    }
    if (!possibleAmounts.contains(nextMultipleOf100)) {
      possibleAmounts.add(nextMultipleOf100);
    }

    while (possibleAmounts.length < 4) {
      double nextValue = (possibleAmounts.last / 5).ceil() * 5;
      if (nextValue <= possibleAmounts.last) {
        nextValue = possibleAmounts.last + 5;
      }
      if (!possibleAmounts.contains(nextValue)) {
        possibleAmounts.add(nextValue);
      } else {
        break;
      }
    }

    if (kDebugMode) {
      prints(possibleAmounts);
    }
    return possibleAmounts.map((e) => e.toStringAsFixed(2)).toList();
  }

  /// Get print data for isPrintAgain
  Future<Map<String, dynamic>> getPrintDataForIsPrintAgain(
    SaleModel saleModel,
  ) async {
    try {
      if (saleModel.id == null) {
        throw Exception('Sale Model ID is missing');
      }

      Map<String, dynamic> data = {};

      List<SaleItemModel> listSI = await _localSaleItemRepository
          .getListSaleItemBasedOnSaleId(saleModel.id!);
      List<SaleModifierModel> listSM = await _localSaleModifierRepository
          .getListSaleModifierModelBySaleId(saleModel.id!);

      List<SaleModifierOptionModel> listSMO =
          await _localSaleModifierOptionRepository
              .getListSaleModifierOptionModelBySaleId(saleModel.id!);

      OrderOptionModel? orderOptionModel = await _localOrderOptionRepository
          .getOrderOptionModelById(saleModel.orderOptionId ?? "");

      PredefinedOrderModel? predefinedOrderModel =
          await _localPredefinedOrderRepository.getPredefinedOrderById(
            saleModel.predefinedOrderId,
          );

      data['saleModel'] = saleModel;
      data['listSI'] = listSI;
      data['listSM'] = listSM;
      data['listSMO'] = listSMO;
      data['orderOptionModel'] = orderOptionModel; // can null
      data['predefinedOrderModel'] = predefinedOrderModel; // can null

      return data;
    } catch (e) {
      prints('Error get data for print again: $e');
      return {};
    }
  }

  // ============================================================
  // Complex Business Operations
  // ============================================================

  /// Save order into predefined order
  Future<void> saveOrderIntoPredefinedOrder(
    BuildContext context,
    String? predefinedOrderId, {
    bool printToKitchen = true,
    Function(SaleModel)? onSuccess,
    Function(SaleModel)? beforeSave,
    required TableModel tableModel,
  }) async {
    try {
      final printCacheNotifier = _ref.read(printReceiptCacheProvider.notifier);
      final saleItemsState = _ref.read(saleItemProvider);
      final saleItemsNotifier = _ref.read(saleItemProvider.notifier);
      final customerNotifier = _ref.read(customerProvider.notifier);
      final outletFacade = _ref.read(outletProvider.notifier);
      final modifierFacade = _ref.read(modifierProvider.notifier);

      UserModel userModel = GetIt.instance<UserModel>();
      OutletModel outletModel = GetIt.instance<OutletModel>();

      // get total price
      double totalPrice = saleItemsState.totalAfterDiscountAndTax;

      // get staff model to get staff id
      final staffFacade = _ref.read(staffProvider.notifier);
      StaffModel? staffModel = await staffFacade.getStaffModelByUserId(
        userModel.id!.toString(),
      );

      List<SaleItemModel> listSaleItems = saleItemsState.saleItems;
      List<SaleItemModel> newListSaleItems = [];
      List<SaleModel> newListSaleModels = [];

      List<SaleModifierModel> listSaleModifierModels =
          saleItemsState.saleModifiers;
      List<SaleModifierModel> newListSM = [];

      List<SaleModifierOptionModel> listSaleModifierOptionModels =
          saleItemsState.saleModifierOptions;
      List<SaleModifierOptionModel> newListSMO = [];

      // last step, clear the order sale item in the notifier
      saleItemsNotifier.clearOrderItems();
      saleItemsNotifier.calcTotalAfterDiscountAndTax();
      saleItemsNotifier.calcTaxAfterDiscount();
      saleItemsNotifier.calcTotalDiscount();
      saleItemsNotifier.calcTaxIncludedAfterDiscount();

      // reset current table
      saleItemsNotifier.setSelectedTable(TableModel());
      // reset current predefined order model
      saleItemsNotifier.setPredefinedOrderModel(PredefinedOrderModel());
      // reset current sale model
      saleItemsNotifier.setCurrSaleModel(SaleModel());

      customerNotifier.setOrderCustomerModel(null);
      String newSaleId = IdUtils.generateUUID();

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
            listSM.forEach((currSM) async {
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
            });
          }

          String modifierJson = await modifierFacade.convertListModifierToJson(
            saleItemModel,
            listSaleModifierModels,
            listSaleModifierOptionModels,
          );

          listJson.add(modifierJson);

          // generate new to avoid duplicate from list in notifier
          SaleItemModel newSaleItemModel = saleItemModel.copyWith(
            id: newSaleItemId,
            saleId: newSaleId,
            isVoided: false,
          );
          newListSaleItems.add(newSaleItemModel);
        }
      }

      // update running number
      int latestRunningNumber = 1;
      await outletFacade.incrementNextOrderNumber(
        onRunningNumber: (runningNumber) {
          latestRunningNumber = runningNumber;
        },
      );

      PredefinedOrderModel? openOrder = await _localPredefinedOrderRepository
          .getPredefinedOrderById(predefinedOrderId);

      if (openOrder == null) {
        return;
      }

      // generate new sale model
      SaleModel newSaleModel = SaleModel(
        id: newSaleId,
        staffId: staffModel!.id,
        outletId: outletModel.id,
        predefinedOrderId: openOrder.id,
        name: openOrder.name,
        remarks: openOrder.remarks,
        runningNumber: latestRunningNumber,
        totalPrice: double.parse(totalPrice.toStringAsFixed(2)),
        orderOptionId: saleItemsState.orderOptionModel?.id,
        saleItemCount: newListSaleItems.length,
      );

      if (beforeSave != null) {
        newSaleModel.tableId = tableModel.id;
        newSaleModel.tableName = tableModel.name;
      }

      newListSaleModels.add(newSaleModel);

      // add to print cache
      await printCacheNotifier.insertDetailsPrintCache(
        saleModel: newSaleModel,
        listSaleItemModel: newListSaleItems,
        listSM: newListSM,
        listSMO: newListSMO,
        orderOptionModel:
            saleItemsState.orderOptionModel ??
            OrderOptionModel(id: '', name: ''),
        pom: openOrder,
        printType: DepartmentTypeEnum.printKitchen,
        isForThisDevice: true,
      );
      prints('CARI PRINTER');

      /// [PRINT KITCHEN ORDER]
      /// [ONLY FOR KITCHEN GROUP]
      await attemptPrintKitchen(onSuccessPrintReceiptCache: (listPRC) {});

      await printCacheNotifier.insertDetailsPrintCache(
        saleModel: newSaleModel,
        listSaleItemModel: newListSaleItems,
        listSM: newListSM,
        listSMO: newListSMO,
        orderOptionModel:
            saleItemsState.orderOptionModel ??
            OrderOptionModel(id: '', name: ''),
        pom: openOrder,
        printType: DepartmentTypeEnum.printKitchen,
        isForThisDevice: false,
      );

      await Future.wait([
        insert(newSaleModel),
        ...newListSaleItems.map(
          (e) => _localSaleItemRepository.insert(e, true),
        ),
        ...newListSM.map((e) => _localSaleModifierRepository.insert(e, true)),
        ...newListSMO.map(
          (e) => _localSaleModifierOptionRepository.insert(e, true),
        ),
        _localPredefinedOrderRepository.makeIsOccupied(openOrder.id!),
      ]);

      prints('KOSONGKAN SEMUA');

      CustomerModel? customerModel = _ref.read(customerProvider).orderCustomer;

      // update table to notifier
      await _ref
          .read(tableLayoutProvider.notifier)
          .updateTableById(
            tableModel.id ?? '',
            saleId: newSaleModel.id,
            status: TableStatusEnum.OCCUPIED,
            staffId: newSaleModel.staffId,
            predefinedOrderId: predefinedOrderId,
            customerId: customerModel?.id,
          );

      if (printToKitchen) {
        if (onSuccess != null) {
          onSuccess(newSaleModel);
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Attempt print kitchen
  Future<void> attemptPrintKitchen({
    required Function(List<PrintReceiptCacheModel>) onSuccessPrintReceiptCache,
  }) async {
    try {
      final printerSettingNotifier = _ref.read(printerSettingProvider.notifier);
      final printCacheNotifier = _ref.read(printReceiptCacheProvider.notifier);

      PrintReceiptCacheModel prcModel = PrintReceiptCacheModel();

      // print kitchen
      await printerSettingNotifier.onHandlePrintVoidAndKitchen(
        departmentType: null,
        onSuccessPrintReceiptCache: (listPRC) {
          onSuccessPrintReceiptCache(listPRC);

          // to handle print error because we also pass the callback when onError
          // why first? because we only have one prc when print kitchen
          if (listPRC.isNotEmpty) {
            prcModel = listPRC.first;
          }
        },
        onSuccess: () {},
        onError: (message, ipAddress) {
          prints('MESSAGE PRINT KITCHEN: $message');
          prints('IP ADDRESS PRINT KITCHEN: $ipAddress');
          if (message == '-1') {
            return;
          }

          /// [CLIENT TANAK SHOW BILA ADA ERROR]
          /// [CLIENT KATA NAK ADA BALIK] 5 december 2025 guna mulut
          final globalContext = navigatorKey.currentContext;
          if (globalContext == null) {
            return;
          }
          CustomDialog.show(
            globalContext,
            dialogType: DialogType.danger,
            icon: FontAwesomeIcons.print,
            title: message,
            description:
                "${'pleaseCheckYourPrinterWithIP'.tr()} $ipAddress \n ${'doYouWantToPrintAgain'.tr()}",
            btnCancelText: 'cancel'.tr(),
            btnCancelOnPress: () {
              NavigationUtils.pop(globalContext);
            },
            btnOkText: 'printAgain'.tr(),
            btnOkOnPress: () async {
              // close error dialogue
              NavigationUtils.pop(globalContext);

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
                    prcModel.printData?.orderOptionModel ?? OrderOptionModel();
                PredefinedOrderModel predefinedOrderModel =
                    prcModel.printData?.predefinedOrderModel ??
                    PredefinedOrderModel();

                await printCacheNotifier.insertDetailsPrintCache(
                  saleModel: modelSale,
                  listSaleItemModel: listSI,
                  listSM: listSM,
                  listSMO: listSMO,
                  orderOptionModel: orderOptionModel,
                  pom: predefinedOrderModel,
                  printType: DepartmentTypeEnum.printKitchen,
                  isForThisDevice: true,
                );

                // use back this function
                await attemptPrintKitchen(
                  onSuccessPrintReceiptCache: onSuccessPrintReceiptCache,
                );
              } else {
                ThemeSnackBar.showSnackBar(
                  navigatorKey.currentContext!,
                  "Please open the order and reprint the order.",
                );
              }
            },
          );
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Handle open order dialogue
  Future<void> handleOpenOrder(BuildContext context) async {
    try {
      final saleItemsNotifier = _ref.read(saleItemProvider.notifier);
      final dialogueNavNotifier = _ref.read(dialogNavigatorProvider.notifier);

      // handle open order
      dialogueNavNotifier.setPageIndex(DialogNavigatorEnum.openOrder);
      // remove checkmark in open order - defer to avoid updating disposed widgets
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          saleItemsNotifier.deselectAll();
        } catch (e) {
          // Prevent crashes if widget is disposed
          prints('Error deselecting all items: $e');
        }
      });

      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext contextDialogue) {
          return OpenAndMoveOrderDialogue(
            isLoading: (isLoading) {
              if (isLoading) {
                LoadingDialog.show(contextDialogue);
              } else {
                LoadingDialog.hide(contextDialogue);
              }
            },
            dataMap: (data) async {
              List<SaleItemModel> listSaleItem =
                  data['listSaleItem'] as List<SaleItemModel>;
              List<SaleModifierModel> filteredSM =
                  data['filteredSM'] as List<SaleModifierModel>;
              List<Map<String, dynamic>> listTotalAfterDiscountAndTax =
                  data['listTotalAfterDiscountAndTax']
                      as List<Map<String, dynamic>>;

              List<Map<String, dynamic>> listTotalDiscount =
                  data['listTotalDiscount'] as List<Map<String, dynamic>>;

              List<Map<String, dynamic>> listTaxAfterDiscount =
                  data['listTaxAfterDiscount'] as List<Map<String, dynamic>>;

              List<Map<String, dynamic>> listTaxIncludedAfterDiscount =
                  data['listTaxIncludedAfterDiscount']
                      as List<Map<String, dynamic>>;

              List<Map<String, dynamic>> listCustomVariant =
                  data['listCustomVariant'] as List<Map<String, dynamic>>;

              List<SaleModifierOptionModel> filteredSMO =
                  data['filteredSMO'] as List<SaleModifierOptionModel>;

              TableModel tableModel = data['tableModel'] as TableModel;

              if (tableModel.id != null) {
                saleItemsNotifier.setSelectedTable(tableModel);
              }

              saleItemsNotifier.setSaleItems(listSaleItem);
              saleItemsNotifier.setSaleModifiers(filteredSM);

              saleItemsNotifier.setListTotalAfterDiscountAndTax(
                listTotalAfterDiscountAndTax,
              );

              saleItemsNotifier.setListTaxAfterDiscount(listTaxAfterDiscount);
              saleItemsNotifier.setListTaxIncludedAfterDiscount(
                listTaxIncludedAfterDiscount,
              );
              saleItemsNotifier.setListTotalDiscount(listTotalDiscount);

              saleItemsNotifier.setListCustomVariant(listCustomVariant);

              saleItemsNotifier.setSaleModifierOptions(filteredSMO);

              // calculate all
              saleItemsNotifier.calcTotalAfterDiscountAndTax();
              saleItemsNotifier.calcTaxAfterDiscount();
              saleItemsNotifier.calcTotalDiscount();
              saleItemsNotifier.calcTaxIncludedAfterDiscount();

              /// [SHOW SECOND DISPLAY] - Optimized with caching approach
              await _showOptimizedSecondDisplayForOpenOrder(saleItemsNotifier);
            },
          );
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Handle edit order
  Future<void> handleEditOrder({
    required PredefinedOrderModel updatedPOM,
    required Function() onSuccess,
    required Function(String errorMessage) onError,
  }) async {
    try {
      final saleItemsNotifier = _ref.read(saleItemProvider.notifier);
      final saleItemsState = _ref.read(saleItemProvider);

      // change the current pom in the saleItemsNotifier to updatedPOM
      saleItemsNotifier.setPredefinedOrderModel(updatedPOM);

      // get the current sale model from notifier
      SaleModel currentSaleModel = saleItemsState.currSaleModel!;
      if (currentSaleModel.id != null) {
        // change 'name' in sale model to updatedPOM.name
        SaleModel updatedSaleModel = currentSaleModel.copyWith(
          name: updatedPOM.name,
          remarks: updatedPOM.remarks,
        );
        // update the sale model
        await update(updatedSaleModel);
        // update the sale model in the saleItemsNotifier
        saleItemsNotifier.setCurrSaleModel(updatedSaleModel);

        onSuccess();
        return;
      } else {
        onError('error'.tr());
        return;
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Delete selected orders
  Future<void> deleteSelectedOrders(
    SaleModel sale, {
    required Function() onSuccess,
  }) async {
    try {
      final dlsNotifier = _ref.read(deletedSaleItemProvider.notifier);
      final saleItemNotifier = _ref.read(saleItemProvider.notifier);
      final saleModifierOptionNotifier = _ref.read(
        saleModifierOptionProvider.notifier,
      );
      final saleModifierNotifier = _ref.read(saleModifierProvider.notifier);

      await dlsNotifier.createAndInsertDeletedSaleItemModel(saleModel: sale);

      // reset current sale model
      saleItemNotifier.setCurrSaleModel(SaleModel());

      for (SaleModel saleModel in [sale]) {
        // get predefined order model
        PredefinedOrderModel? predefinedOrderModel =
            await _localPredefinedOrderRepository.getPredefinedOrderById(
              saleModel.predefinedOrderId,
            );

        if (predefinedOrderModel != null) {
          if (predefinedOrderModel.isCustom! &&
              predefinedOrderModel.isOccupied != null) {
            prints('Deleting custom saved sale');
            bool isDeleteSMO = await saleModifierOptionNotifier
                .softDeleteSaleModifierOptionsByPredefinedOrderId(
                  saleModel.predefinedOrderId!,
                );

            prints('is Delete SMO $isDeleteSMO');
            if (isDeleteSMO) {
              bool isDeleteSM = await saleModifierNotifier
                  .softDeleteSMsByPredefinedOrderId(
                    saleModel.predefinedOrderId!,
                  );
              prints('is Delete SM $isDeleteSM');
              if (isDeleteSM && isDeleteSMO) {
                await saleItemNotifier.deleteSaleItemWhereSaleId(saleModel.id!);
              }
            }
            //detach from table
            if (saleModel.tableId != null) {
              await _ref
                  .read(tableLayoutProvider.notifier)
                  .resetTableById(
                    saleModel.tableId!,
                    // true sebab custom
                    clearOpenOrder: true,
                  );
            }
            await saleItemNotifier.deleteSaleItemWhereSaleId(saleModel.id!);
            await _localPredefinedOrderRepository.delete(
              saleModel.predefinedOrderId!,
              true,
            );
            await delete(saleModel.id!);
          } else {
            // undo restore
            prints('undo restore');
            bool isDeleteSMO = await saleModifierOptionNotifier
                .softDeleteSaleModifierOptionsByPredefinedOrderId(
                  saleModel.predefinedOrderId!,
                );

            prints('is Delete SMO $isDeleteSMO');
            if (isDeleteSMO) {
              bool isDeleteSM = await saleModifierNotifier
                  .softDeleteSMsByPredefinedOrderId(
                    saleModel.predefinedOrderId!,
                  );
              prints('is Delete SM $isDeleteSM');
              if (isDeleteSM && isDeleteSMO) {
                await saleItemNotifier.deleteSaleItemWhereSaleId(saleModel.id!);
              }
            }
            //detach from table
            if (saleModel.tableId != null) {
              await _ref
                  .read(tableLayoutProvider.notifier)
                  .resetTableById(saleModel.tableId!, clearOpenOrder: false);
            }
            bool successDelete = await saleItemNotifier
                .deleteSaleItemWhereSaleId(saleModel.id!);
            prints('success delete $successDelete');
            await _localPredefinedOrderRepository.unOccupied(
              saleModel.predefinedOrderId!,
            );
            await delete(saleModel.id!);
          }
        }
      }

      onSuccess();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Print void for selected deleted orders
  Future<void> printVoidForSelectedDeletedOrders({
    required Function(SaleModel) onSuccess,
    required Function(String, String, SaleModel) onError,
  }) async {
    try {
      List<SaleModel> listSaleModelWantToUpdate = [];
      final printReceiptCacheNotifier = _ref.read(
        printReceiptCacheProvider.notifier,
      );
      final printerSettingNotifier = _ref.read(printerSettingProvider.notifier);
      final inventoryNotifier = _ref.read(inventoryProvider.notifier);
      final saleItemsState = _ref.read(saleItemProvider);
      final currentSaleModel = saleItemsState.currSaleModel;

      List<SaleModel> listSelectedOrders = saleItemsState.selectedOpenOrders;
      if (listSelectedOrders.isNotEmpty) {
        // if select open orders from checkbox, thats why use list
        listSaleModelWantToUpdate = listSelectedOrders;
      } else {
        if (currentSaleModel?.id != null) {
          // is open that orders, so we use current sale model
          listSaleModelWantToUpdate = [currentSaleModel!];
        }
      }

      for (SaleModel saleModel in listSaleModelWantToUpdate) {
        if (saleModel.id == null) continue;

        // get list sale items model by sale id
        List<SaleItemModel> existingSaleItemsInDB =
            await _localSaleItemRepository.getListSaleItemBasedOnSaleId(
              saleModel.id!,
            );
        List<SaleModifierModel> existingSaleModifiers =
            await _localSaleModifierRepository.getListSaleModifierModelBySaleId(
              saleModel.id!,
            );
        List<SaleModifierOptionModel> existingSaleModifierOptions =
            await _localSaleModifierOptionRepository
                .getListSaleModifierOptionModelBySaleId(saleModel.id!);

        OrderOptionModel? orderOptionModel = await _localOrderOptionRepository
            .getOrderOptionModelById(saleModel.orderOptionId ?? '');

        PredefinedOrderModel? predefinedOrderModel =
            await _localPredefinedOrderRepository.getPredefinedOrderById(
              saleModel.predefinedOrderId,
            );

        // use list not voided to update inventory
        List<SaleItemModel> listSINotVoided =
            existingSaleItemsInDB.where((si) => si.isVoided == false).toList();

        await inventoryNotifier.updateInventoryInSaleItem(
          listSINotVoided,
          InventoryTransactionTypeEnum.stockIn,
        );

        // check if all sale items are voided printed
        bool isAllVoided = true;
        for (SaleItemModel saleItemModel in existingSaleItemsInDB) {
          if (saleItemModel.isVoided != true) {
            isAllVoided = false;
            break;
          }
        }

        if (isAllVoided) {
          // ignore printing
          onSuccess(saleModel);
          continue; // continue to next sale model
        } else {
          // update all sale items to void
          final updatedSaleItems =
              existingSaleItemsInDB.map((si) {
                return si.copyWith(isVoided: true);
              }).toList();

          await printReceiptCacheNotifier.insertDetailsPrintCache(
            saleModel: saleModel,
            listSaleItemModel: updatedSaleItems,
            listSM: existingSaleModifiers,
            listSMO: existingSaleModifierOptions,
            pom: predefinedOrderModel ?? PredefinedOrderModel(),
            orderOptionModel: orderOptionModel ?? OrderOptionModel(),
            printType: DepartmentTypeEnum.printVoid,
            isForThisDevice: true,
          );

          /// [print void receipt]
          await printerSettingNotifier.onHandlePrintVoidAndKitchen(
            departmentType: DepartmentTypeEnum.printVoid,
            onSuccess: () {
              onSuccess(saleModel);
            },
            onError: (message, ip) {
              onError(message, ip, saleModel);
            },
            onSuccessPrintReceiptCache: (listPRC) {
              onSuccess(saleModel);
            },
          );

          await printReceiptCacheNotifier.insertDetailsPrintCache(
            saleModel: saleModel,
            listSaleItemModel: updatedSaleItems,
            listSM: existingSaleModifiers,
            listSMO: existingSaleModifierOptions,
            pom: predefinedOrderModel ?? PredefinedOrderModel(),
            orderOptionModel: orderOptionModel ?? OrderOptionModel(),
            printType: DepartmentTypeEnum.printVoid,
            isForThisDevice: false,
          );

          // add delay to avoid conflict for printer to printing the receipt
          await Future.delayed(Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Assign order to user
  Future<void> onAssignOrder(
    SaleModel currSaleModel,
    UserModel userAssigned,
  ) async {
    try {
      final saleItemNotifier = _ref.read(saleItemProvider.notifier);
      final customerNotifier = _ref.read(customerProvider.notifier);
      final staffNotifier = _ref.read(staffProvider.notifier);

      saleItemNotifier.removeAllSaleItems();
      saleItemNotifier.setPredefinedOrderModel(PredefinedOrderModel());
      // reset selected table
      saleItemNotifier.setSelectedTable(TableModel());
      // reset current sale model
      saleItemNotifier.setCurrSaleModel(SaleModel());
      // reset predefined order model
      saleItemNotifier.setPredefinedOrderModel(PredefinedOrderModel());
      customerNotifier.setOrderCustomerModel(null);

      // get staff model from user id
      StaffModel? staffModel = await staffNotifier.getStaffModelByUserId(
        userAssigned.id?.toString() ?? '-1',
      );

      SaleModel udpatedSaleModel = currSaleModel.copyWith(
        staffId: staffModel!.id,
      );

      await update(udpatedSaleModel);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Assign order to table
  Future<void> assignOrderToThatTable({
    required SaleModel incomingSaleModel,
    required TableModel incomingTableModel,
    required Function() onSuccess,
    required Function(String message) onError,
  }) async {
    if (incomingTableModel.id == null) {
      onError('Table not found. Please contact support.');
      return;
    }

    if (incomingSaleModel.id == null) {
      onError('Sale not found. Please contact support.');
      return;
    }

    if (incomingSaleModel.predefinedOrderId == null ||
        incomingSaleModel.predefinedOrderId!.isEmpty) {
      onError('Predefined Order not found. Please contact support.');
      return;
    }

    try {
      // update table model
      CustomerModel? customerModel =
          _ref.read(customerProvider).currentCustomer;

      if (incomingTableModel.id != null) {
        if (incomingTableModel.predefinedOrderId != null &&
            incomingTableModel.predefinedOrderId!.isNotEmpty) {
          PredefinedOrderModel? po = await _localPredefinedOrderRepository
              .getPredefinedOrderById(incomingTableModel.predefinedOrderId);

          // assign null to tableId and tableName of previous predefined in that incoming table
          if (po != null && po.id != null) {
            po.tableId = null;
            po.tableName = null;
            await _localPredefinedOrderRepository.update(po, true);
          }
        }

        await _ref
            .read(tableLayoutProvider.notifier)
            .updateTableById(
              incomingTableModel.id!,
              status: TableStatusEnum.OCCUPIED,
              saleId: incomingSaleModel.id,
              staffId: incomingSaleModel.staffId,
              customerId: customerModel?.id,
              predefinedOrderId: incomingSaleModel.predefinedOrderId,
            );
      }

      // update sale model
      if (incomingSaleModel.id != null) {
        SaleModel updatedSaleModel = incomingSaleModel.copyWith(
          tableId: incomingTableModel.id,
          tableName: incomingTableModel.name,
        );

        await update(updatedSaleModel);

        if (incomingSaleModel.predefinedOrderId != null &&
            incomingSaleModel.predefinedOrderId!.isNotEmpty) {
          PredefinedOrderModel? po = await _localPredefinedOrderRepository
              .getPredefinedOrderById(incomingSaleModel.predefinedOrderId);

          if (po != null && po.id != null) {
            PredefinedOrderModel updatedPO = po.copyWith(
              tableId: incomingTableModel.id,
              tableName: incomingTableModel.name,
            );

            await _localPredefinedOrderRepository.update(updatedPO, true);
          }
        }

        if (incomingSaleModel.tableId != null) {
          // reset current table in that sale if user want to change table
          await _ref
              .read(tableLayoutProvider.notifier)
              .resetTableById(incomingSaleModel.tableId!, clearOpenOrder: true);
        }
      }

      onSuccess();
      return;
    } catch (e) {
      onError("$e. Please contact support.");
      return;
    }
  }

  // ============================================================
  // Private Helper Methods
  // ============================================================

  /// Optimized method to show second display for open order using caching approach
  Future<void> _showOptimizedSecondDisplayForOpenOrder(
    dynamic saleItemsNotifier,
  ) async {
    try {
      UserModel userModel = GetIt.instance<UserModel>();

      // Use cached slideshow model from MenuItem if available to avoid DB calls
      SlideshowModel? currSdModel;

      // Try to get cached slideshow from MenuItem first
      if (MenuItem.isCacheInitialized()) {
        // Use the same caching approach as MenuItem
        final cachedData = MenuItem.getCachedCommonData();
        if (cachedData.containsKey(DataEnum.slideshow)) {
          try {
            currSdModel = SlideshowModel.fromJson(
              cachedData[DataEnum.slideshow],
            );
          } catch (e) {
            prints(
              '⚠️ Error parsing cached slideshow, falling back to DB call: $e',
            );
            currSdModel = null;
          }
        }
      }

      // If no cached slideshow available, fallback to DB call
      if (currSdModel == null) {
        prints('⚠️ Slideshow cache not available, falling back to DB call');
        final slideshowNotifier = _ref.read(slideshowProvider.notifier);
        final Map<String, dynamic> slideshowMap =
            await slideshowNotifier.getLatestModel();
        currSdModel = slideshowMap[DbResponseEnum.data];
      } else {
        prints('✅ Using cached slideshow model for open order second display');
      }

      // Get the base data from sale items notifier
      Map<String, dynamic> dataToTransfer =
          saleItemsNotifier.getMapDataToTransfer();

      // Create optimized data package with cached common data
      Map<String, dynamic> optimizedData = {
        DataEnum.userModel: userModel.toJson(),
        DataEnum.slideshow: currSdModel?.toJson() ?? {},
        DataEnum.showThankYou: false,
        DataEnum.isCharged: false,
        // Add unique update ID to track this update
        DataEnum.cartUpdateId: IdUtils.generateUUID(),
      };

      // Add the sale items data
      dataToTransfer.forEach((key, value) {
        if (!optimizedData.containsKey(key)) {
          optimizedData[key] = value;
        }
      });

      // Use cached common data from MenuItem if available
      if (MenuItem.isCacheInitialized()) {
        final cachedCommonData = MenuItem.getCachedCommonData();
        cachedCommonData.forEach((key, value) {
          if (!optimizedData.containsKey(key)) {
            optimizedData[key] = value;
          }
        });
        prints('✅ Using MenuItem cached common data for open order');
      }

      // Use optimized second display update
      await _updateSecondaryDisplayOptimized(optimizedData);
    } catch (e) {
      prints('❌ Error in optimized second display for open order: $e');
      // Fallback to original implementation if optimization fails
      await _fallbackSecondDisplayForOpenOrder(saleItemsNotifier);
    }
  }

  /// Optimized method to update the second display without full navigation
  Future<void> _updateSecondaryDisplayOptimized(
    Map<String, dynamic> data,
  ) async {
    try {
      // Check if we need to navigate to a new screen or just update the current one
      final secondDisplayNotifier = ServiceLocator.get<SecondDisplayNotifier>();
      final String currRouteName = secondDisplayNotifier.getCurrentRouteName;
      final SecondaryDisplayService showSecondaryDisplayFacade =
          ServiceLocator.get<SecondaryDisplayService>();

      if (currRouteName != CustomerShowReceipt.routeName) {
        // If we're not already on the receipt screen, do a full navigation
        prints('🔄 Full navigation to second display for open order');
        await showSecondaryDisplayFacade.navigateSecondScreen(
          CustomerShowReceipt.routeName,
          displayManager,
          data: data,
          isShowLoading: true,
        );
      } else {
        // If we're already on the receipt screen, use the optimized update method
        prints('⚡ Optimized update to second display for open order');
        try {
          await showSecondaryDisplayFacade.updateSecondaryDisplay(
            displayManager,
            data,
          );
        } catch (e) {
          prints(
            'Error updating second display, falling back to navigation: $e',
          );
          // Fall back to full navigation if the update fails
          await showSecondaryDisplayFacade.navigateSecondScreen(
            CustomerShowReceipt.routeName,
            displayManager,
            data: data,
            isShowLoading: true,
          );
        }
      }
    } catch (e) {
      prints('❌ Error in optimized second display update: $e');
      rethrow;
    }
  }

  /// Fallback method using original implementation
  Future<void> _fallbackSecondDisplayForOpenOrder(
    dynamic saleItemsNotifier,
  ) async {
    try {
      prints('🔄 Using fallback second display implementation for open order');

      UserModel userModel = GetIt.instance<UserModel>();
      // to get current slideshow model
      final slideshowNotifier = _ref.read(slideshowProvider.notifier);
      final Map<String, dynamic> slideshowMap =
          await slideshowNotifier.getLatestModel();
      final SlideshowModel? currSdModel = slideshowMap[DbResponseEnum.data];
      final SecondaryDisplayService showSecondaryDisplayFacade =
          ServiceLocator.get<SecondaryDisplayService>();

      Map<String, dynamic> dataToTransfer =
          saleItemsNotifier.getMapDataToTransfer();
      dataToTransfer.addEntries([
        MapEntry(DataEnum.userModel, userModel.toJson()),
        MapEntry(DataEnum.slideshow, currSdModel?.toJson() ?? {}),
        const MapEntry(DataEnum.showThankYou, false),
        const MapEntry(DataEnum.isCharged, false),
      ]);

      await showSecondaryDisplayFacade.navigateSecondScreen(
        CustomerShowReceipt.routeName,
        displayManager,
        data: dataToTransfer,
      );
    } catch (e) {
      prints('❌ Error in fallback second display: $e');
      rethrow;
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get list of sales from state (old notifier getter)
  List<SaleModel> get getListSales => state.items;

  /// Delete bulk sales from local and database
  Future<void> deleteBulkFromLocalAndDBList(List<SaleModel> list) async {
    final saleNotifier = _ref.read(saleProvider.notifier);

    // Remove from state
    final updatedItems =
        state.items.where((sale) => !list.contains(sale)).toList();
    state = state.copyWith(items: updatedItems);

    // Delete from database
    for (SaleModel saleModel in list) {
      await saleNotifier.delete(saleModel.id!);
    }
  }

  Future<List<SaleModel>> syncFromRemote() async {
    List<SaleModel> allSales = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching sales page $currentPage');
      SaleListResponseModel responseModel = await _webService.get(
        _remoteRepository.getListSaleWithPagination(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Add sales from current page to the list
        allSales.addAll(responseModel.data!);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination SALE: current page=$currentPage, last page=$lastPage, total sales=${responseModel.paginator!.total}',
          );
        } else {
          // If no paginator info, assume we're done
          break;
        }

        // Move to next page
        currentPage++;
      } else {
        // If request failed, stop pagination
        prints(
          'Failed to fetch sales page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints('Fetched a total of ${allSales.length} sales from all pages');
    return allSales;
  }

  Future<List<SaleModel>> getSaleModelBasedOnCurrentUserAndChargedAt(
    BuildContext context,
  ) async {
    List<SaleModel> listSaleModel = [];
    // get staff based on user id

    // get sale model based on staff id
    // buang staff id sebab tak perlu filter by staff id
    listSaleModel = await getListSalesBasedOnStaffIdChargedAt();

    // listSaleModel = listSaleModel.where((saleModel) {
    //   return listPO.any((po) =>
    //       po.id == saleModel.predefinedOrderId && po.name == saleModel.name);
    // }).toList();

    return listSaleModel;
  }
}

/// Provider for sorted items (computed provider)
final sortedSalesProvider = Provider<List<SaleModel>>((ref) {
  final items = ref.watch(saleProvider).items;
  final sorted = List<SaleModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)),
  );
  return sorted;
});

/// Provider for sale domain
final saleProvider = StateNotifierProvider<SaleNotifier, SaleState>((ref) {
  return SaleNotifier(
    ref,
    localRepository: ServiceLocator.get<LocalSaleRepository>(),
    localSaleItemRepository: ServiceLocator.get<LocalSaleItemRepository>(),
    localSaleModifierRepository:
        ServiceLocator.get<LocalSaleModifierRepository>(),
    localSaleModifierOptionRepository:
        ServiceLocator.get<LocalSaleModifierOptionRepository>(),
    localPredefinedOrderRepository:
        ServiceLocator.get<LocalPredefinedOrderRepository>(),
    localOrderOptionRepository:
        ServiceLocator.get<LocalOrderOptionRepository>(),
    remoteRepository: ServiceLocator.get<SaleRepository>(),
    webService: ServiceLocator.get<IWebService>(),
  );
});

/// Provider for sale by ID (family provider for indexed lookups)
final saleByIdProvider = FutureProvider.family<SaleModel?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(saleProvider.notifier);
  return notifier.getSaleModelById(id);
});
