import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/outlet_payment_type/outlet_payment_type_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/outlet_payment_type_repository.dart';
import 'package:mts/providers/outlet_payment_type_notifier.dart';

class OutletPaymentTypeSyncHandler implements SyncHandler {
  final LocalOutletPaymentTypeRepository _localRepository;
  final OutletPaymentTypeNotifier _outletPaymentTypeNotifier;

  /// constructor
  OutletPaymentTypeSyncHandler({
    LocalOutletPaymentTypeRepository? localRepository,
    OutletPaymentTypeNotifier? outletPaymentTypeNotifier,
  }) : _localRepository =
           localRepository ??
           ServiceLocator.get<LocalOutletPaymentTypeRepository>(),
       _outletPaymentTypeNotifier =
           outletPaymentTypeNotifier ??
           ServiceLocator.get<OutletPaymentTypeNotifier>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    OutletPaymentTypeModel model = OutletPaymentTypeModel.fromJson(data);
    // Don't insert to pending changes for server data
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _outletPaymentTypeNotifier.addOrUpdate(model);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(OutletPaymentTypeModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    OutletPaymentTypeModel model = OutletPaymentTypeModel.fromJson(data);
    await _localRepository.upsertBulk([
      model,
    ], false); // Don't insert to pending changes for server data
    _outletPaymentTypeNotifier.addOrUpdate(model);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(OutletPaymentTypeModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    OutletPaymentTypeModel model = OutletPaymentTypeModel.fromJson(data);
    await _localRepository.deleteBulk([
      model,
    ], false); // Don't insert to pending changes for server data
    _outletPaymentTypeNotifier.remove(model.outletId!, model.paymentTypeId!);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(OutletPaymentTypeModel.modelName, meta);
  }
}
