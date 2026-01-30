import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/item_representation/item_representation_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/services/media/asset_download_service.dart';
import 'package:mts/domain/repositories/local/item_representation_repository.dart';
import 'package:mts/providers/item_representation/item_representation_providers.dart';

/// Provider for ItemRepresentationSyncHandler
final itemRepresentationSyncHandlerProvider = Provider<SyncHandler>((ref) {
  return ItemRepresentationSyncHandler(
    localRepository: ref.read(itemRepresentationLocalRepoProvider),
    assetDownloadService: ref.read(assetDownloadServiceProvider),
  );
});

/// Sync handler for ItemRepresentation model
class ItemRepresentationSyncHandler implements SyncHandler {
  final LocalItemRepresentationRepository _localRepository;
  final AssetDownloadService _assetDownloadService;

  /// Constructor with dependency injection
  ItemRepresentationSyncHandler({
    required LocalItemRepresentationRepository localRepository,
    required AssetDownloadService assetDownloadService,
  }) : _localRepository = localRepository,
       _assetDownloadService = assetDownloadService;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    ItemRepresentationModel model = ItemRepresentationModel.fromJson(data);

    await _localRepository.upsertBulk([model], isInsertToPending: false);

    // already upate in HIVE
    // _itemNotifier.addOrUpdateListIR([model]);
    // wait until the hive box update to sql
    await Future.delayed(const Duration(milliseconds: 200));
    await _assetDownloadService.downloadPendingAssets();

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ItemRepresentationModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    ItemRepresentationModel model = ItemRepresentationModel.fromJson(data);

    await _localRepository.upsertBulk([model], isInsertToPending: false);
    // already upate in HIVE
    // _itemNotifier.addOrUpdateListIR([model]);
    // wait until the hive box update to sql
    await Future.delayed(const Duration(milliseconds: 200));
    await _assetDownloadService.downloadPendingAssets();

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ItemRepresentationModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    ItemRepresentationModel itemRepresentation =
        ItemRepresentationModel.fromJson(data);

    // Delete the item representation from the local database
    await _localRepository.deleteBulk([itemRepresentation], false);

    // remove from notifier
    // already remove from hive
    // _itemNotifier.removeIR(itemRepresentation.id!);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: itemRepresentation.updatedAt);
    await SyncService.saveMetaData(ItemRepresentationModel.modelName, meta);
  }
}
