import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/feature/feature_company_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/feature_company_repository.dart';
import 'package:mts/providers/feature_company_notifier.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';

/// Provider for FeatureCompanySyncHandler
final featureCompanySyncHandlerProvider = Provider<SyncHandler>((ref) {
  return FeatureCompanySyncHandler(
    localRepository: ref.read(featureCompanyLocalRepoProvider),
    featureCompanyNotifier: ref.read(featureCompanyProvider.notifier),
    onFeatureCompanyChanged: null, // Callback not needed with Riverpod
  );
});

/// Sync handler for feature company data
class FeatureCompanySyncHandler implements SyncHandler {
  final LocalFeatureCompanyRepository _localRepository;
  final FeatureCompanyNotifier _featureCompanyNotifier;
  final void Function()? _onFeatureCompanyChanged;

  /// Constructor
  FeatureCompanySyncHandler({
    required LocalFeatureCompanyRepository localRepository,
    required FeatureCompanyNotifier featureCompanyNotifier,
    void Function()? onFeatureCompanyChanged,
  }) : _localRepository = localRepository,
       _featureCompanyNotifier = featureCompanyNotifier,
       _onFeatureCompanyChanged = onFeatureCompanyChanged;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    final model = FeatureCompanyModel.fromJson(data);
    // Don't insert to pending changes for server data
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _featureCompanyNotifier.addOrUpdate(model);

    _onFeatureCompanyChanged?.call();

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(FeatureCompanyModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    final model = FeatureCompanyModel.fromJson(data);
    // Don't insert to pending changes for server data
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _featureCompanyNotifier.addOrUpdate(model);

    _onFeatureCompanyChanged?.call();

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(FeatureCompanyModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    final model = FeatureCompanyModel.fromJson(data);
    if (model.featureId != null && model.companyId != null) {
      // Don't insert to pending changes for server data
      await _localRepository.deleteBulk([model]);
      _featureCompanyNotifier.remove(model.featureId!, model.companyId!);
    }

    _onFeatureCompanyChanged?.call();

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(FeatureCompanyModel.modelName, meta);
  }
}
