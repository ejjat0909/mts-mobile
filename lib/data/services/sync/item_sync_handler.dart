import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/item_repository.dart';
import 'package:mts/domain/repositories/remote/sync_repository.dart';
import 'package:mts/providers/item_notifier.dart';
import 'package:mts/providers/item/item_providers.dart';

/// Provider for ItemSyncHandler
final itemSyncHandlerProvider = Provider<SyncHandler>((ref) {
  return ItemSyncHandler(
    localRepository: ref.read(itemLocalRepoProvider),
    itemNotifier: ref.read(itemProvider.notifier),
  );
});

/// Sync handler for Item model
class ItemSyncHandler implements SyncHandler {
  final LocalItemRepository _localRepository;
  final ItemNotifier _itemNotifier;

  /// Constructor with dependency injection
  ItemSyncHandler({
    required LocalItemRepository localRepository,
    required ItemNotifier itemNotifier,
  }) : _localRepository = localRepository,
       _itemNotifier = itemNotifier;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    ItemModel model = ItemModel.fromJson(data);
    // prints('handleCreated $data');

    await _localRepository.upsertBulk([model], isInsertToPending: false);
    // already update in HIVE
    _itemNotifier.initializeForSecondScreen([model]);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ItemModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    ItemModel model = ItemModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    // prints('handleUpdated $data');
    // already update in HIVE
    _itemNotifier.initializeForSecondScreen([model]);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ItemModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    ItemModel model = ItemModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);

    // already remove in HIVE
    // _itemNotifier.removeItem(model.id!);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ItemModel.modelName, meta);
  }
}
