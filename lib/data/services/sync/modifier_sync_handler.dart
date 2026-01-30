import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/modifier/modifier_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/modifier_repository.dart';
import 'package:mts/providers/modifier/modifier_providers.dart';

/// Provider for ModifierSyncHandler
final modifierSyncHandlerProvider = Provider<SyncHandler>((ref) {
  return ModifierSyncHandler(
    localRepository: ref.read(modifierLocalRepoProvider),
  );
});

/// Sync handler for Modifier model
class ModifierSyncHandler implements SyncHandler {
  final LocalModifierRepository _localRepository;

  /// Constructor with dependency injection
  ModifierSyncHandler({required LocalModifierRepository localRepository})
    : _localRepository = localRepository;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    ModifierModel model = ModifierModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);

    MetaModel mete = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ModifierModel.modelName, mete);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    ModifierModel model = ModifierModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);

    MetaModel mete = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ModifierModel.modelName, mete);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    ModifierModel model = ModifierModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);

    MetaModel mete = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ModifierModel.modelName, mete);
  }
}
