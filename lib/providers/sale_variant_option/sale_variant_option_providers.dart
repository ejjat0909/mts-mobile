import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/sale_variant_option/sale_variant_option_model.dart';
import 'package:mts/domain/repositories/local/sale_variant_option_repository.dart';
import 'package:mts/providers/sale_variant_option/sale_variant_option_state.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/domain/repositories/remote/sale_variant_option_repository.dart';

/// StateNotifier for SaleVariantOption domain
///
/// Migrated from: sale_variant_option_facade_impl.dart
class SaleVariantOptionNotifier extends StateNotifier<SaleVariantOptionState> {
  final LocalSaleVariantOptionRepository _localRepository;
  final SaleVariantOptionRepository _remoteRepository;
  final IWebService _webService;

  SaleVariantOptionNotifier({
    required LocalSaleVariantOptionRepository localRepository,
    required SaleVariantOptionRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const SaleVariantOptionState());

  // ============================================================
  // CRUD Operations
  // ============================================================

  /// Insert a single item into local storage
  Future<bool> insert(
    SaleVariantOptionModel item, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(
        item,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        final currentItems = List<SaleVariantOptionModel>.from(state.items);
        final index = currentItems.indexWhere((e) => e.id == item.id);
        if (index >= 0) {
          currentItems[index] = item;
        } else {
          currentItems.add(item);
        }
        state = state.copyWith(items: currentItems, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result > 0;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Update a single item in local storage
  Future<bool> update(
    SaleVariantOptionModel item, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.update(
        item,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        final currentItems = List<SaleVariantOptionModel>.from(state.items);
        final index = currentItems.indexWhere((e) => e.id == item.id);
        if (index >= 0) {
          currentItems[index] = item;
          state = state.copyWith(items: currentItems, isLoading: false);
        } else {
          state = state.copyWith(isLoading: false);
        }
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result > 0;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<SaleVariantOptionModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<SaleVariantOptionModel>.from(state.items);
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
    List<SaleVariantOptionModel> list, {
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
        final existingItems = List<SaleVariantOptionModel>.from(state.items);
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
  Future<List<SaleVariantOptionModel>> getListSaleVariantOption() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListSaleVariantOption();
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

      if (result > 0) {
        final updatedItems =
            state.items.where((item) => item.id != id).toList();
        state = state.copyWith(items: updatedItems, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result > 0;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<SaleVariantOptionModel> list) async {
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
    List<SaleVariantOptionModel> newData, {
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

  /// Find an item by its ID
  Future<SaleVariantOptionModel?> getSaleVariantOptionModelById(
    String itemId,
  ) async {
    try {
      final items = await _localRepository.getListSaleVariantOption();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => SaleVariantOptionModel(),
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

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get sale variant option list (old notifier getter)
  List<SaleVariantOptionModel> get getSaleVariantOptionList => state.items;
}

/// Provider for saleVariantOption domain
final saleVariantOptionProvider =
    StateNotifierProvider<SaleVariantOptionNotifier, SaleVariantOptionState>((
      ref,
    ) {
      return SaleVariantOptionNotifier(
        localRepository: ServiceLocator.get<LocalSaleVariantOptionRepository>(),
        remoteRepository: ServiceLocator.get<SaleVariantOptionRepository>(),
        webService: ServiceLocator.get<IWebService>(),
      );
    });

/// Provider for saleVariantOption by ID (family provider for indexed lookups)
final saleVariantOptionByIdProvider =
    FutureProvider.family<SaleVariantOptionModel?, String>((ref, id) async {
      final notifier = ref.watch(saleVariantOptionProvider.notifier);
      return notifier.getSaleVariantOptionModelById(id);
    });

/// Provider for sorted items by createdAt (newest first)
final sortedSaleVariantOptionsProvider = Provider<List<SaleVariantOptionModel>>(
  (ref) {
    final items = ref.watch(saleVariantOptionProvider).items;
    final sorted = List<SaleVariantOptionModel>.from(items);
    sorted.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    return sorted;
  },
);
