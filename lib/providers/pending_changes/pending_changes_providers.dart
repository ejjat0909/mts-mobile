import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_sync_request_model.dart';
import 'package:mts/data/models/pending_process/pending_process_list_response_model.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/remote/sync_repository.dart';
import 'package:mts/providers/pending_changes/pending_changes_state.dart';

/// StateNotifier for PendingChanges domain
///
/// Migrated from: pending_changes_facade_impl.dart
class PendingChangesNotifier extends StateNotifier<PendingChangesState> {
  final LocalPendingChangesRepository _localRepository;
  final IWebService _webService;
  final SyncRepository _syncRepository;

  PendingChangesNotifier({
    required LocalPendingChangesRepository localRepository,
    required IWebService webService,
    required SyncRepository syncRepository,
  }) : _localRepository = localRepository,
       _webService = webService,
       _syncRepository = syncRepository,
       super(const PendingChangesState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(List<PendingChangesModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(list);

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
  Future<List<PendingChangesModel>> getListPendingChanges() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListPendingChanges();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Get items (sync version for state access)
  List<PendingChangesModel> getListPendingChangesSync() {
    return state.items;
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<PendingChangesModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      bool allDeleted = true;
      for (var item in list) {
        if (item.id != null) {
          final result = await _localRepository.delete(item.id!);
          if (result <= 0) {
            allDeleted = false;
          }
        } else {
          allDeleted = false;
        }
      }

      if (allDeleted) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return allDeleted;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete all items from local storage
  Future<void> deleteAll() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _localRepository.deleteAll();
      state = state.copyWith(items: [], isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Delete items where modelId is null (cleanup operation)
  Future<int> deleteWhereModelIdIsNull() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteWhereModelIdIsNull();

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

  /// Delete a single item by ID
  Future<int> delete(String id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.delete(id);

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
  Future<PendingChangesModel?> getPendingChangesModelById(String itemId) async {
    try {
      final items = await _localRepository.getListPendingChanges();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => PendingChangesModel(),
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

  /// Sync pending changes to server with batching and retry logic
  ///
  /// Sends items to server in batches of 50:
  /// - If all 50 succeed: they are deleted
  /// - If some have errors: they stay in local storage to retry next sync
  /// - If entire batch fails: retry items individually
  Future<bool> syncPendingChangesList() async {
    try {
      state = state.copyWith(isSyncing: true);

      final pendingChanges = await getListPendingChanges().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          prints('⚠️ Getting pending changes list timed out');
          return [];
        },
      );

      if (pendingChanges.isEmpty) {
        prints('No pending changes found.');
        state = state.copyWith(isSyncing: false);
        return true;
      }

      prints('Found ${pendingChanges.length} pending changes to sync');
      prints(pendingChanges.map((e) => e.modelName).toList());
      prints(pendingChanges.map((e) => e.toJson()).toList());

      bool overallSuccess = true;
      List<PendingChangesModel> allProcessed = [];
      const int batchSize = 50;

      // Process items in batches of 50
      for (int i = 0; i < pendingChanges.length; i += batchSize) {
        final int end =
            (i + batchSize > pendingChanges.length)
                ? pendingChanges.length
                : i + batchSize;
        final List<PendingChangesModel> batch = pendingChanges.sublist(i, end);
        final int batchNumber = (i ~/ batchSize) + 1;
        final int totalBatches =
            (pendingChanges.length + batchSize - 1) ~/ batchSize;

        prints(
          'Processing batch $batchNumber of $totalBatches (${batch.length} items)',
        );

        try {
          var requestModel = PendingChangesSyncRequestModel(
            pendingChanges: batch,
          );

          var resource = _syncRepository.syncPendingChanges(requestModel);
          PendingProcessListResponseModel response = await _webService
              .post(resource)
              .timeout(
                const Duration(seconds: 60),
                onTimeout: () {
                  prints(
                    '⚠️ Batch $batchNumber sync timed out after 60 seconds',
                  );
                  return PendingProcessListResponseModel({
                    'is_success': false,
                    'message': 'Request timed out',
                  });
                },
              );

          List<PendingChangesModel>? processed = response.data?.processed;
          List<String> errorIds = [];

          if (response.data?.errors != null &&
              response.data!.errors!.isNotEmpty) {
            errorIds =
                response.data!.errors!
                    .map((e) => e.id ?? '')
                    .where((id) => id.isNotEmpty)
                    .toList();
          }

          if (processed != null && processed.isNotEmpty) {
            prints(
              '✓ Batch $batchNumber: ${processed.length}/${batch.length} items successfully processed',
            );
            allProcessed.addAll(processed);
          }

          if (errorIds.isNotEmpty) {
            prints('❌ Batch $batchNumber: ${errorIds.length} items had errors');
            prints(response.data?.errors?.map((e) => e.error).toList());

            for (var errorId in errorIds) {
              final erroredItem = batch.firstWhere(
                (item) => item.id == errorId,
                orElse: () => PendingChangesModel(),
              );
              if (erroredItem.id != null) {
                prints(
                  '✗ Error: ${erroredItem.modelName} (${erroredItem.id}) - will retry next sync',
                );
              }
            }
          }

          if (!response.isSuccess && processed == null && errorIds.isEmpty) {
            prints('⚠️ Batch $batchNumber failed: ${response.message}');
            prints('Retrying batch $batchNumber items individually...');

            for (int j = 0; j < batch.length; j++) {
              final PendingChangesModel item = batch[j];

              try {
                final singleRequestModel = PendingChangesSyncRequestModel(
                  pendingChanges: [item],
                );
                final singleResource = _syncRepository.syncPendingChanges(
                  singleRequestModel,
                );
                PendingProcessListResponseModel singleResponse =
                    await _webService
                        .post(singleResource)
                        .timeout(
                          const Duration(seconds: 20),
                          onTimeout: () {
                            return PendingProcessListResponseModel({
                              'is_success': false,
                              'message': 'Request timed out',
                            });
                          },
                        );

                List<PendingChangesModel>? singleProcessed =
                    singleResponse.data?.processed;
                if (singleProcessed != null && singleProcessed.isNotEmpty) {
                  prints(
                    '✓ Item ${i + j + 1} (${item.modelName}): successfully processed',
                  );
                  allProcessed.addAll(singleProcessed);
                } else {
                  prints('✗ Item ${i + j + 1} (${item.modelName}): failed');
                }
              } catch (e) {
                prints('❌ Error processing item ${i + j + 1}: $e');
              }
            }
          }
        } catch (e) {
          prints('❌ Error processing batch $batchNumber: $e');
        }
      }

      // Delete all successfully processed items at once
      if (allProcessed.isNotEmpty) {
        prints('Deleting ${allProcessed.length} successfully processed items');
        await deleteBulk(allProcessed);
      }

      state = state.copyWith(isSyncing: false);
      return overallSuccess;
    } on Exception catch (e) {
      prints('An error occurred while syncing pending changes: $e');
      await LogUtils.error(
        'An error occurred while syncing pending changes: $e',
      );
      state = state.copyWith(isSyncing: false);
      return false;
    }
  }

  /// Set syncing state
  void setSyncing(bool syncing) {
    state = state.copyWith(isSyncing: syncing);
  }

  /// Internal helper to load items and update state
  Future<void> _loadItems() async {
    try {
      final items = await _localRepository.getListPendingChanges();
      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider for sorted items (computed provider)
final sortedPendingChangessProvider = Provider<List<PendingChangesModel>>((
  ref,
) {
  final items = ref.watch(pendingChangesProvider).items;
  final sorted = List<PendingChangesModel>.from(items);
  sorted.sort(
    (a, b) => (a.modelName ?? '').toLowerCase().compareTo(
      (b.modelName ?? '').toLowerCase(),
    ),
  );
  return sorted;
});

/// Provider for pendingChanges domain
final pendingChangesProvider =
    StateNotifierProvider<PendingChangesNotifier, PendingChangesState>((ref) {
      return PendingChangesNotifier(
        localRepository: ServiceLocator.get<LocalPendingChangesRepository>(),
        webService: ServiceLocator.get<IWebService>(),
        syncRepository: ServiceLocator.get<SyncRepository>(),
      );
    });

/// Provider for pendingChanges by ID (family provider for indexed lookups)
final pendingChangesByIdProvider =
    FutureProvider.family<PendingChangesModel?, String>((ref, id) async {
      final notifier = ref.watch(pendingChangesProvider.notifier);
      return notifier.getPendingChangesModelById(id);
    });

/// Provider for pendingChanges by ID (sync version - computed provider)
final pendingChangesByIdSyncProvider =
    Provider.family<PendingChangesModel?, String>((ref, id) {
      final items = ref.watch(pendingChangesProvider).items;
      try {
        return items.firstWhere((item) => item.id == id);
      } catch (e) {
        return null;
      }
    });

/// Provider for pendingChanges by operation type
final pendingChangesByOperationProvider =
    Provider.family<List<PendingChangesModel>, String>((ref, operation) {
      final items = ref.watch(pendingChangesProvider).items;
      return items.where((item) => item.operation == operation).toList();
    });

/// Provider for pendingChanges by model name
final pendingChangesByModelNameProvider =
    Provider.family<List<PendingChangesModel>, String>((ref, modelName) {
      final items = ref.watch(pendingChangesProvider).items;
      return items.where((item) => item.modelName == modelName).toList();
    });

/// Provider for pending changes count
final pendingChangesCountProvider = Provider<int>((ref) {
  final items = ref.watch(pendingChangesProvider).items;
  return items.length;
});

/// Provider for checking if there are pending changes
final hasPendingChangesProvider = Provider<bool>((ref) {
  final items = ref.watch(pendingChangesProvider).items;
  return items.isNotEmpty;
});

/// Provider for checking if pending changes is loading
final isPendingChangesLoadingProvider = Provider<bool>((ref) {
  return ref.watch(pendingChangesProvider).isLoading;
});

/// Provider for checking if pending changes is syncing
final isPendingChangesSyncingProvider = Provider<bool>((ref) {
  return ref.watch(pendingChangesProvider).isSyncing;
});
