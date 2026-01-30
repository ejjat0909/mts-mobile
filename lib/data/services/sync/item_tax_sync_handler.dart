import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/item_tax/item_tax_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/item_tax_repository.dart';
import 'package:mts/providers/item_tax_notifier.dart';

class ItemTaxSyncHandler implements SyncHandler {
  final LocalItemTaxRepository _localRepository;
  final ItemTaxNotifier _itemTaxNotifier;

  /// constructor
  ItemTaxSyncHandler({
    LocalItemTaxRepository? localRepository,
    ItemTaxNotifier? itemTaxNotifier,
  }) : _localRepository =
           localRepository ?? ServiceLocator.get<LocalItemTaxRepository>(),
       _itemTaxNotifier =
           itemTaxNotifier ?? ServiceLocator.get<ItemTaxNotifier>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    ItemTaxModel model = ItemTaxModel.fromJson(data);
    // Don't insert to pending changes for server data
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _itemTaxNotifier.addOrUpdate(model);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ItemTaxModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    ItemTaxModel model = ItemTaxModel.fromJson(data);
    await _localRepository.upsertBulk([
      model,
    ], false); // Don't insert to pending changes for server data
    _itemTaxNotifier.addOrUpdate(model);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ItemTaxModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    ItemTaxModel model = ItemTaxModel.fromJson(data);
    await _localRepository.deleteBulk([
      model,
    ], false); // Don't insert to pending changes for server data
    _itemTaxNotifier.remove(model.itemId!, model.taxId!);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ItemTaxModel.modelName, meta);
  }
}
