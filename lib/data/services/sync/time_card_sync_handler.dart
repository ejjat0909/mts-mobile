import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/time_card/timecard_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/timecard_repository.dart';

class TimeCardSyncHandler implements SyncHandler {
  final LocalTimecardRepository _localRepository;

  TimeCardSyncHandler({LocalTimecardRepository? localRepository})
    : _localRepository =
          localRepository ?? ServiceLocator.get<LocalTimecardRepository>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    TimecardModel model = TimecardModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(TimecardModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    TimecardModel model = TimecardModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(TimecardModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    TimecardModel model = TimecardModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(TimecardModel.modelName, meta);
  }
}
