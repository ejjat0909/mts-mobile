import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/order_option_repository.dart';

/// Sync handler for OrderOption model
class OrderOptionSyncHandler implements SyncHandler {
  final LocalOrderOptionRepository _localRepository;

  /// Constructor with dependency injection
  OrderOptionSyncHandler({LocalOrderOptionRepository? localRepository})
    : _localRepository =
          localRepository ?? ServiceLocator.get<LocalOrderOptionRepository>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    OrderOptionModel model = OrderOptionModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(OrderOptionModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    OrderOptionModel model = OrderOptionModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(OrderOptionModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    OrderOptionModel model = OrderOptionModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(OrderOptionModel.modelName, meta);
  }
}
