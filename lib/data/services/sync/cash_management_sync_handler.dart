import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/repositories/local/local_cash_management_repository_impl.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/cash_management/cash_management_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/cash_management_repository.dart';

/// Provider for CashManagementSyncHandler
final cashManagementSyncHandlerProvider = Provider<SyncHandler>((ref) {
  return CashManagementSyncHandler(
    localRepository: ref.read(cashManagementLocalRepoProvider),
  );
});

class CashManagementSyncHandler implements SyncHandler {
  final LocalCashManagementRepository _localRepository;

  CashManagementSyncHandler({
    required LocalCashManagementRepository localRepository,
  }) : _localRepository = localRepository;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    CashManagementModel model = CashManagementModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(CashManagementModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    CashManagementModel model = CashManagementModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(CashManagementModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    CashManagementModel model = CashManagementModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(CashManagementModel.modelName, meta);
  }
}
