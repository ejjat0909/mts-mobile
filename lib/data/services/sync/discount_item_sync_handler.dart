import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/discount_item/discount_item_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/discount_item_repository.dart';
import 'package:mts/providers/discount_item_notifier.dart';

class DiscountItemSyncHandler implements SyncHandler {
  final LocalDiscountItemRepository _localRepository;
  final DiscountItemNotifier _discountItemNotifier;

  DiscountItemSyncHandler({
    LocalDiscountItemRepository? localRepository,
    DiscountItemNotifier? discountItemNotifier,
  }) : _localRepository =
           localRepository ?? ServiceLocator.get<LocalDiscountItemRepository>(),
       _discountItemNotifier =
           discountItemNotifier ?? ServiceLocator.get<DiscountItemNotifier>();
  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    DiscountItemModel model = DiscountItemModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _discountItemNotifier.addOrUpdate(model);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(DiscountItemModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    DiscountItemModel model = DiscountItemModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _discountItemNotifier.addOrUpdate(model);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(DiscountItemModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    DiscountItemModel model = DiscountItemModel.fromJson(data);
    await _localRepository.deleteBulk([model], isInsertToPending: false);
    _discountItemNotifier.remove(model.itemId!, model.discountId!);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(DiscountItemModel.modelName, meta);
  }
}
