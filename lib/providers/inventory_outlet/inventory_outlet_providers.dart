import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/inventory_outlet/inventory_outlet_list_response_model.dart';
import 'package:mts/data/models/inventory_outlet/inventory_outlet_model.dart';
import 'package:mts/domain/repositories/local/inventory_outlet_repository.dart';
import 'package:mts/domain/repositories/remote/inventory_outlet_repository.dart';
import 'package:mts/providers/inventory_outlet/inventory_outlet_state.dart';

/// StateNotifier for InventoryOutlet domain
///
/// Migrated from: inventory_outlet_facade_impl.dart
class InventoryOutletNotifier extends StateNotifier<InventoryOutletState> {
  final LocalInventoryOutletRepository _localRepository;
  final InventoryOutletRepository _remoteRepository;
  final IWebService _webService;
  final Ref _ref;

  InventoryOutletNotifier({
    required LocalInventoryOutletRepository localRepository,
    required InventoryOutletRepository remoteRepository,
    required IWebService webService,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _ref = ref,
       super(const InventoryOutletState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<InventoryOutletModel> list, {
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
  Future<List<InventoryOutletModel>> getListInventoryOutletModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListInventoryOutletModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<InventoryOutletModel> list) async {
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
  Future<InventoryOutletModel?> getInventoryOutletModelById(
    String itemId,
  ) async {
    try {
      final items = await _localRepository.getListInventoryOutletModel();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => InventoryOutletModel(),
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
    List<InventoryOutletModel> newData, {
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
    List<InventoryOutletModel> list, {
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
        final existingItems = List<InventoryOutletModel>.from(state.items);
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
    InventoryOutletModel inventoryOutletModel, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(
        inventoryOutletModel,
        isInsertToPending,
      );

      if (result > 0) {
        final updatedItems = [...state.items, inventoryOutletModel];
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
    InventoryOutletModel inventoryOutletModel, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.update(
        inventoryOutletModel,
        isInsertToPending,
      );

      if (result > 0) {
        final updatedItems =
            state.items.map((item) {
              return item.id == inventoryOutletModel.id
                  ? inventoryOutletModel
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
      final items = await _localRepository.getListInventoryOutletModel();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get inventory outlet list (old notifier getter)
  List<InventoryOutletModel> get getInventoryOutletList => state.items;

  Future<List<InventoryOutletModel>> syncFromRemote() async {
    List<InventoryOutletModel> allInventoryOutlets = [];
    int currentPage = 1;
    int? lastPage;

    do {
      InventoryOutletListResponseModel responseModel = await _webService.get(
        _remoteRepository.getInventoryOutletListPaginated(
          currentPage.toString(),
        ),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        allInventoryOutlets.addAll(responseModel.data!);

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

    return allInventoryOutlets;
  }

  Resource getListInventoryOutletWithPagination(String page) {
    return _remoteRepository.getInventoryOutletListPaginated(page);
  }
}

/// Provider for sorted items (computed provider)
final sortedInventoryOutletsProvider = Provider<List<InventoryOutletModel>>((
  ref,
) {
  final items = ref.watch(inventoryOutletProvider).items;
  final sorted = List<InventoryOutletModel>.from(items);
  sorted.sort((a, b) => (a.id ?? '').compareTo(b.id ?? ''));
  return sorted;
});

/// Provider for inventoryOutlet domain
final inventoryOutletProvider =
    StateNotifierProvider<InventoryOutletNotifier, InventoryOutletState>((ref) {
      return InventoryOutletNotifier(
        localRepository: ServiceLocator.get<LocalInventoryOutletRepository>(),
        remoteRepository: ServiceLocator.get<InventoryOutletRepository>(),
        webService: ServiceLocator.get<IWebService>(),
        ref: ref,
      );
    });

/// Provider for inventoryOutlet by ID (family provider for indexed lookups)
final inventoryOutletByIdProvider =
    Provider.family<InventoryOutletModel?, String>((ref, id) {
      final items = ref.watch(inventoryOutletProvider).items;
      try {
        return items.firstWhere((item) => item.id == id);
      } catch (e) {
        return null;
      }
    });

/// Provider for inventory outlets from Hive cache (synchronous)
final inventoryOutletsFromHiveProvider = Provider<List<InventoryOutletModel>>((
  ref,
) {
  final notifier = ref.watch(inventoryOutletProvider.notifier);
  return notifier.getListInventoryOutletFromHive();
});

/// Provider for inventory outlet count (computed provider)
final inventoryOutletCountProvider = Provider<int>((ref) {
  final items = ref.watch(inventoryOutletProvider).items;
  return items.length;
});

/// Provider for inventory outlets by outlet ID (computed family provider)
final inventoryOutletsByOutletIdProvider =
    Provider.family<List<InventoryOutletModel>, String>((ref, outletId) {
      final items = ref.watch(inventoryOutletProvider).items;
      return items.where((item) => item.outletId == outletId).toList();
    });

/// Provider for inventory outlets by inventory ID (computed family provider)
final inventoryOutletsByInventoryIdProvider =
    Provider.family<List<InventoryOutletModel>, String>((ref, inventoryId) {
      final items = ref.watch(inventoryOutletProvider).items;
      return items.where((item) => item.inventoryId == inventoryId).toList();
    });

/// Provider to check if inventory outlet exists (computed family provider)
final inventoryOutletExistsProvider = Provider.family<bool, String>((ref, id) {
  final items = ref.watch(inventoryOutletProvider).items;
  return items.any((item) => item.id == id);
});

/// Provider for inventory outlets with low stock (computed family provider)
final lowStockInventoryOutletsProvider =
    Provider.family<List<InventoryOutletModel>, double>((ref, threshold) {
      final items = ref.watch(inventoryOutletProvider).items;
      return items
          .where((item) => (item.currentQuantity ?? 0) < threshold)
          .toList();
    });

/// Provider for inventory outlets with stock (computed provider)
final inStockInventoryOutletsProvider = Provider<List<InventoryOutletModel>>((
  ref,
) {
  final items = ref.watch(inventoryOutletProvider).items;
  return items.where((item) => (item.currentQuantity ?? 0) > 0).toList();
});

/// Provider for out of stock inventory outlets (computed provider)
final outOfStockInventoryOutletsProvider = Provider<List<InventoryOutletModel>>(
  (ref) {
    final items = ref.watch(inventoryOutletProvider).items;
    return items.where((item) => (item.currentQuantity ?? 0) <= 0).toList();
  },
);

/// Provider for total quantity by inventory ID (computed family provider)
final totalQuantityByInventoryIdProvider = Provider.family<double, String>((
  ref,
  inventoryId,
) {
  final items = ref.watch(inventoryOutletsByInventoryIdProvider(inventoryId));
  return items.fold(0.0, (sum, item) => sum + (item.currentQuantity ?? 0));
});
