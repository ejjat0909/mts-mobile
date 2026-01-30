import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/domain/repositories/local/sale_modifier_option_repository.dart';
import 'package:mts/providers/sale_modifier_option/sale_modifier_option_state.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_list_response_model.dart';
import 'package:mts/domain/repositories/remote/sale_modifier_option_repository.dart';

/// StateNotifier for SaleModifierOption domain
///
/// Migrated from: sale_modifier_option_facade_impl.dart
class SaleModifierOptionNotifier
    extends StateNotifier<SaleModifierOptionState> {
  final LocalSaleModifierOptionRepository _localRepository;
  final SaleModifierOptionRepository _remoteRepository;
  final IWebService _webService;

  SaleModifierOptionNotifier({
    required LocalSaleModifierOptionRepository localRepository,
    required SaleModifierOptionRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const SaleModifierOptionState());

  // ============================================================
  // CRUD Operations - Optimized for Riverpod
  // ============================================================

  /// Insert a single sale modifier option
  Future<int> insert(SaleModifierOptionModel model) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(model, true);

      if (result > 0) {
        final currentItems = List<SaleModifierOptionModel>.from(state.items);
        final index = currentItems.indexWhere((item) => item.id == model.id);
        if (index >= 0) {
          currentItems[index] = model;
        } else {
          currentItems.add(model);
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
    List<SaleModifierOptionModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<SaleModifierOptionModel>.from(state.items);
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
    List<SaleModifierOptionModel> list, {
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
        final existingItems = List<SaleModifierOptionModel>.from(state.items);
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
  Future<List<SaleModifierOptionModel>> getListSaleModifierOption() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListSaleModifierOption();
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
  Future<bool> deleteBulk(List<SaleModifierOptionModel> list) async {
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
    List<SaleModifierOptionModel> newData, {
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

  /// Get list of modifier option IDs by sale modifier IDs
  Future<List<String>> getListModifierOptionIds(
    List<String> saleModifierIds,
  ) async {
    try {
      return await _localRepository.getListModifierOptionIds(saleModifierIds);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get sale modifier options by sale ID
  Future<List<SaleModifierOptionModel>> getSaleModifierOptionModelsByIdSale(
    String idSale,
  ) async {
    try {
      return await _localRepository.getListSaleModifierOptionModelBySaleId(
        idSale,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get list of sale modifier options by predefined order ID
  Future<List<SaleModifierOptionModel>>
  getListSaleModifierOptionsByPredefinedOrderId(
    String predefinedOrderId, {
    required List<String> categoryIds,
  }) async {
    try {
      return await _localRepository
          .getListSaleModifierOptionsByPredefinedOrderId(
            predefinedOrderId,
            categoryIds: categoryIds,
          );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get list of sale modifier options by predefined order ID filtered by category
  Future<List<SaleModifierOptionModel>>
  getListSaleModifierOptionsByPredefinedOrderIdFilterWithCategory(
    String predefinedOrderId, {
    required List<String> categoryIds,
    required String? saleModifierId,
  }) async {
    try {
      return _localRepository
          .getListSaleModifierOptionsByPredefinedOrderIdFilterWithCategory(
            predefinedOrderId,
            categoryIds: categoryIds,
            saleModifierId: saleModifierId,
          );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get list of sale modifier options by sale modifier IDs
  Future<List<SaleModifierOptionModel>>
  getListSaleModifierOptionsBySaleModifierIds(
    List<String> saleModifierIds,
  ) async {
    try {
      return await _localRepository.getListSaleModifierOptionsBySaleModifierIds(
        saleModifierIds,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Find an item by its ID
  Future<SaleModifierOptionModel?> getSaleModifierOptionModelById(
    String itemId,
  ) async {
    try {
      final items = await _localRepository.getListSaleModifierOption();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => SaleModifierOptionModel(),
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

  /// Soft delete sale modifier options by predefined order ID
  Future<bool> softDeleteSaleModifierOptionsByPredefinedOrderId(
    String predefinedOrderId,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository
          .softDeleteSaleModifierOptionsByPredefinedOrderId(predefinedOrderId);
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete sale modifier options by predefined order ID
  Future<bool> deleteSMOsByPredefinedOrderId(String predefinedOrderId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository
          .deleteSaleModifierOptionsByPredefinedOrderId(predefinedOrderId);
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

  /// Get sale modifier option list (old notifier getter)
  List<SaleModifierOptionModel> get getSaleModifierOptionList => state.items;

  Future<List<SaleModifierOptionModel>> syncFromRemote() async {
    List<SaleModifierOptionModel> allSaleModifierOptions = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching sale modifier options page $currentPage');
      SaleModifierOptionListResponseModel responseModel = await _webService.get(
        getListSaleModifierOptionsWithPagination(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Add items from current page to the list
        allSaleModifierOptions.addAll(responseModel.data!);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination SALE MODIFIER OPTION: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch sale modifier options page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allSaleModifierOptions.length} sale modifier options from all pages',
    );
    return allSaleModifierOptions;
  }

  Resource getListSaleModifierOptionsWithPagination(String page) {
    return _remoteRepository.getListSaleModifierOptionsWithPagination(page);
  }
}

/// Provider for saleModifierOption domain
final saleModifierOptionProvider = StateNotifierProvider<
  SaleModifierOptionNotifier,
  SaleModifierOptionState
>((ref) {
  return SaleModifierOptionNotifier(
    localRepository: ServiceLocator.get<LocalSaleModifierOptionRepository>(),
    remoteRepository: ServiceLocator.get<SaleModifierOptionRepository>(),
    webService: ServiceLocator.get<IWebService>(),
  );
});

/// Provider for saleModifierOption by ID (family provider for indexed lookups)
final saleModifierOptionByIdProvider =
    FutureProvider.family<SaleModifierOptionModel?, String>((ref, id) async {
      final notifier = ref.watch(saleModifierOptionProvider.notifier);
      return notifier.getSaleModifierOptionModelById(id);
    });

/// Provider for sorted items by createdAt (newest first)
final sortedSaleModifierOptionsProvider =
    Provider<List<SaleModifierOptionModel>>((ref) {
      final items = ref.watch(saleModifierOptionProvider).items;
      final sorted = List<SaleModifierOptionModel>.from(items);
      sorted.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return sorted;
    });
