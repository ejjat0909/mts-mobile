import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/deleted_sale_item/deleted_sale_item_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/domain/repositories/local/deleted_sale_item_repository.dart';
import 'package:mts/providers/deleted_sale_item/deleted_sale_item_state.dart';
import 'package:mts/providers/device/device_providers.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/sale_modifier_option/sale_modifier_option_providers.dart';
import 'package:mts/providers/user/user_providers.dart';

/// StateNotifier for DeletedSaleItem domain
///
/// Contains business logic for tracking deleted/voided sale items.
/// Orchestrates DeviceFacade, SaleItemFacade, SaleModifierOptionFacade for context gathering.
enum ItemTypeDetails { name, sku }

class DeletedSaleItemNotifier extends StateNotifier<DeletedSaleItemState> {
  final LocalDeletedSaleItemRepository _localRepository;
  final Ref _ref;

  DeletedSaleItemNotifier({
    required LocalDeletedSaleItemRepository localRepository,
    required Ref ref,
  }) : _localRepository = localRepository,
       _ref = ref,
       super(const DeletedSaleItemState());

  /// Insert a single deleted sale item
  Future<int> insert(DeletedSaleItemModel model) async {
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

  /// Update a deleted sale item
  Future<int> update(DeletedSaleItemModel deletedSaleItemModel) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.update(deletedSaleItemModel, true);

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

  /// Create and insert deleted sale item records for voided items
  ///
  /// This method orchestrates multiple services to gather context:
  /// - DeviceFacade: Get POS device info
  /// - SaleItemFacade: Get voided sale items
  /// - SaleModifierOptionFacade: Get item modifiers
  /// - UserNotifier, StaffModel, OutletModel: Get user/staff/outlet context
  Future<void> createAndInsertDeletedSaleItemModel({
    required SaleModel saleModel,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Get context from various services
      final outletModel = ServiceLocator.get<OutletModel>();
      final userNotifier = _ref.read(userProvider.notifier);
      final staffModel = ServiceLocator.get<StaffModel>();
      final deviceNotifier = _ref.read(deviceProvider.notifier);
      final posDeviceModel = await deviceNotifier.getLatestDeviceModel();
      final userModel = await userNotifier.getUserModelFromStaffId(
        staffModel.id ?? '-1',
      );

      final saleItemFacade = _ref.read(saleItemProvider.notifier);
      final listSaleItem = await saleItemFacade
          .getListSaleItemBySaleIdWhereIsVoidedTrue([saleModel.id ?? '-1']);

      for (SaleItemModel saleItem in listSaleItem) {
        String? orderNumber =
            saleModel.id != null ? saleModel.runningNumber.toString() : null;

        double? itemPrice = calcItemPrice(saleItem);

        DeletedSaleItemModel dsi = DeletedSaleItemModel(
          // the one who delete the order
          staffName: userModel?.name,
          orderNumber: orderNumber,
          itemQuantity: saleItem.quantity.toString(),
          itemTotalPrice: saleItem.price?.toStringAsFixed(2),
          itemPrice: itemPrice?.toStringAsFixed(2),
          itemName: getItemDetails(saleItem.itemId, ItemTypeDetails.name),
          itemSku: getItemDetails(saleItem.itemId, ItemTypeDetails.sku),
          itemVariant: saleItem.variantOptionJson ?? '{}',
          itemModifiers: await getItemModifiers(saleModel),
          posDeviceName: posDeviceModel?.name,
          posDeviceCode: posDeviceModel?.code,
          outletName: outletModel.name,
          outletId: outletModel.id,
          companyId: staffModel.companyId,
        );

        await insert(dsi);
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      prints('Error creating deleted sale items: $e');
    }
  }

  /// Calculate item price from sale item
  double? calcItemPrice(SaleItemModel saleItem) {
    double? itemPrice =
        (saleItem.id != null &&
                saleItem.price != null &&
                saleItem.quantity != null &&
                saleItem.quantity != 0)
            ? saleItem.price! / saleItem.quantity!
            : null;

    return itemPrice;
  }

  /// Get item details (name or SKU) from item ID
  String? getItemDetails(String? itemId, ItemTypeDetails type) {
    final itemNotifier = _ref.read(itemProvider.notifier);

    if (itemId == null || itemId.isEmpty) {
      return null;
    } else {
      ItemModel itemModel = itemNotifier.getItemById(itemId);

      if (type == ItemTypeDetails.name) {
        if (itemModel.id != null && itemModel.name != null) {
          return itemModel.name;
        } else {
          return null;
        }
      }

      if (type == ItemTypeDetails.sku) {
        if (itemModel.id != null && itemModel.sku != null) {
          return itemModel.sku;
        } else {
          return null;
        }
      }

      return null;
    }
  }

  /// Get item modifiers as JSON string
  Future<String?> getItemModifiers(SaleModel saleModel) async {
    final smoFacade = _ref.read(saleModifierOptionProvider.notifier);
    if (saleModel.id == null) {
      return null;
    }

    List<SaleModifierOptionModel> listSMO = await smoFacade
        .getSaleModifierOptionModelsByIdSale(saleModel.id!);

    return jsonEncode(listSMO.map((e) => e.toJson()).toList());
  }

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<DeletedSaleItemModel> list, {
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
  Future<List<DeletedSaleItemModel>> getListDeletedSaleItemModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListDeletedSaleItemModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<DeletedSaleItemModel> list) async {
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
  Future<DeletedSaleItemModel?> getDeletedSaleItemModelById(
    String itemId,
  ) async {
    try {
      final items = await _localRepository.getListDeletedSaleItemModel();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => DeletedSaleItemModel(),
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
    List<DeletedSaleItemModel> newData, {
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
    List<DeletedSaleItemModel> list, {
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
      final items = await _localRepository.getListDeletedSaleItemModel();

      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get deleted sale item list (old notifier getter)
  List<DeletedSaleItemModel> get getDeletedSaleItemList => state.items;

  /// Set the list of deleted sale items (old notifier method)
  void setListDeletedSaleItem(List<DeletedSaleItemModel> list) {
    state = state.copyWith(items: list);
  }

  /// Add or update list of deleted sale items (old notifier method)
  void addOrUpdateList(List<DeletedSaleItemModel> list) {
    final currentItems = List<DeletedSaleItemModel>.from(state.items);

    for (DeletedSaleItemModel deletedSaleItem in list) {
      int index = currentItems.indexWhere(
        (element) => element.id == deletedSaleItem.id,
      );

      if (index != -1) {
        // if found, replace existing item with the new one
        currentItems[index] = deletedSaleItem;
      } else {
        // not found
        currentItems.add(deletedSaleItem);
      }
    }
    state = state.copyWith(items: currentItems);
  }

  /// Add or update a single deleted sale item (old notifier method)
  void addOrUpdate(DeletedSaleItemModel deletedSaleItem) {
    final currentItems = List<DeletedSaleItemModel>.from(state.items);
    int index = currentItems.indexWhere((p) => p.id == deletedSaleItem.id);

    if (index != -1) {
      // if found, replace existing item with the new one
      currentItems[index] = deletedSaleItem;
    } else {
      // not found
      currentItems.add(deletedSaleItem);
    }
    state = state.copyWith(items: currentItems);
  }

  /// Remove a deleted sale item by ID (old notifier method)
  void remove(String id) {
    final updatedItems =
        state.items
            .where((deletedSaleItem) => deletedSaleItem.id != id)
            .toList();
    state = state.copyWith(items: updatedItems);
  }
}

/// Provider for sorted items (computed provider)
final sortedDeletedSaleItemsProvider = Provider<List<DeletedSaleItemModel>>((
  ref,
) {
  final items = ref.watch(deletedSaleItemProvider).items;
  final sorted = List<DeletedSaleItemModel>.from(items);
  sorted.sort(
    (a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
  );
  return sorted;
});

/// Provider for deletedSaleItem domain
final deletedSaleItemProvider =
    StateNotifierProvider<DeletedSaleItemNotifier, DeletedSaleItemState>((ref) {
      return DeletedSaleItemNotifier(
        localRepository: ServiceLocator.get<LocalDeletedSaleItemRepository>(),
        ref: ref,
      );
    });

/// Provider for deletedSaleItem by ID (family provider for indexed lookups)
final deletedSaleItemByIdProvider =
    FutureProvider.family<DeletedSaleItemModel?, String>((ref, id) async {
      final notifier = ref.watch(deletedSaleItemProvider.notifier);
      return notifier.getDeletedSaleItemModelById(id);
    });
