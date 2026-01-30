import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/shift_repository.dart';
import 'package:mts/providers/shift/shift_providers.dart';

/// Provider for ShiftSyncHandler
final shiftSyncHandlerProvider = Provider<SyncHandler>((ref) {
  return ShiftSyncHandler(localRepository: ref.read(shiftLocalRepoProvider));
});

/// Sync handler for Shift model
class ShiftSyncHandler implements SyncHandler {
  final LocalShiftRepository _localRepository;

  /// Constructor with dependency injection
  ShiftSyncHandler({required LocalShiftRepository localRepository})
    : _localRepository = localRepository;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    ShiftModel model = ShiftModel.fromJson(data);

    List<ShiftModel> list = [model];
    for (ShiftModel shiftModel in list) {
      if (shiftModel.saleSummaryJson != null) {
        shiftModel.saleSummaryJson = shiftModel.saleSummaryJson;
      }
    }
    await _localRepository.upsertBulk(list, isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ShiftModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    ShiftModel model = ShiftModel.fromJson(data);

    List<ShiftModel> list = [model];
    for (ShiftModel shiftModel in list) {
      if (shiftModel.saleSummaryJson != null) {
        shiftModel.saleSummaryJson = shiftModel.saleSummaryJson;
      }
    }
    await _localRepository.upsertBulk(list, isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ShiftModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    ShiftModel model = ShiftModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ShiftModel.modelName, meta);
  }
}
