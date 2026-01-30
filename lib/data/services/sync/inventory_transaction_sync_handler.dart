import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/inventory_transaction/inventory_transaction_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/inventory_transaction_repository.dart';

class InventoryTransactionSyncHandler implements SyncHandler {
  final LocalInventoryTransactionRepository _localRepository;

  InventoryTransactionSyncHandler({
    LocalInventoryTransactionRepository? localRepository,
  }) : _localRepository =
           localRepository ??
           ServiceLocator.get<LocalInventoryTransactionRepository>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    InventoryTransactionModel model = InventoryTransactionModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(InventoryTransactionModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    InventoryTransactionModel model = InventoryTransactionModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(InventoryTransactionModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    InventoryTransactionModel model = InventoryTransactionModel.fromJson(data);
    // already handle in delete bulk
    //
    await _localRepository.deleteBulk([model], isInsertToPending: false);
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(InventoryTransactionModel.modelName, meta);
  }
}
