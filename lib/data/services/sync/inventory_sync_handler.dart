import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/inventory/inventory_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/inventory_repository.dart';

class InventorySyncHandler implements SyncHandler {
  final LocalInventoryRepository _localRepository;

  InventorySyncHandler({LocalInventoryRepository? localRepository})
    : _localRepository =
          localRepository ?? ServiceLocator.get<LocalInventoryRepository>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    InventoryModel model = InventoryModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(InventoryModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    InventoryModel model = InventoryModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(InventoryModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    InventoryModel model = InventoryModel.fromJson(data);
    // already handle in delete bulk
    //
    await _localRepository.deleteBulk([model], isInsertToPending: false);
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(InventoryModel.modelName, meta);
  }
}
