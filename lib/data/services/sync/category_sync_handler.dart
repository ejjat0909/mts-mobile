import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/repositories/local/local_category_repository_impl.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/category/category_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/category_repository.dart';

/// Provider for CategorySyncHandler
final categorySyncHandlerProvider = Provider<SyncHandler>((ref) {
  return CategorySyncHandler(
    localRepository: ref.read(categoryLocalRepoProvider),
  );
});

/// Sync handler for Category model
class CategorySyncHandler implements SyncHandler {
  final LocalCategoryRepository _localRepository;

  /// Constructor with dependency injection
  CategorySyncHandler({required LocalCategoryRepository localRepository,
  }) : _localRepository = localRepository;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    CategoryModel model = CategoryModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    // already update in HIVE
    // _categoryNotifier.addOrUpdate(model);
    MetaModel meta = MetaModel(lastSync: model.updatedAt?.toUtc());
    await SyncService.saveMetaData(CategoryModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    CategoryModel model = CategoryModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    // already update in HIVE
    // _categoryNotifier.addOrUpdate(model);
    MetaModel meta = MetaModel(lastSync: model.updatedAt?.toUtc());
    await SyncService.saveMetaData(CategoryModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    CategoryModel model = CategoryModel.fromJson(data);
    
    await _localRepository.deleteBulk([model], isInsertToPending: false);
    // _categoryNotifier.remove(model.id!);
    MetaModel meta = MetaModel(lastSync: model.updatedAt?.toUtc());
    await SyncService.saveMetaData(CategoryModel.modelName, meta);
  }
}
