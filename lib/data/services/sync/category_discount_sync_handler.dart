import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/repositories/local/local_category_discount_repository_impl.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/category_discount/category_discount_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/category_discount_repository.dart';
import 'package:mts/providers/category_discount/category_discount_providers.dart';

/// Provider for CategoryDiscountSyncHandler
final categoryDiscountSyncHandlerProvider = Provider<SyncHandler>((ref) {
  final notifier = ref.read(categoryDiscountProvider.notifier);
  return CategoryDiscountSyncHandler(
    localRepository: ref.read(categoryDiscountLocalRepoProvider),
    onAddOrUpdate: notifier.addOrUpdate,
    onRemove: notifier.remove,
  );
});

class CategoryDiscountSyncHandler implements SyncHandler {
  final LocalCategoryDiscountRepository _localRepository;
  final void Function(CategoryDiscountModel) onAddOrUpdate;
  final void Function(String categoryId, String discountId) onRemove;

  CategoryDiscountSyncHandler({
    required LocalCategoryDiscountRepository localRepository,
    required this.onAddOrUpdate,
    required this.onRemove,
  }) : _localRepository = localRepository;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    CategoryDiscountModel model = CategoryDiscountModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    onAddOrUpdate(model);

    MetaModel meta = MetaModel(lastSync: model.updatedAt?.toUtc());
    await SyncService.saveMetaData(CategoryDiscountModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    CategoryDiscountModel model = CategoryDiscountModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    onAddOrUpdate(model);

    MetaModel meta = MetaModel(lastSync: model.updatedAt?.toUtc());
    await SyncService.saveMetaData(CategoryDiscountModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    CategoryDiscountModel model = CategoryDiscountModel.fromJson(data);
    await _localRepository.deleteBulk([model], isInsertToPending: false);
    onRemove(model.categoryId!, model.discountId!);

    MetaModel meta = MetaModel(lastSync: model.updatedAt?.toUtc());
    await SyncService.saveMetaData(CategoryDiscountModel.modelName, meta);
  }
}
