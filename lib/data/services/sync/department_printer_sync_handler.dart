import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/department_printer_repository.dart';

class DepartmentPrinterSyncHandler implements SyncHandler {
  final LocalDepartmentPrinterRepository _localRepository;

  DepartmentPrinterSyncHandler({
    LocalDepartmentPrinterRepository? localRepository,
  }) : _localRepository =
           localRepository ??
           ServiceLocator.get<LocalDepartmentPrinterRepository>();
  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    DepartmentPrinterModel model = DepartmentPrinterModel.fromJson(data);

    await _localRepository.upsertBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(DepartmentPrinterModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    DepartmentPrinterModel model = DepartmentPrinterModel.fromJson(data);

    await _localRepository.upsertBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(DepartmentPrinterModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    DepartmentPrinterModel model = DepartmentPrinterModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(DepartmentPrinterModel.modelName, meta);
  }
}
