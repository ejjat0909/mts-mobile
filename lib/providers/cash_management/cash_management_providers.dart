import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/models/cash_management/cash_management_model.dart';
import 'package:mts/data/repositories/local/local_cash_management_repository_impl.dart';
import 'package:mts/data/repositories/remote/cash_management_repository_impl.dart';
import 'package:mts/domain/repositories/local/cash_management_repository.dart';
import 'package:mts/domain/repositories/remote/cash_management_repository.dart';
import 'package:mts/providers/cash_management/cash_management_state.dart';
import 'package:mts/core/utils/log_utils.dart';

/// StateNotifier for CashManagement domain
///
/// Migrated from: cash_management_facade_impl.dart
class CashManagementNotifier extends StateNotifier<CashManagementState> {
  final LocalCashManagementRepository _localRepository;
  final RemoteCashManagementRepository _remoteRepository;

  CashManagementNotifier({
    required LocalCashManagementRepository localRepository,
    required RemoteCashManagementRepository remoteRepository,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       super(const CashManagementState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<CashManagementModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        // Update state directly - Riverpod auto-notifies listeners
        state = state.copyWith(
          items: [...state.items, ...list],
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Insert a single cash management record
  Future<int> insert(CashManagementModel model) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(model, true);

      if (result > 0) {
        // Update state directly - Riverpod auto-notifies listeners
        state = state.copyWith(
          items: [...state.items, model],
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Update an existing cash management record
  Future<int> update(CashManagementModel model) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.update(model, true);

      if (result > 0) {
        // Update state directly - Riverpod auto-notifies listeners
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

  /// Get all items from local storage
  Future<List<CashManagementModel>> getListCashManagementModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListCashManagementModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<CashManagementModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        // Update state directly - Riverpod auto-notifies listeners
        final idsToRemove = list.map((e) => e.id).toSet();
        final remainingItems =
            state.items
                .where((item) => !idsToRemove.contains(item.id))
                .toList();
        state = state.copyWith(items: remainingItems, isLoading: false);
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
        // Update state directly - Riverpod auto-notifies listeners
        final remainingItems =
            state.items.where((item) => item.id != id).toList();
        state = state.copyWith(items: remainingItems, isLoading: false);
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
  Future<CashManagementModel?> getCashManagementModelById(String itemId) async {
    try {
      final items = await _localRepository.getListCashManagementModel();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => CashManagementModel(),
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

  /// Get cash management records that are not synced
  Future<List<CashManagementModel>> getListCashManagementNotSynced() async {
    try {
      return await _localRepository.getListCashManagementNotSynced();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get sum of pay in amounts that are not synced
  Future<double> getSumAmountPayInNotSynced() async {
    try {
      return await _localRepository.getSumAmountPayInNotSynced();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return 0.0;
    }
  }

  /// Get sum of pay out amounts that are not synced
  Future<double> getSumAmountPayOutNotSynced() async {
    try {
      return await _localRepository.getSumAmountPayOutNotSynced();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return 0.0;
    }
  }

  /// Get cash management list by current shift
  Future<List<CashManagementModel>> getCashManagementListByShift() async {
    try {
      return await _localRepository.getCashManagementListByShift();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get stream of pay out sum
  Stream<double> get getSumPayOutStream => _localRepository.getSumPayOutStream;

  /// Get stream of pay in sum
  Stream<double> get getSumPayInStream => _localRepository.getSumPayInStream;

  /// Notify changes to update streams
  Future<void> notifyChanges() async {
    await _localRepository.notifyChanges();
  }

  /// Emit sum amount pay out not synced
  Future<void> emitSumAmountPayOutNotSynced() async {
    await _localRepository.emitSumAmountPayOutNotSynced();
  }

  /// Emit sum amount pay in not synced
  Future<void> emitSumAmountPayInNotSynced() async {
    await _localRepository.emitSumAmountPayInNotSynced();
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<CashManagementModel> newData, {
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
    List<CashManagementModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        // Update state directly - merge upserted items with existing
        final upsertedIds = list.map((e) => e.id).toSet();
        final existingItems =
            state.items
                .where((item) => !upsertedIds.contains(item.id))
                .toList();
        state = state.copyWith(
          items: [...existingItems, ...list],
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Force reload items from database (use sparingly)
  Future<void> refresh() async {
    await getListCashManagementModel();
  }

  // ============================================================
  // UI State Management Methods (from old CashManagementNotifier)
  // ============================================================

  /// Get cash management list (getter for compatibility)
  List<CashManagementModel> get getCashManagementList => state.items;

  /// Set the entire cash management list
  void setListCashManagement(List<CashManagementModel> list) {
    state = state.copyWith(items: list);
  }

  /// Add or update multiple cash management records in the list
  void addOrUpdateList(List<CashManagementModel> list) {
    final currentItems = List<CashManagementModel>.from(state.items);

    for (CashManagementModel cashManagement in list) {
      int index = currentItems.indexWhere(
        (element) => element.id == cashManagement.id,
      );

      if (index != -1) {
        // if found, replace existing item with the new one
        currentItems[index] = cashManagement;
      } else {
        // not found
        currentItems.add(cashManagement);
      }
    }

    state = state.copyWith(items: currentItems);
  }

  /// Add or update a single cash management record
  void addOrUpdate(CashManagementModel cashManagement) {
    final currentItems = List<CashManagementModel>.from(state.items);
    int index = currentItems.indexWhere((c) => c.id == cashManagement.id);

    if (index != -1) {
      // if found, replace existing item with the new one
      currentItems[index] = cashManagement;
    } else {
      // not found
      currentItems.add(cashManagement);
    }

    state = state.copyWith(items: currentItems);
  }

  Future<List<CashManagementModel>> syncFromRemote() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Fetch all data from remote
      prints('Starting sync for ${CashManagementModel.modelName}...');
      final allItems = await _remoteRepository.fetchAllPaginated();
      prints(
        'Fetched ${allItems.length} ${CashManagementModel.modelName} from remote',
      );

      // Persist to local storage if data exists
      if (allItems.isNotEmpty) {
        final saved = await _localRepository.upsertBulk(
          allItems,
          isInsertToPending:
              false, // Don't track as pending - this is data FROM server
        );

        if (saved) {
          prints(
            'Successfully synced ${allItems.length} ${CashManagementModel.modelName} to local storage',
          );
          state = state.copyWith(items: allItems, isLoading: false);
          return allItems;
        } else {
          await LogUtils.error(
            'Failed to save synced ${CashManagementModel.modelName} to local storage',
            null,
          );
          state = state.copyWith(isLoading: false);
          return [];
        }
      } else {
        prints('No ${CashManagementModel.modelName} to sync');
        state = state.copyWith(isLoading: false);
        return [];
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      await LogUtils.error(
        'Error syncing ${CashManagementModel.modelName} from remote',
        e,
      );
      return [];
    }
  }
}

/// Provider for sorted items by createdAt (computed provider)
final sortedCashManagementsProvider = Provider<List<CashManagementModel>>((
  ref,
) {
  final items = ref.watch(cashManagementProvider).items;
  final sorted = List<CashManagementModel>.from(items);
  sorted.sort((a, b) {
    final aDate = a.createdAt ?? DateTime(1970);
    final bDate = b.createdAt ?? DateTime(1970);
    return bDate.compareTo(aDate); // Most recent first
  });
  return sorted;
});

/// Provider for cashManagement domain
final cashManagementProvider =
    StateNotifierProvider<CashManagementNotifier, CashManagementState>((ref) {
      return CashManagementNotifier(
        localRepository: ref.read(cashManagementLocalRepoProvider),
        remoteRepository: ref.read(cashManagementRemoteRepoProvider),
      );
    });

/// Provider for cashManagement by ID (family provider for indexed lookups)
final cashManagementByIdProvider =
    FutureProvider.family<CashManagementModel?, String>((ref, id) async {
      final notifier = ref.watch(cashManagementProvider.notifier);
      return notifier.getCashManagementModelById(id);
    });

/// Provider for pay out sum stream
final sumPayOutStreamProvider = StreamProvider<double>((ref) {
  final notifier = ref.watch(cashManagementProvider.notifier);
  return notifier.getSumPayOutStream;
});

/// Provider for pay in sum stream
final sumPayInStreamProvider = StreamProvider<double>((ref) {
  final notifier = ref.watch(cashManagementProvider.notifier);
  return notifier.getSumPayInStream;
});

/// Provider for cash management by shift
final cashManagementByShiftProvider = FutureProvider<List<CashManagementModel>>(
  (ref) async {
    final notifier = ref.watch(cashManagementProvider.notifier);
    return notifier.getCashManagementListByShift();
  },
);
