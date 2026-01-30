import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/services/media/asset_download_service.dart';
import 'package:mts/domain/repositories/local/slideshow_repository.dart';
import 'package:mts/providers/slideshow/slideshow_providers.dart';

/// Provider for SlideshowSyncHandler
final slideshowSyncHandlerProvider = Provider<SyncHandler>((ref) {
  return SlideshowSyncHandler(
    localRepository: ref.read(slideshowLocalRepoProvider),
    assetDownloadService: ref.read(assetDownloadServiceProvider),
  );
});

/// Sync handler for SecondDisplay model
class SlideshowSyncHandler implements SyncHandler {
  final LocalSlideshowRepository _localRepository;
  final AssetDownloadService _assetDownloadService;

  /// Constructor with dependency injection
  SlideshowSyncHandler({
    required LocalSlideshowRepository localRepository,
    required AssetDownloadService assetDownloadService,
  }) : _localRepository = localRepository,
       _assetDownloadService = assetDownloadService;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    SlideshowModel model = SlideshowModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);

    await _assetDownloadService.downloadPendingAssets();

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(SlideshowModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    SlideshowModel model = SlideshowModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    prints(model.toJson());

    await _assetDownloadService.downloadPendingAssets();

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(SlideshowModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    SlideshowModel model = SlideshowModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(SlideshowModel.modelName, meta);
  }
}
