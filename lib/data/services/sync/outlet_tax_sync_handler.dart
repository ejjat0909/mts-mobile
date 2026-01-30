import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/outlet_tax/outlet_tax_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/outlet_tax_repository.dart';
import 'package:mts/providers/outlet_tax_notifier.dart';

class OutletTaxSyncHandler implements SyncHandler {
  final LocalOutletTaxRepository _localRepository;
  final OutletTaxNotifier _outletTaxNotifier;

  /// constructor
  OutletTaxSyncHandler({
    LocalOutletTaxRepository? localRepository,
    OutletTaxNotifier? outletTaxNotifier,
  }) : _localRepository =
           localRepository ?? ServiceLocator.get<LocalOutletTaxRepository>(),
       _outletTaxNotifier =
           outletTaxNotifier ?? ServiceLocator.get<OutletTaxNotifier>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    OutletTaxModel model = OutletTaxModel.fromJson(data);
    // Don't insert to pending changes for server data
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _outletTaxNotifier.addOrUpdate(model);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(OutletTaxModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    OutletTaxModel model = OutletTaxModel.fromJson(data);
    await _localRepository.upsertBulk([
      model,
    ], false); // Don't insert to pending changes for server data
    _outletTaxNotifier.addOrUpdate(model);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(OutletTaxModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    OutletTaxModel model = OutletTaxModel.fromJson(data);
    await _localRepository.deleteBulk([
      model,
    ], false); // Don't insert to pending changes for server data
    _outletTaxNotifier.remove(model.outletId!, model.taxId!);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(OutletTaxModel.modelName, meta);
  }
}
