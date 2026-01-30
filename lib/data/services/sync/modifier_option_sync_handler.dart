import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/modifier_option_repository.dart';
import 'package:mts/providers/modifier_option_notifier.dart';
import 'package:mts/providers/modifier_option/modifier_option_providers.dart';

/// Provider for ModifierOptionSyncHandler
final modifierOptionSyncHandlerProvider = Provider<SyncHandler>((ref) {
  return ModifierOptionSyncHandler(
    localRepository: ref.read(modifierOptionLocalRepoProvider),
  );
});

class ModifierOptionSyncHandler implements SyncHandler {
  final LocalModifierOptionRepository _localRepository;
  final ModifierOptionNotifier _modifierOptionNotifier;

  ModifierOptionSyncHandler({
    required LocalModifierOptionRepository localRepository,
    required ModifierOptionNotifier modifierOptionNotifier,
  }) : _localRepository = localRepository,
       _modifierOptionNotifier = modifierOptionNotifier;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    ModifierOptionModel model = ModifierOptionModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _modifierOptionNotifier.initializeForSecondScreen([model]);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ModifierOptionModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    ModifierOptionModel model = ModifierOptionModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _modifierOptionNotifier.initializeForSecondScreen([model]);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ModifierOptionModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    ModifierOptionModel model = ModifierOptionModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ModifierOptionModel.modelName, meta);
  }
}
