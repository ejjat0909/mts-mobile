import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/storage/secured_storage_key.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/deleted/deleted_list_response_model.dart';
import 'package:mts/data/models/deleted/deleted_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/domain/repositories/remote/deleted_repository.dart';
import 'package:mts/domain/services/model_deletion_service.dart';
import 'package:mts/providers/deleted/deleted_state.dart';

/// StateNotifier for Deleted domain
///
/// Contains business logic for syncing deleted items from API and cascading deletions.
/// This provider orchestrates deletion strategies across multiple models.
class DeletedNotifier extends StateNotifier<DeletedState> {
  final DeletedRepository _remoteRepository;
  final IWebService _webService;
  final Ref _ref;

  DeletedNotifier({
    required DeletedRepository remoteRepository,
    required IWebService webService,
    required Ref ref,
  }) : _remoteRepository = remoteRepository,
       _webService = webService,
       _ref = ref,
       super(const DeletedState());

  // Note: Deleted model doesn't have local CRUD operations.
  // It only syncs from API and triggers cascading deletions in other models.

  /// Fetch deleted items from API with pagination and handle deletions
  ///
  /// This method:
  /// 1. Fetches all pages of deleted items from the API
  /// 2. Cascades deletions to corresponding models using deletion strategies
  /// 3. Saves metadata with last sync timestamp
  Future<List<DeletedModel>> syncFromRemote() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      List<DeletedModel> allDeletedItems = [];
      int currentPage = 1;
      int? lastPage;

      do {
        prints('Fetching deleted items page $currentPage');
        DeletedListResponseModel responseModel = await _webService.get(
          getDeletedListPaginated(currentPage.toString()),
        );

        if (responseModel.isSuccess && responseModel.data != null) {
          // Delete data from corresponding models
          await deleteDataFromThatModel(responseModel.data ?? []);
          allDeletedItems.addAll(responseModel.data!);

          if (responseModel.paginator != null) {
            lastPage = responseModel.paginator!.lastPage;
            prints(
              'Pagination DELETED: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
            );
          } else {
            break;
          }

          currentPage++;
        } else {
          prints(
            'Failed to fetch deleted items page $currentPage: ${responseModel.message}',
          );
          break;
        }
      } while (lastPage != null && currentPage <= lastPage);

      prints(
        'Fetched a total of ${allDeletedItems.length} deleted items from all pages',
      );

      // Save meta model (last sync at)
      MetaModel meta = MetaModel(lastSync: DateTime.now().toUtc());
      await SyncService.saveMetaData(DeletedModel.modelName, meta);

      state = state.copyWith(isLoading: false);
      return allDeletedItems;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      prints('Error fetching deleted items from API: $e');
      return [];
    }
  }

  /// Process deleted models and cascade deletions to corresponding tables
  ///
  /// For each deleted item, looks up the deletion strategy for that model type
  /// and executes it to remove the item from the appropriate table.
  Future<void> deleteDataFromThatModel(
    List<DeletedModel> listDeletedModels,
  ) async {
    for (DeletedModel dm in listDeletedModels) {
      String modelName = dm.model ?? "";
      String modelId = dm.modelId ?? "";

      if (modelName.isEmpty || modelId.isEmpty) {
        prints('Skipping deletion: empty modelName or modelId');
        continue;
      }

      if (!SSKey.allKeys.contains(modelName)) {
        prints('Model name "$modelName" not found in SSKey.allKeys');
        continue;
      }

      try {
        await _deleteModelById(modelName, modelId);
        prints('🗑️🗑️🗑️🗑️Successfully deleted $modelName with ID: $modelId');
      } catch (e) {
        prints('Error deleting $modelName with ID $modelId: $e');
      }
    }
  }

  /// Delete a model by ID using the registered deletion strategy
  Future<void> _deleteModelById(String modelName, String modelId) async {
    final deletionService = _ref.read(modelDeletionServiceProvider);
    try {
      await deletionService.deleteByModelName(modelName, modelId);
    } catch (e) {
      prints('Error in deletion service for $modelName: $e');
      rethrow;
    }
  }

  /// Get the resource for fetching deleted list with pagination
  Resource getDeletedListPaginated(String page) {
    return _remoteRepository.getDeletedListPaginated(page);
  }
}

/// Provider for deleted domain
final deletedProvider = StateNotifierProvider<DeletedNotifier, DeletedState>((
  ref,
) {
  return DeletedNotifier(
    remoteRepository: ServiceLocator.get<DeletedRepository>(),
    webService: ServiceLocator.get<IWebService>(),
    ref: ref,
  );
});
