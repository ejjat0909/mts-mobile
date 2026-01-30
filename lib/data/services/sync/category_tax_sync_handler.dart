import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/repositories/local/local_category_tax_repository_impl.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/category_tax/category_tax_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/category_tax_repository.dart';
import 'package:mts/providers/category_tax/category_tax_providers.dart';

/// Provider for CategoryTaxSyncHandler
final categoryTaxSyncHandlerProvider = Provider<SyncHandler>((ref) {
  final notifier = ref.read(categoryTaxProvider.notifier);
  return CategoryTaxSyncHandler(
    localRepository: ref.read(categoryTaxLocalRepoProvider),
    onAddOrUpdate: notifier.addOrUpdate,
    onRemove: notifier.remove,
  );
});

class CategoryTaxSyncHandler implements SyncHandler {
  final LocalCategoryTaxRepository _localRepository;
  final void Function(CategoryTaxModel) onAddOrUpdate;
  final void Function(String categoryId, String taxId) onRemove;

  /// constructor
  CategoryTaxSyncHandler({
    required LocalCategoryTaxRepository localRepository,
    required this.onAddOrUpdate,
    required this.onRemove,
  }) : _localRepository = localRepository;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    CategoryTaxModel model = CategoryTaxModel.fromJson(data);
    // Don't insert to pending changes for server data
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    onAddOrUpdate(model);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(CategoryTaxModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    CategoryTaxModel model = CategoryTaxModel.fromJson(data);
    await _localRepository.upsertBulk([
      model,
    ], isInsertToPending: false); // Don't insert to pending changes for server data
    onAddOrUpdate(model);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(CategoryTaxModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    CategoryTaxModel model = CategoryTaxModel.fromJson(data);
    await _localRepository.deleteBulk([
      model,
    ], isInsertToPending: false); // Don't insert to pending changes for server data
    onRemove(model.categoryId!, model.taxId!);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(CategoryTaxModel.modelName, meta);
  }
}
