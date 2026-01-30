import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/core/enum/print_cache_status_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/print_receipt_cache_repository.dart';

class PrintReceiptCacheSyncHandler implements SyncHandler {
  final LocalPrintReceiptCacheRepository _localRepository;
  final PrintReceiptCacheNotifier _printReceiptCacheNotifier;
  final PrinterSettingFacade _printerSettingFacade;

  PrintReceiptCacheSyncHandler({
    LocalPrintReceiptCacheRepository? localRepository,
    PrintReceiptCacheNotifier? printReceiptCacheNotifier,
    PrinterSettingFacade? printerSettingFacade,
  }) : _localRepository =
           localRepository ??
           ServiceLocator.get<LocalPrintReceiptCacheRepository>(),
       _printReceiptCacheNotifier =
           printReceiptCacheNotifier ??
           ServiceLocator.get<PrintReceiptCacheNotifier>(),
       _printerSettingFacade =
           printerSettingFacade ?? ServiceLocator.get<PrinterSettingFacade>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    PrintReceiptCacheModel model = PrintReceiptCacheModel.fromJson(data);

    PosDeviceModel posDeviceModel = ServiceLocator.get<PosDeviceModel>();
    if (model.status == PrintCacheStatusEnum.pending) {
      if (model.printData?.printerSettingModel?.printOrders == true) {
        if (model.posDeviceId == posDeviceModel.id) {
          prints("🥮🥮🥮🥮🥮🥮🥮 ${model.toJson()}");
          await _localRepository.upsertBulk([model], isInsertToPending: false);
          await _localRepository.upsertBulk(
            [model],
            isInsertToPending: false,
            isQueue: false,
          );
          _printReceiptCacheNotifier.addOrUpdate(model);

          await _printerSettingFacade.onHandlePrintVoidAndKitchen(
            onSuccess: () {
              prints('✅ Print void and kitchen sync completed successfully');
            },
            onError: (message, ipAdd) {
              prints(
                '❌ Print void and kitchen sync error: $message, IP: $ipAdd',
              );
            },
            departmentType: model.printType,
            onSuccessPrintReceiptCache: (list) {
              prints('✅ Print cache models processed: ${list.length}');
            },
          );

          MetaModel meta = MetaModel(lastSync: model.updatedAt?.toUtc());
          await SyncService.saveMetaData(
            PrintReceiptCacheModel.modelName,
            meta,
          );
        }
      }
    }
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    PrintReceiptCacheModel model = PrintReceiptCacheModel.fromJson(data);
    PosDeviceModel posDeviceModel = ServiceLocator.get<PosDeviceModel>();
    if (model.status == PrintCacheStatusEnum.pending) {
      if (model.printData?.printerSettingModel?.printOrders == true) {
        if (model.posDeviceId == posDeviceModel.id) {
          prints("🥮🥮🥮🥮🥮🥮🥮 ${model.toJson()}");
          await _localRepository.upsertBulk([model], isInsertToPending: false);
          await _localRepository.upsertBulk(
            [model],
            isInsertToPending: false,
            isQueue: false,
          );
          _printReceiptCacheNotifier.addOrUpdate(model);

          await _printerSettingFacade.onHandlePrintVoidAndKitchen(
            onSuccess: () {
              prints('✅ Print void and kitchen sync completed successfully');
            },
            onError: (message, ipAdd) {
              prints(
                '❌ Print void and kitchen sync error: $message, IP: $ipAdd',
              );
            },
            departmentType: model.printType,
            onSuccessPrintReceiptCache: (list) {
              prints('✅ Print cache models processed: ${list.length}');
            },
          );

          MetaModel meta = MetaModel(lastSync: model.updatedAt?.toUtc());
          await SyncService.saveMetaData(
            PrintReceiptCacheModel.modelName,
            meta,
          );
        }
      }
    }
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    PrintReceiptCacheModel model = PrintReceiptCacheModel.fromJson(data);
    await _localRepository.deleteBulk([model], isInsertToPending: false);

    _printReceiptCacheNotifier.remove(model.id!);

    MetaModel meta = MetaModel(lastSync: model.updatedAt?.toUtc());
    await SyncService.saveMetaData(PrintReceiptCacheModel.modelName, meta);
  }
}
