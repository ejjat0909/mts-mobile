import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/payment_type_repository.dart';
import 'package:mts/domain/repositories/remote/sync_repository.dart';
import 'package:mts/providers/payment_type_notifier.dart';

/// Sync handler for Payment model (using PaymentType)
class PaymentTypeSyncHandler implements SyncHandler {
  final LocalPaymentTypeRepository _localRepository;
  final PaymentTypeNotifier _paymentTypeNotifier;

  /// Constructor with dependency injection
  PaymentTypeSyncHandler({
    IWebService? webService,
    SyncRepository? syncRepository,
    LocalPaymentTypeRepository? localRepository,
    PaymentTypeNotifier? paymentTypeNotifier,
  }) : _localRepository =
           localRepository ?? ServiceLocator.get<LocalPaymentTypeRepository>(),
       _paymentTypeNotifier =
           paymentTypeNotifier ?? ServiceLocator.get<PaymentTypeNotifier>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    PaymentTypeModel model = PaymentTypeModel.fromJson(data);
    // Don't insert to pending changes for server data
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _paymentTypeNotifier.refreshPaymentTypes();

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(PaymentTypeModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    PaymentTypeModel model = PaymentTypeModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _paymentTypeNotifier.refreshPaymentTypes();
    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(PaymentTypeModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    PaymentTypeModel model = PaymentTypeModel.fromJson(data);

    await _localRepository.deleteBulk([
      model,
    ], false); // Don't insert to pending changes for server data
    _paymentTypeNotifier.refreshPaymentTypes();
    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(PaymentTypeModel.modelName, meta);
  }
}
