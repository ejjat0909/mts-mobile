import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/feature/feature_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/feature_repository.dart';
import 'package:mts/domain/repositories/remote/sync_repository.dart';
import 'package:mts/providers/feature_notifier.dart';

/// Sync handler for Feature model
class FeatureSyncHandler implements SyncHandler {
  final LocalFeatureRepository _localRepository;
  final FeatureNotifier _featureNotifier;

  /// Constructor with dependency injection
  FeatureSyncHandler({
    SyncRepository? syncRepository,
    LocalFeatureRepository? localRepository,
    FeatureNotifier? featureNotifier,
  }) : _localRepository =
           localRepository ?? ServiceLocator.get<LocalFeatureRepository>(),
       _featureNotifier =
           featureNotifier ?? ServiceLocator.get<FeatureNotifier>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    FeatureModel model = FeatureModel.fromJson(data);
    // Insert or update the feature in the local database
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    // Update the notifier to refresh UI
    _featureNotifier.addOrUpdate(model);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(FeatureModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    FeatureModel model = FeatureModel.fromJson(data);
    // Insert or update the feature in the local database
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    // Update the notifier to refresh UI
    _featureNotifier.addOrUpdate(model);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(FeatureModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    FeatureModel feature = FeatureModel.fromJson(data);
    // Delete the feature from the local database
    await _localRepository.deleteBulk([feature], false);
    // Update the notifier to refresh UI
    _featureNotifier.remove(feature.id!);

    MetaModel meta = MetaModel(lastSync: (feature.updatedAt?.toUtc()));
    await SyncService.saveMetaData(FeatureModel.modelName, meta);
  }
}
