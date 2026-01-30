import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/enum/department_type_enum.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/core/enum/table_status_enum.dart';
import 'package:mts/core/enums/inventory_transaction_type_enum.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_list_response_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/domain/repositories/local/predefined_order_repository.dart';
import 'package:mts/main.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/providers/customer/customer_providers.dart';
import 'package:mts/providers/error_log/error_log_providers.dart';
import 'package:mts/providers/inventory/inventory_providers.dart';
import 'package:mts/providers/outlet/outlet_providers.dart';
import 'package:mts/providers/print_receipt_cache/print_receipt_cache_providers.dart';
import 'package:mts/providers/sale_modifier/sale_modifier_providers.dart';
import 'package:mts/providers/sale_modifier_option/sale_modifier_option_providers.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';

import 'package:mts/providers/dialog_navigator/dialog_navigator_providers.dart';
import 'package:mts/providers/predefined_order/predefined_order_state.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';
import 'package:mts/providers/sale/sale_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/sale_item/sale_item_state.dart';
import 'package:mts/providers/staff/staff_providers.dart';
import 'package:mts/providers/table_layout/table_layout_providers.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/domain/repositories/local/sale_item_repository.dart';
import 'package:mts/domain/repositories/remote/predefined_order_repository.dart';

/// StateNotifier for PredefinedOrder domain
///
/// Migrated from: predefined_order_facade_impl.dart
class PredefinedOrderNotifier extends StateNotifier<PredefinedOrderState> {
  final LocalPredefinedOrderRepository _localRepository;
  final LocalSaleItemRepository _localSaleItemRepository;
  final PredefinedOrderRepository _remoteRepository;
  final IWebService _webService;
  final Ref _ref;

  PredefinedOrderNotifier({
    required LocalPredefinedOrderRepository localRepository,
    required LocalSaleItemRepository localSaleItemRepository,
    required PredefinedOrderRepository remoteRepository,
    required IWebService webService,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _localSaleItemRepository = localSaleItemRepository,
       _webService = webService,
       _ref = ref,
       super(const PredefinedOrderState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<PredefinedOrderModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final updatedItems = [...state.items, ...list];
        state = state.copyWith(items: updatedItems);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Get all items from local storage
  Future<List<PredefinedOrderModel>> getListPredefinedOrder() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListPredefinedOrder();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<PredefinedOrderModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        final idsToDelete = list.map((e) => e.id).toSet();
        final updatedItems =
            state.items.where((e) => !idsToDelete.contains(e.id)).toList();
        state = state.copyWith(items: updatedItems);
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
        final updatedItems = state.items.where((e) => e.id != id).toList();
        state = state.copyWith(items: updatedItems);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Find an item by its ID
  Future<PredefinedOrderModel?> getPredefinedOrderModelById(
    String itemId,
  ) async {
    try {
      final items = await _localRepository.getListPredefinedOrder();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => PredefinedOrderModel(),
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
    List<PredefinedOrderModel> newData, {
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
    List<PredefinedOrderModel> list, {
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
        // Merge upserted items with existing items
        final existingItems = List<PredefinedOrderModel>.from(state.items);
        for (final item in list) {
          final index = existingItems.indexWhere((e) => e.id == item.id);
          if (index >= 0) {
            existingItems[index] = item;
          } else {
            existingItems.add(item);
          }
        }
        state = state.copyWith(items: existingItems);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Insert or update a single item
  Future<int> insert(
    PredefinedOrderModel predefinedOrderModel, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(
        predefinedOrderModel,
        isInsertToPending,
      );

      if (result > 0) {
        final updatedItems = [...state.items, predefinedOrderModel];
        state = state.copyWith(items: updatedItems);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Update an existing item
  Future<int> update(
    PredefinedOrderModel predefinedOrderModel, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.update(
        predefinedOrderModel,
        isInsertToPending,
      );

      if (result > 0) {
        final updatedItems =
            state.items.map((item) {
              return item.id == predefinedOrderModel.id
                  ? predefinedOrderModel
                  : item;
            }).toList();
        state = state.copyWith(items: updatedItems);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Refresh items from repository (explicit reload)
  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListPredefinedOrder();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Mark predefined order as occupied
  Future<bool> makeIsOccupied(String idModel) async {
    try {
      final result = await _localRepository.makeIsOccupied(idModel);
      if (result) {
        final updatedItems =
            state.items.map((item) {
              return item.id == idModel
                  ? item.copyWith(isOccupied: true)
                  : item;
            }).toList();
        state = state.copyWith(items: updatedItems);
      }
      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Attempt to print kitchen orders via facade
  Future<void> attemptPrintKitchen({
    required Function(String message) onError,
    required bool isPrintAgain,
    required bool isFromLocal,
    required Function(List<PrintReceiptCacheModel> listPRC)
    onSuccessPrintReceiptCache,
  }) async {
    // print kitchen
    await _ref
        .read(printerSettingProvider.notifier)
        .onHandlePrintVoidAndKitchen(
          departmentType: DepartmentTypeEnum.printKitchen,
          onSuccessPrintReceiptCache: onSuccessPrintReceiptCache,
          onSuccess: () {
            prints('SUCCESS PRINT CUSTOM ORDER TO DEPARTMENT PRINTER');
          },
          onError: (message, ipAddress) {
            if (message != '-1') {
              prints(
                '😈😈😈😈😈😈😈😈😈😈 $ipAddress PRINT SAVED CUSTOM ORDER INTO PREDEFINED FAILEDD $message',
              );
              onError(ipAddress);
            } else {
              onError(message);
            }
            return;
          },
        );
  }

  /// Save order into custom predefined order
  Future<void> saveOrderIntoCustomPredefinedOrder(
    BuildContext context,
    PredefinedOrderModel predefinedOrderModel,
    SaleItemState saleItemsState, {
    required Function() onSuccess,
    required Function(String message) onError,
    required Function(List<PrintReceiptCacheModel> listPRC)
    onCallbackPrintReceiptCache,
  }) async {
    final saleNotifier = _ref.read(saleProvider.notifier);
    final saleItemNotifier = _ref.read(saleItemProvider.notifier);
    final inventoryNotifier = _ref.read(inventoryProvider.notifier);
    final saleModifierNotifier = _ref.read(saleModifierProvider.notifier);
    final saleModifierOptionNotifier = _ref.read(
      saleModifierOptionProvider.notifier,
    );
    final customerNotifier = _ref.read(customerProvider.notifier);
    final outletNotifier = _ref.read(outletProvider.notifier);
    final errorLogNotifier = _ref.read(errorLogProvider.notifier);
    final printCacheNotifier = _ref.read(printReceiptCacheProvider.notifier);

    // globalStopwatch.start();
    globalStopwatch2.start();

    // get total price
    double totalPrice = saleItemsState.totalAfterDiscountAndTax;
    // get staff model to get staff id
    UserModel userModel = ServiceLocator.get<UserModel>();

    if (predefinedOrderModel.id == null) {
      // rare case
      String message = "Predefined Order id is null, cannot save custom order";
      ThemeSnackBar.showSnackBar(context, message);
      errorLogNotifier.createAndInsertErrorLog(message);
      return;
    }

    if (userModel.id == null) {
      // rare case
      String message = "User id is null, cannot save custom order";
      ThemeSnackBar.showSnackBar(context, message);
      errorLogNotifier.createAndInsertErrorLog(message);
      return;
    }
    final staffNotifier = _ref.read(staffProvider.notifier);
    StaffModel? staffModel = await staffNotifier.getStaffModelByUserId(
      userModel.id!.toString(),
    );

    if (staffModel?.id == null) {
      // rare case
      String message = "Staff id is null, cannot save custom order";
      ThemeSnackBar.showSnackBar(context, message);
      errorLogNotifier.createAndInsertErrorLog(message);
      return;
    }

    if (staffModel?.userId != userModel.id) {
      // rare case
      String message = "Staff id is conflict, cannot save custom order";
      ThemeSnackBar.showSnackBar(context, message);
      errorLogNotifier.createAndInsertErrorLog(message);
      return;
    }

    // close kan dulu dialogue baru buat bende belakang
    // close custom predefined order dialogue
    NavigationUtils.pop(context);

    List<SaleItemModel> listSaleItems = saleItemsState.saleItems;
    List<SaleItemModel> newListSaleItems = [];
    List<SaleModel> newListSaleModels = [];

    List<SaleModifierModel> listSaleModifierModels =
        saleItemsState.saleModifiers;

    List<SaleModifierModel> newListSM = [];
    List<SaleModifierOptionModel> listSaleModifierOptionModels =
        saleItemsState.saleModifierOptions;

    List<SaleModifierOptionModel> newListSMO = [];
    String newSaleId = IdUtils.generateUUID();

    if (listSaleItems.isNotEmpty) {
      for (SaleItemModel saleItemModel in listSaleItems) {
        String newSaleItemId = IdUtils.generateUUID();

        // get the sale modifier list by sale item id to get the id
        List<SaleModifierModel> listSM =
            listSaleModifierModels
                .where((element) => element.saleItemId == saleItemModel.id)
                .toList();

        if (listSM.isNotEmpty) {
          for (SaleModifierModel currSM in listSM) {
            List<SaleModifierOptionModel> listSMO =
                listSaleModifierOptionModels
                    .where((element) => element.saleModifierId == currSM.id)
                    .toList();
            SaleModifierModel newSM = currSM.copyWith(
              saleItemId: newSaleItemId,
              saleModifierOptionCount: listSMO.length,
            );
            newListSM.add(newSM);
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

        SaleItemModel newSaleItemModel = saleItemModel.copyWith(
          id: newSaleItemId,
          saleId: newSaleId,
          isVoided: false,
          // isPrintedKitchen: false,
          // isPrintedVoided: false,
          saleModifierCount: listSM.length,
        );

        newListSaleItems.add(newSaleItemModel);
      }
    }

    // udpate running number
    int runningNumber = 1;
    await outletNotifier.incrementNextOrderNumber(
      onRunningNumber: (latestNumber) {
        runningNumber = latestNumber;
      },
    );

    // generate new sale model
    SaleModel newSaleModel = SaleModel(
      id: newSaleId,
      staffId: staffModel!.id,
      // saleItemIdsToPrint: saleItemIdToPrintJson,
      // saleItemIdsToPrintVoid: saleItemIdToPrintVoidedJson,
      saleItemCount: newListSaleItems.length,
      outletId: predefinedOrderModel.outletId,
      predefinedOrderId: predefinedOrderModel.id,
      name: predefinedOrderModel.name,
      remarks: predefinedOrderModel.remarks,
      runningNumber: runningNumber,
      totalPrice: double.parse(totalPrice.toStringAsFixed(2)),
      orderOptionId: saleItemsState.orderOptionModel?.id,
    );

    newListSaleModels.add(newSaleModel);

    final TableModel? currSelectedTable = saleItemsState.selectedTable;
    final CustomerModel? customerModel = customerNotifier.getOrderCustomerModel;

    // reset current attached customer
    customerNotifier.setOrderCustomerModel(null);
    globalStopwatch.start();
    // add to print cache
    await printCacheNotifier.insertDetailsPrintCache(
      saleModel: newSaleModel,
      listSaleItemModel: newListSaleItems,
      listSM: newListSM,
      listSMO: newListSMO,
      orderOptionModel:
          saleItemsState.orderOptionModel ?? OrderOptionModel(id: '', name: ''),
      pom: predefinedOrderModel,
      printType: DepartmentTypeEnum.printKitchen,
      isForThisDevice: true,
    );
    globalStopwatch.stop();
    prints(
      "insert details print cache: ${globalStopwatch.elapsedMilliseconds} ms",
    );

    /// [PRINT KITCHEN ORDER]
    /// [ONLY FOR PRINTER WITH DEPARTMENT]
    await attemptPrintKitchen(
      onError: onError,
      isPrintAgain: false,
      isFromLocal: true,
      onSuccessPrintReceiptCache: (listPRC) {
        onCallbackPrintReceiptCache(listPRC);
      },
    );
    globalStopwatch2.stop();
    prints("HABIS PRINT KITCHEN: ${globalStopwatch2.elapsedMilliseconds} ms");

    _ref
        .read(dialogNavigatorProvider.notifier)
        .setPageIndex(DialogNavigatorEnum.reset);

    /// [SHOW SECOND DISPLAY]
    // Don't await this call to prevent blocking the UI thread
    _ref.read(secondDisplayProvider.notifier).showMainCustomerDisplay();
    await printCacheNotifier.insertDetailsPrintCache(
      saleModel: newSaleModel,
      listSaleItemModel: newListSaleItems,
      listSM: newListSM,
      listSMO: newListSMO,
      orderOptionModel:
          saleItemsState.orderOptionModel ?? OrderOptionModel(id: '', name: ''),
      pom: predefinedOrderModel,
      printType: DepartmentTypeEnum.printKitchen,
      isForThisDevice: false,
    );

    // must insert sale model first before inserting sale item
    await saleNotifier.insert(newSaleModel);

    await Future.wait([
      ...newListSaleItems.map((e) => saleItemNotifier.insert(e)),
      ...newListSM.map((e) => saleModifierNotifier.insert(e)),
      ...newListSMO.map((e) => saleModifierOptionNotifier.insert(e)),
      // remove the selected predefined order
      // in this case, the predefined order just created, but need to softDelete so cannot be used again if have new sales
      makeIsOccupied(predefinedOrderModel.id!),
    ]); // update predefined order that occupied
    PredefinedOrderModel updatedPO = predefinedOrderModel.copyWith(
      isOccupied: true,
    );

    // update predefined order
    await update(updatedPO);
    // update table if have table
    // update customer id if have customer
    if (currSelectedTable?.id != null) {
      await _ref
          .read(tableLayoutProvider.notifier)
          .updateTableById(
            currSelectedTable!.id!.toString(),
            saleId: newSaleModel.id,
            status: TableStatusEnum.OCCUPIED,
            staffId: staffModel.id,
            predefinedOrderId: updatedPO.id,
            customerId: customerModel?.id,
          );
    }
    // operation for inventory
    await inventoryNotifier.updateInventoryInSaleItem(
      newListSaleItems,
      InventoryTransactionTypeEnum.stockOut,
    );
  }

  Future<bool> unOccupied(String idModel) async {
    return await _localRepository.unOccupied(idModel);
  }

  Future<void> handleMergeOrders(
    BuildContext context,
    // merge into this sale model
    SaleModel incomingSaleModel,
    List<SaleModel> selectedSaleModels,
  ) async {
    // dear future me, dont stress stress
    // the flow is we choose order 1 from open order, and we choose order 2 in move order body to merge to open order 2
    final incomingPredefinedOrderId = incomingSaleModel.predefinedOrderId;

    final saleItemsNotifier = _ref.read(saleItemProvider.notifier);
    PredefinedOrderModel? incomingPO = await getPredefinedOrderById(
      incomingPredefinedOrderId,
    );

    // get sale model.predefinedORderId that not same with predefined order id to be removed
    List<SaleModel> differentSaleModels =
        selectedSaleModels
            .where(
              (sale) => sale.predefinedOrderId != incomingPredefinedOrderId,
            )
            .toList();

    // get sum of totalPrice from differentSaleModels
    double sumOfTotalPrice = 0;
    for (SaleModel sm in differentSaleModels) {
      if (sm.totalPrice != null) {
        sumOfTotalPrice += sm.totalPrice!;
      }
    }

    // get list sale items based on differentSaleModels.id to change the saleId in the saleITem
    List<SaleItemModel> mergingListSI = await _ref
        .read(saleItemProvider.notifier)
        .getListSaleItemBySaleId(
          differentSaleModels.map((e) => e.id!).toList(),
        );

    // get the current list sale item to get for the saleItemCount calculation
    List<SaleItemModel> existingListSI = await _ref
        .read(saleItemProvider.notifier)
        .getListSaleItemBySaleId([incomingSaleModel.id!]);

    // get the differentTableId from differentSaleModels to be unoccupied and null the predefinedOrder and null the saleId
    // get only that have table id

    List<String> differentTableIds =
        selectedSaleModels
            .where(
              (element) =>
                  element.tableId != null &&
                  element.tableId != incomingSaleModel.tableId,
            )
            .map((e) => e.tableId!)
            .toList();

    List<SaleItemModel> newListSI = [];

    if (incomingSaleModel.id != null) {
      // delete the different sale models

      // process moving
      // move the sale item
      for (SaleItemModel saleItemModel in mergingListSI) {
        SaleItemModel updatedSI = saleItemModel.copyWith(
          saleId: incomingSaleModel.id,
        );

        newListSI.add(updatedSI);
      }

      // reset the table
      for (String tableId in differentTableIds) {
        await _ref
            .read(tableLayoutProvider.notifier)
            .resetTableById(tableId, clearOpenOrder: true);
      }
      // update sale item first then delete sale
      await Future.wait(
        newListSI.map((e) async => _localSaleItemRepository.update(e, true)),
      );

      await _ref.read(saleProvider.notifier).deleteBulk(differentSaleModels);
    } else {
      prints('soon sale model id is null');
      await LogUtils.error('ERROR in merge orders, soon sale model id is null');
    }

    // get list of POs to set the PO to occupied = 0
    if (incomingSaleModel.id != null) {
      List<String> poIds =
          differentSaleModels.map((e) => e.predefinedOrderId!).toList();
      // remove this id, so only the remaining ids will be occupied = 0

      List<PredefinedOrderModel> listPOs = [];

      for (String poId in poIds) {
        PredefinedOrderModel? po = await getPredefinedOrderById(poId);

        if (po != null) {
          listPOs.add(po);
        }
      }

      for (PredefinedOrderModel predefinedOrderModel in listPOs) {
        await unOccupied(predefinedOrderModel.id!);
      }
    } else {
      prints('soon sale model id is null cannot unoccupied');
    }

    List<SaleItemModel> mergedListSI = [...existingListSI, ...newListSI];

    String message = '';
    SaleModel newSaleModel = SaleModel();
    // get staff model to get staff id
    UserModel userModel = ServiceLocator.get<UserModel>();
    StaffModel? staffModel = await _ref
        .read(staffProvider.notifier)
        .getStaffModelByUserId(userModel.id!.toString());

    if (incomingSaleModel.id != null) {
      // update sale and table model
      newSaleModel = incomingSaleModel.copyWith(
        staffId: staffModel!.id,
        predefinedOrderId: incomingPO!.id,
        name: incomingPO.name,

        saleItemCount: mergedListSI.length,
        totalPrice: sumOfTotalPrice + incomingSaleModel.totalPrice!,
      );
      message = await _ref.read(saleProvider.notifier).update(newSaleModel);
    } else {
      prints('soon sale model id is null');
      await LogUtils.error('ERROR in merge orders, soon sale model id is null');
      message = 'soon sale model id is null';
    }
    // List<SaleModel> newListSaleAfterMerge = [];
    // for (SaleModel saleModel in selectedSaleModels) {
    //   SaleModel newSaleModel = saleModel.copyWith(
    //     predefinedOrderId: predefinedOrderId,
    //     name: po!.name,
    //   );
    //   newListSaleAfterMerge.add(newSaleModel);
    // }

    // so now you have a list of sale model after merge

    if (message == '') {
      // clear the selected POs
      saleItemsNotifier.clearSelections();

      Navigator.of(context).pop();
      _ref
          .read(dialogNavigatorProvider.notifier)
          .setPageIndex(DialogNavigatorEnum.reset);
    } else {
      await LogUtils.error('ERROR merge order: $message');
      CustomDialog.show(
        context,
        icon: FontAwesomeIcons.circleExclamation,
        title: 'errorMergeOrder'.tr(),
        description: 'errorMergeOrderDesc'.tr(args: [incomingPO?.name ?? '']),
        btnOkText: 'ok'.tr(),
        btnOkOnPress: () => NavigationUtils.pop(context),
      );
    }
  }

  Future<int> getLatestColumnOrder() async {
    return await _localRepository.getLatestColumnOrder();
  }

  Resource getPredefinedOrderList(String page) {
    return _remoteRepository.getPredefinedOrderListWithPagination(page);
  }

  Future<List<PredefinedOrderModel>> syncFromRemote() async {
    List<PredefinedOrderModel> allPredefinedOrders = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching predefined orders page $currentPage');
      PredefinedOrderListResponseModel responseModel = await _webService.get(
        getPredefinedOrderList(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Process predefined orders from current page
        List<PredefinedOrderModel> pagePredefinedOrders = responseModel.data!;

        // Add predefined orders from current page to the list
        allPredefinedOrders.addAll(pagePredefinedOrders);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination PREDEFINED ORDER: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch predefined orders page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allPredefinedOrders.length} predefined orders from all pages',
    );
    return allPredefinedOrders;
  }

  Future<List<PredefinedOrderModel>>
  getListPredefinedOrderWhereOccupied0() async {
    return await _localRepository.getListPredefinedOrderWhereOccupied0();
  }

  Future<List<PredefinedOrderModel>> getPredefinedOrderByIds(
    List<String?> listId,
  ) async {
    return await _localRepository.getPredefinedOrderByIds(listId);
  }

  Future<List<PredefinedOrderModel>>
  getListPredefinedOrderWhereOccupied1() async {
    return await _localRepository.getListPredefinedOrderWhereOccupied1();
  }

  Future<PredefinedOrderModel?> getPredefinedOrderById(
    String? idPredefined,
  ) async {
    return await _localRepository.getPredefinedOrderById(idPredefined);
  }

  Future<bool> clearTableReferenceByTableId(String targetTableId) {
    return _localRepository.clearTableReferenceByTableId(targetTableId);
  }

  Future<List<PredefinedOrderModel>> getListPoByTableIds(
    List<String> tableIds,
  ) {
    return _localRepository.getListPoByTableIds(tableIds);
  }

  Future<List<PredefinedOrderModel>> getCustomPoThatHaveTable() async {
    return _localRepository.getCustomPoThatHaveTable();
  }

  List<PredefinedOrderModel> getListPredefinedOrderFromHive() {
    return _localRepository.getListPredefinedOrderFromHive();
  }
}

/// Provider for sorted items (computed provider)
final sortedPredefinedOrdersProvider = Provider<List<PredefinedOrderModel>>((
  ref,
) {
  final items = ref.watch(predefinedOrderProvider).items;
  final sorted = List<PredefinedOrderModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for predefinedOrder domain
final predefinedOrderProvider =
    StateNotifierProvider<PredefinedOrderNotifier, PredefinedOrderState>((ref) {
      return PredefinedOrderNotifier(
        localRepository: ServiceLocator.get<LocalPredefinedOrderRepository>(),
        localSaleItemRepository: ServiceLocator.get<LocalSaleItemRepository>(),
        remoteRepository: ServiceLocator.get<PredefinedOrderRepository>(),
        webService: ServiceLocator.get<IWebService>(),
        ref: ref,
      );
    });

/// Provider for predefinedOrder by ID (family provider for indexed lookups)
final predefinedOrderByIdProvider =
    Provider.family<PredefinedOrderModel?, String>((ref, id) {
      final items = ref.watch(predefinedOrderProvider).items;
      try {
        return items.firstWhere((item) => item.id == id);
      } catch (e) {
        return null;
      }
    });

/// Provider for predefined orders by IDs
final predefinedOrdersByIdsProvider =
    FutureProvider.family<List<PredefinedOrderModel>, List<String?>>((
      ref,
      ids,
    ) async {
      final notifier = ref.read(predefinedOrderProvider.notifier);
      return notifier.getPredefinedOrderByIds(ids);
    });

/// Provider for predefined orders where occupied = 0 (available)
final predefinedOrdersWhereOccupied0Provider =
    FutureProvider<List<PredefinedOrderModel>>((ref) async {
      final notifier = ref.read(predefinedOrderProvider.notifier);
      return notifier.getListPredefinedOrderWhereOccupied0();
    });

/// Provider for predefined orders where occupied = 1 (occupied)
final predefinedOrdersWhereOccupied1Provider =
    FutureProvider<List<PredefinedOrderModel>>((ref) async {
      final notifier = ref.read(predefinedOrderProvider.notifier);
      return notifier.getListPredefinedOrderWhereOccupied1();
    });

/// Provider for predefined orders count
final predefinedOrdersCountProvider = Provider<int>((ref) {
  final items = ref.watch(predefinedOrderProvider).items;
  return items.length;
});

/// Provider for predefined orders from Hive (sync)
final predefinedOrdersFromHiveProvider = Provider<List<PredefinedOrderModel>>((
  ref,
) {
  final notifier = ref.read(predefinedOrderProvider.notifier);
  return notifier.getListPredefinedOrderFromHive();
});

/// Provider for custom PO that have table
final customPoThatHaveTableProvider =
    FutureProvider<List<PredefinedOrderModel>>((ref) async {
      final notifier = ref.read(predefinedOrderProvider.notifier);
      return notifier.getCustomPoThatHaveTable();
    });

/// Provider for latest column order
final latestColumnOrderProvider = FutureProvider<int>((ref) async {
  final notifier = ref.read(predefinedOrderProvider.notifier);
  return notifier.getLatestColumnOrder();
});
