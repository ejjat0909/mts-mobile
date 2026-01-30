import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/printer_setting_repository.dart';

/// Sync handler for PrinterSetting model
class PrinterSettingSyncHandler implements SyncHandler {
  final LocalPrinterSettingRepository _localRepository;
  final PrinterSettingFacade printerSettingFacade =
      ServiceLocator.get<PrinterSettingFacade>();

  /// Constructor with dependency injection
  PrinterSettingSyncHandler({LocalPrinterSettingRepository? localRepository})
    : _localRepository =
          localRepository ??
          ServiceLocator.get<LocalPrinterSettingRepository>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    PrinterSettingModel model = PrinterSettingModel.fromJson(data);
    List<PrinterSettingModel> list = [model];
    list = printerSettingFacade.prepareData(list);

    await _localRepository.upsertBulk(list, isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(PrinterSettingModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    PrinterSettingModel model = PrinterSettingModel.fromJson(data);
    List<PrinterSettingModel> list = [model];

    list = printerSettingFacade.prepareData(list);

    await _localRepository.upsertBulk(list, isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(PrinterSettingModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    PrinterSettingModel model = PrinterSettingModel.fromJson(data);
    List<PrinterSettingModel> list = [model];
    list = printerSettingFacade.prepareData(list);

    await _localRepository.deleteBulk(list, false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(PrinterSettingModel.modelName, meta);
  }
}
