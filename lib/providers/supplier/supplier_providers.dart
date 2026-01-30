import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/supplier/supplier_model.dart';
import 'package:mts/domain/repositories/local/supplier_repository.dart';
import 'package:mts/providers/supplier/supplier_state.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/supplier/supplier_list_response_model.dart';
import 'package:mts/domain/repositories/remote/supplier_repository.dart';

/// StateNotifier for Supplier domain
///
/// Migrated from: supplier_facade_impl.dart
///
class SupplierNotifier extends StateNotifier<SupplierState> {
  final LocalSupplierRepository _localRepository;
  final SupplierRepository _remoteRepository;
  final IWebService _webService;

  SupplierNotifier({
    required LocalSupplierRepository localRepository,
    required SupplierRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const SupplierState());

  /// Insert a single item into local storage
  Future<int> insert(
    SupplierModel model, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(
        model,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        final updatedItems = List<SupplierModel>.from(state.items)..add(model);
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
    SupplierModel model, {
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
    List<SupplierModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<SupplierModel>.from(state.items);
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
  Future<List<SupplierModel>> getListSupplierModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListSupplierModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<SupplierModel> list) async {
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
  Future<SupplierModel?> getSupplierModelById(String itemId) async {
    try {
      final items = await _localRepository.getListSupplierModel();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => SupplierModel(),
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
    List<SupplierModel> newData, {
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
    List<SupplierModel> list, {
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
        final existingItems = List<SupplierModel>.from(state.items);
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

  /// Refresh items from repository (explicit reload)
  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListSupplierModel();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ============================================================
  // UI State Management Methods (from old SupplierNotifier)
  // ============================================================

  /// Get current supplier list (getter for compatibility)
  List<SupplierModel> get getSupplierList => state.items;

  /// Get current supplier model (getter for compatibility)
  SupplierModel? get getCurrentSupplierModel => state.currentSupplier;

  /// Set current supplier for operations
  void setCurrentSupplierModel(SupplierModel? model) {
    state = state.copyWith(currentSupplier: model);
  }

  /// Set the entire supplier list
  void setListSuppliers(List<SupplierModel> list) {
    state = state.copyWith(items: list);
  }

  /// Add or update multiple suppliers in the list
  void addOrUpdateList(List<SupplierModel> list) {
    final currentItems = List<SupplierModel>.from(state.items);

    for (SupplierModel supplier in list) {
      int index = currentItems.indexWhere(
        (element) => element.id == supplier.id,
      );

      if (index != -1) {
        // if found, replace existing item with the new one
        currentItems[index] = supplier;
      } else {
        // not found
        currentItems.add(supplier);
      }
    }

    state = state.copyWith(items: currentItems);
  }

  /// Add or update a single supplier
  void addOrUpdate(SupplierModel model) {
    final currentItems = List<SupplierModel>.from(state.items);
    int index = currentItems.indexWhere((supplier) => supplier.id == model.id);

    if (index != -1) {
      // if found, replace existing item with the new one
      currentItems[index] = model;
    } else {
      // not found
      currentItems.add(model);
    }

    state = state.copyWith(items: currentItems);
  }

  /// Add a supplier to the list
  void addSupplier(SupplierModel model) {
    final currentItems = List<SupplierModel>.from(state.items);
    currentItems.add(model);
    state = state.copyWith(items: currentItems);
  }

  /// Remove a supplier by ID
  void remove(String id) {
    final currentItems = List<SupplierModel>.from(state.items);
    currentItems.removeWhere((supplier) => supplier.id == id);
    state = state.copyWith(items: currentItems);
  }

  /// Update a supplier in the list
  void updateSupplier(SupplierModel model) {
    final currentItems = List<SupplierModel>.from(state.items);
    int index = currentItems.indexWhere((supplier) => supplier.id == model.id);
    if (index >= 0) {
      currentItems[index] = model;
      state = state.copyWith(items: currentItems);
    }
  }

  /// Get supplier by ID (synchronous version for compatibility)
  SupplierModel getSupplierById(String? idSupplier) {
    if (idSupplier == null) {
      return SupplierModel();
    }

    return state.items.firstWhere(
      (supplier) => supplier.id == idSupplier,
      orElse: () => SupplierModel(),
    );
  }

  Resource getSupplierListWithPagination(String page) {
    return _remoteRepository.getSupplierListWithPagination(page);
  }

  Future<List<SupplierModel>> syncFromRemote() async {
    List<SupplierModel> allSuppliers = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching suppliers page $currentPage');
      SupplierListResponseModel responseModel = await _webService.get(
        getSupplierListWithPagination(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Process suppliers from current page
        List<SupplierModel> pageSuppliers = responseModel.data!;

        // Add suppliers from current page to the list
        allSuppliers.addAll(pageSuppliers);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination SUPPLIER: current page=$currentPage, last page=$lastPage, total suppliers=${responseModel.paginator!.total}',
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
          'Failed to fetch suppliers page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allSuppliers.length} suppliers from all pages',
    );
    return allSuppliers;
  }
}

/// Provider for sorted items (computed provider)
final sortedSuppliersProvider = Provider<List<SupplierModel>>((ref) {
  final items = ref.watch(supplierProvider).items;
  final sorted = List<SupplierModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for supplier domain
final supplierProvider = StateNotifierProvider<SupplierNotifier, SupplierState>(
  (ref) {
    return SupplierNotifier(
      localRepository: ServiceLocator.get<LocalSupplierRepository>(),
      remoteRepository: ServiceLocator.get<SupplierRepository>(),
      webService: ServiceLocator.get<IWebService>(),
    );
  },
);

/// Provider for supplier by ID (family provider for indexed lookups)
final supplierByIdProvider = FutureProvider.family<SupplierModel?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(supplierProvider.notifier);
  return notifier.getSupplierModelById(id);
});
