import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/sale_modifier_option_repository.dart';

class SaleModifierOptionSyncHandler implements SyncHandler {
  final LocalSaleModifierOptionRepository _localRepository;

  SaleModifierOptionSyncHandler({
    LocalSaleModifierOptionRepository? localRepository,
  }) : _localRepository =
           localRepository ??
           ServiceLocator.get<LocalSaleModifierOptionRepository>();
  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    SaleModifierOptionModel model = SaleModifierOptionModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    await _localRepository.upsertBulk(
      [model],
      isInsertToPending: false,
      isQueue: false,
    );

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(SaleModifierOptionModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    SaleModifierOptionModel model = SaleModifierOptionModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    await _localRepository.upsertBulk(
      [model],
      isInsertToPending: false,
      isQueue: false,
    );

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(SaleModifierOptionModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    SaleModifierOptionModel model = SaleModifierOptionModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(SaleModifierOptionModel.modelName, meta);
  }
}
