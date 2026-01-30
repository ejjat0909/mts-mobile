import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/domain/repositories/local/sale_modifier_repository.dart';
import 'package:mts/providers/sale_modifier/sale_modifier_state.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_list_response_model.dart';
import 'package:mts/domain/repositories/remote/sale_modifier_repository.dart';

/// StateNotifier for SaleModifier domain
///
/// Migrated from: sale_modifier_facade_impl.dart
class SaleModifierNotifier extends StateNotifier<SaleModifierState> {
  final LocalSaleModifierRepository _localRepository;
  final SaleModifierRepository _remoteRepository;
  final IWebService _webService;

  SaleModifierNotifier({
    required LocalSaleModifierRepository localRepository,
    required SaleModifierRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const SaleModifierState());

  // ============================================================
  // CRUD Operations - Optimized for Riverpod
  // ============================================================

  /// Insert a single sale modifier
  Future<int> insert(
    SaleModifierModel sm, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(
        sm,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        final currentItems = List<SaleModifierModel>.from(state.items);
        final index = currentItems.indexWhere((item) => item.id == sm.id);
        if (index >= 0) {
          currentItems[index] = sm;
        } else {
          currentItems.add(sm);
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

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<SaleModifierModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<SaleModifierModel>.from(state.items);
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

  /// Upsert bulk items to Hive box without replacing all items
  Future<bool> upsertBulk(
    List<SaleModifierModel> list, {
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
        final existingItems = List<SaleModifierModel>.from(state.items);
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

  /// Get all items from local storage
  Future<List<SaleModifierModel>> getListSaleModifierModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListSaleModifierModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete a single item by ID
  Future<bool> delete(String id, {bool isInsertToPending = true}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.delete(
        id,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final updatedItems =
            state.items.where((item) => item.id != id).toList();
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

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<SaleModifierModel> list) async {
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

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<SaleModifierModel> newData, {
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

  // ============================================================
  // Query Methods
  // ============================================================

  /// Get list of sale modifier IDs by sale item ID
  Future<List<String>> getListSaleModifierIds(String idSaleItem) async {
    try {
      return await _localRepository.getListSaleModifierIds(idSaleItem);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get list of sale modifiers by sale ID
  Future<List<SaleModifierModel>> getListSaleModifierModelBySaleId(
    String idSale,
  ) async {
    try {
      return await _localRepository.getListSaleModifierModelBySaleId(idSale);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get list of sale modifiers by predefined order ID
  Future<List<SaleModifierModel>> getListSaleModifiersByPredefinedOrderId(
    String predefinedOrderId, {
    required List<String> categoryIds,
  }) async {
    try {
      return await _localRepository.getListSaleModifiersByPredefinedOrderId(
        predefinedOrderId,
        categoryIds,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get list of sale modifiers by predefined order ID filtered by category
  Future<List<SaleModifierModel>>
  getListSaleModifiersByPredefinedOrderIdFilterWithCategory(
    String predefinedOrderId, {
    required List<String> categoryIds,
    required String? saleItemId,
  }) async {
    try {
      return _localRepository
          .getListSaleModifiersByPredefinedOrderIdFilterWithCategory(
            predefinedOrderId,
            categoryIds,
            saleItemId: saleItemId,
          );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get list of sale modifiers by item ID and timestamp
  Future<List<SaleModifierModel>> getListSaleModifiersByItemIdAndTimestamp(
    String saleItemId,
    DateTime updatedAt,
  ) async {
    try {
      return await _localRepository.getListSaleModifiersByItemIdAndTimestamp(
        saleItemId,
        updatedAt,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Find an item by its ID
  Future<SaleModifierModel?> getSaleModifierModelById(String itemId) async {
    try {
      final items = await _localRepository.getListSaleModifierModel();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => SaleModifierModel(),
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

  // ============================================================
  // Delete Operations
  // ============================================================

  /// Soft delete sale modifiers by predefined order ID
  Future<bool> softDeleteSMsByPredefinedOrderId(
    String predefinedOrderId,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository
          .softDeleteSaleModifiersByPredefinedOrderId(predefinedOrderId);
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete sale modifiers by predefined order ID
  Future<bool> deleteSMsByPredefinedOrderId(String predefinedOrderId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository
          .deleteSaleModifiersByPredefinedOrderId(predefinedOrderId);
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get sale modifier list (old notifier getter)
  List<SaleModifierModel> get getSaleModifierList => state.items;

  Future<List<SaleModifierModel>> syncFromRemote() async {
    List<SaleModifierModel> allSaleModifiers = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching sale modifiers page $currentPage');
      SaleModifierListResponseModel responseModel = await _webService.get(
        getListSaleModifiersWithPagination(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Add items from current page to the list
        allSaleModifiers.addAll(responseModel.data!);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination SALE MODIFIER: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch sale modifiers page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allSaleModifiers.length} sale modifiers from all pages',
    );
    return allSaleModifiers;
  }

  Resource getListSaleModifiersWithPagination(String page) {
    return _remoteRepository.getListSaleModifiersWithPagination(page);
  }
}

/// Provider for sorted items (computed provider)
final sortedSaleModifiersProvider = Provider<List<SaleModifierModel>>((ref) {
  final items = ref.watch(saleModifierProvider).items;
  final sorted = List<SaleModifierModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)),
  );
  return sorted;
});

/// Provider for saleModifier domain
final saleModifierProvider =
    StateNotifierProvider<SaleModifierNotifier, SaleModifierState>((ref) {
      return SaleModifierNotifier(
        localRepository: ServiceLocator.get<LocalSaleModifierRepository>(),
        remoteRepository: ServiceLocator.get<SaleModifierRepository>(),
        webService: ServiceLocator.get<IWebService>(),
      );
    });

/// Provider for saleModifier by ID (family provider for indexed lookups)
final saleModifierByIdProvider =
    FutureProvider.family<SaleModifierModel?, String>((ref, id) async {
      final notifier = ref.watch(saleModifierProvider.notifier);
      return notifier.getSaleModifierModelById(id);
    });
