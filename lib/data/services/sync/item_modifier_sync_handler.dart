import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/item_modifier/item_modifier_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/item_modifier_repository.dart';

/// Sync handler for ItemModifier model
class ItemModifierSyncHandler implements SyncHandler {
  final LocalItemModifierRepository _localRepository;

  /// Constructor with dependency injection
  ItemModifierSyncHandler({LocalItemModifierRepository? localRepository})
    : _localRepository =
          localRepository ?? ServiceLocator.get<LocalItemModifierRepository>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    ItemModifierModel model = ItemModifierModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _itemModifierNotifier.addOrUpdateList([model]);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ItemModifierModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    ItemModifierModel model = ItemModifierModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _itemModifierNotifier.addOrUpdateList([model]);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ItemModifierModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    ItemModifierModel model = ItemModifierModel.fromJson(data);
    await _localRepository.deleteBulk([model], isInsertToPending: false);
    _itemModifierNotifier.remove(model.itemId!, model.modifierId!);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ItemModifierModel.modelName, meta);
  }
}
