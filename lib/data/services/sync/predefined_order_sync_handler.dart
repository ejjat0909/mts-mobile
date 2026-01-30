import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/predefined_order_repository.dart';

class PredefinedOrderSyncHandler implements SyncHandler {
  final LocalPredefinedOrderRepository _localRepository;

  PredefinedOrderSyncHandler({LocalPredefinedOrderRepository? localRepository})
    : _localRepository =
          localRepository ??
          ServiceLocator.get<LocalPredefinedOrderRepository>();
  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    PredefinedOrderModel model = PredefinedOrderModel.fromJson(data);

    await _localRepository.upsertBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(PredefinedOrderModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    PredefinedOrderModel model = PredefinedOrderModel.fromJson(data);

    await _localRepository.upsertBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(PredefinedOrderModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    PredefinedOrderModel model = PredefinedOrderModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(PredefinedOrderModel.modelName, meta);
  }
}
