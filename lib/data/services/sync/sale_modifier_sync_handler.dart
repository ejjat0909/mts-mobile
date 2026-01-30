import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/sale_modifier_repository.dart';

class SaleModifierSyncHandler implements SyncHandler {
  final LocalSaleModifierRepository _localRepository;

  SaleModifierSyncHandler({LocalSaleModifierRepository? localRepository})
    : _localRepository =
          localRepository ?? ServiceLocator.get<LocalSaleModifierRepository>();
  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    SaleModifierModel model = SaleModifierModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    await _localRepository.upsertBulk(
      [model],
      isInsertToPending: false,
      isQueue: false,
    );

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(SaleModifierModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    SaleModifierModel model = SaleModifierModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    await _localRepository.upsertBulk(
      [model],
      isInsertToPending: false,
      isQueue: false,
    );

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(SaleModifierModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    SaleModifierModel model = SaleModifierModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(SaleModifierModel.modelName, meta);
  }
}
