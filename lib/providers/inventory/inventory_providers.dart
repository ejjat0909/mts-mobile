import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/data/models/inventory/inventory_model.dart';
import 'package:mts/domain/repositories/local/inventory_repository.dart';
import 'package:mts/domain/repositories/remote/inventory_repository.dart';
import 'package:mts/providers/inventory/inventory_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enums/inventory_transaction_type_enum.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/inventory/inventory_list_response_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/providers/inventory_transaction/inventory_transaction_providers.dart';

/// StateNotifier for Inventory domain
///
/// Migrated from: inventory_facade_impl.dart
class InventoryNotifier extends StateNotifier<InventoryState> {
  final LocalInventoryRepository _localRepository;
  final InventoryRepository _remoteRepository;
  final IWebService _webService;
  final Ref _ref;

  InventoryNotifier({
    required LocalInventoryRepository localRepository,
    required InventoryRepository remoteRepository,
    required IWebService webService,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _ref = ref,
       super(const InventoryState());

  /// Insert a single item into local storage
  Future<int> insert(
    InventoryModel model, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(
        model,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        final updatedItems = List<InventoryModel>.from(state.items)..add(model);
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

  /// Update a single item in local storage
  Future<int> update(
    InventoryModel model, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.update(
        model,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        final updatedItems =
            state.items.map((item) {
              return item.id == model.id ? model : item;
            }).toList();
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

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<InventoryModel> list, {
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
  Future<List<InventoryModel>> getListInventoryModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListInventoryModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<InventoryModel> list) async {
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
  Future<InventoryModel?> getInventoryModelById(String itemId) async {
    try {
      final items = await _localRepository.getListInventoryModel();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => InventoryModel(),
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
    List<InventoryModel> newData, {
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
    List<InventoryModel> list, {
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
        final existingItems = List<InventoryModel>.from(state.items);
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

  /// Refresh items from repository (explicit reload)
  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListInventoryModel();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get inventory list (old notifier getter)
  List<InventoryModel> get getInventoryList => state.items;

  Resource getInventoryListWithPagination(String page) {
    return _remoteRepository.getInventoryListWithPagination(page);
  }

  Future<List<InventoryModel>> syncFromRemote() async {
    List<InventoryModel> allInventories = [];
    int currentPage = 1;

    while (true) {
      InventoryListResponseModel responseModel = await _webService.get(
        _remoteRepository.getInventoryListWithPagination(
          currentPage.toString(),
        ),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        allInventories.addAll(responseModel.data!);

        // Check if there are more pages
        if (responseModel.data!.length < 100) {
          break; // Last page
        }

        currentPage++;
      } else {
        break;
      }
    }

    return allInventories;
  }

  List<InventoryModel> getListInventoryFromHive() {
    return _localRepository.getListInventoryFromHive();
  }

  Future<void> updateInventoryInSaleItem(
    List<SaleItemModel> newListSaleItems,
    int transactionTypeEnum, {
    Future<bool> Function()? onLowStock,
  }) async {
    StaffModel staffModel = ServiceLocator.get<StaffModel>();
    OutletModel outletModel = ServiceLocator.get<OutletModel>();
    PosDeviceModel posDeviceModel = ServiceLocator.get<PosDeviceModel>();

    await Future.wait(
      newListSaleItems.map((SaleItemModel saleItem) async {
        /// [PLEASE DONT DO UPDATE SALE ITEM HERE BECAUSE IT WILL CAUSE IS_PRINTED_KITCHEN BACK TO 0 AGAIN]
        // then update the inventory with the sale item details
        // get the inventory by inventoryId
        InventoryModel? invModel = await getInventoryModelById(
          saleItem.inventoryId ?? '-1',
        );
        if (invModel == null) return;

        // bool shouldProceed = true;
        // if (getCurrQty(invModel, saleItem, transactionTypeEnum) <= 0) {
        //   if (transactionTypeEnum == InventoryTransactionTypeEnum.OUT) {
        //     shouldProceed = await onLowStock?.call() ?? true;
        //   }
        // }

        // if (!shouldProceed) return;

        // update the inventory model
        await update(
          invModel.copyWith(
            currentQuantity: getCurrQty(
              invModel,
              saleItem,
              transactionTypeEnum,
            ),
            updatedById: staffModel.id!,
            updatedAt: DateTime.now(),
          ),
        );

        /// then create and insert inventory transaction
        await _ref
            .read(inventoryTransactionProvider.notifier)
            .createAndInsertInvTransaction(
              invName: invModel.name ?? 'null',
              transactionTypeEnum: transactionTypeEnum,
              staffModel: staffModel,
              outletModel: outletModel,
              posDeviceModel: posDeviceModel,
              invModel: invModel,
              saleItemQty: saleItem.quantity!,
              // empty because do nothing in this method
              // future developer after me, please continue this
              onError: (message) {},
            );
      }).toList(),
    );
  }

  double getCurrQty(
    InventoryModel invModel,
    SaleItemModel saleItem,
    int transactionTypeEnum,
  ) {
    if (transactionTypeEnum == InventoryTransactionTypeEnum.stockOut) {
      return invModel.currentQuantity! - saleItem.quantity!;
    } else if (transactionTypeEnum == InventoryTransactionTypeEnum.stockIn) {
      return invModel.currentQuantity! + saleItem.quantity!;
    } else {
      return invModel.currentQuantity!;
    }
  }

  Future<List<InventoryModel>> getListInventoryModelByInvIds(
    List<String?> invIds,
  ) async {
    return await _localRepository.getListInventoryModelByInvIds(invIds);
  }

  Future<bool> checkInventoryStock(
    BuildContext context,
    List<SaleItemModel> saleItems,
  ) async {
    List<String?> invIds = saleItems.map((si) => si.inventoryId).toList();
    List<InventoryModel> listInv = await getListInventoryModelByInvIds(invIds);

    // get inv that current is less than or equal to 0
    List<InventoryModel> lowStockInv =
        listInv
            .where((inv) => inv.currentQuantity! <= 0 && inv.isEnabled == true)
            .toList();

    String lowStockInvNames = lowStockInv.map((inv) => inv.name!).join(', ');

    if (lowStockInv.isNotEmpty) {
      bool? result = await CustomDialog.show(
        context,
        icon: Icons.inventory_2_rounded,
        title: 'lowStockWarning'.tr(),
        description: 'lowStockWarningDescription'.tr(args: [lowStockInvNames]),
        dialogType: DialogType.warning,
        btnOkText: 'ok'.tr(),
        btnOkOnPress: () {
          NavigationUtils.pop(context, true);
        },
        btnCancelText: 'cancel'.tr(),
        btnCancelOnPress: () {
          NavigationUtils.pop(context, false);
        },
      );
      return result ?? false;
    } else {
      return true;
    }
  }
}

/// Provider for sorted items (computed provider)
final sortedInventorysProvider = Provider<List<InventoryModel>>((ref) {
  final items = ref.watch(inventoryProvider).items;
  final sorted = List<InventoryModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for inventory domain
final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
      return InventoryNotifier(
        localRepository: ServiceLocator.get<LocalInventoryRepository>(),
        remoteRepository: ServiceLocator.get<InventoryRepository>(),
        webService: ServiceLocator.get<IWebService>(),
        ref: ref,
      );
    });

/// Provider for inventory by ID (family provider for indexed lookups)
final inventoryByIdProvider = Provider.family<InventoryModel?, String>((
  ref,
  id,
) {
  final items = ref.watch(inventoryProvider).items;
  try {
    return items.firstWhere((item) => item.id == id);
  } catch (e) {
    return null;
  }
});
