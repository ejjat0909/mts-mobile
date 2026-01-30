import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/outlet_repository.dart';
import 'package:mts/domain/repositories/remote/sync_repository.dart';
import 'package:mts/providers/outlet_notifier.dart';

/// Sync handler for Outlet model
class OutletSyncHandler implements SyncHandler {
  final LocalOutletRepository _localRepository;
  final OutletNotifier _outletNotifier;

  /// Constructor with dependency injection
  OutletSyncHandler({
    IWebService? webService,
    SyncRepository? syncRepository,
    LocalOutletRepository? localRepository,
    OutletNotifier? outletNotifier,
  }) : _localRepository =
           localRepository ?? ServiceLocator.get<LocalOutletRepository>(),
       _outletNotifier = outletNotifier ?? ServiceLocator.get<OutletNotifier>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    OutletModel model = OutletModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _outletNotifier.addOrUpdateList([model]);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(OutletModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    OutletModel model = OutletModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _outletNotifier.addOrUpdateList([model]);

    prints(
      'OUTLETTTTTTTTTTTTTTTTTTTTTTTTTTTTTT MODELLLLLLLLLLLL UPDATEEEEEEE : ${model.nextOrderNumber}',
    );
    prints(
      'OUTLETTTTTTTTTTTTTTTTTTTTTTTTTTTTTT MODELLLLLLLLLLLL UPDATEEEEEEE : ${DateTimeUtils.getDateTimeFormat(model.updatedAt)}',
    );

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(OutletModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    OutletModel model = OutletModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);
    _outletNotifier.remove(model.id!);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(OutletModel.modelName, meta);
  }
}
