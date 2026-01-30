import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/tax_repository.dart';
import 'package:mts/providers/tax_notifier.dart';

/// Sync handler for Tax model
class TaxSyncHandler implements SyncHandler {
  final LocalTaxRepository _localRepository;
  final TaxNotifier _taxNotifier;

  /// Constructor with dependency injection
  TaxSyncHandler({
    LocalTaxRepository? localRepository,
    TaxNotifier? taxNotifier,
  }) : _localRepository =
           localRepository ?? ServiceLocator.get<LocalTaxRepository>(),
       _taxNotifier = taxNotifier ?? ServiceLocator.get<TaxNotifier>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    TaxModel model = TaxModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _taxNotifier.addOrUpdate(model);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(TaxModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    TaxModel model = TaxModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _taxNotifier.addOrUpdate(model);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(TaxModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    TaxModel model = TaxModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);
    _taxNotifier.remove(model.id!);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(TaxModel.modelName, meta);
  }
}
