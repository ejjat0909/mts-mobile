import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/sale_item_repository.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';

/// Provider for SaleItemSyncHandler
final saleItemSyncHandlerProvider = Provider<SyncHandler>((ref) {
  return SaleItemSyncHandler(
    localRepository: ref.read(saleItemLocalRepoProvider),
  );
});

/// Sync handler for SaleItem model
class SaleItemSyncHandler implements SyncHandler {
  final LocalSaleItemRepository _localRepository;

  /// Constructor with dependency injection
  SaleItemSyncHandler({required LocalSaleItemRepository localRepository})
    : _localRepository = localRepository;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    SaleItemModel model = SaleItemModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    await _localRepository.upsertBulk(
      [model],
      isInsertToPending: false,
      isQueue: false,
    );

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(SaleItemModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    SaleItemModel model = SaleItemModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    await _localRepository.upsertBulk(
      [model],
      isInsertToPending: false,
      isQueue: false,
    );

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(SaleItemModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    SaleItemModel model = SaleItemModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(SaleItemModel.modelName, meta);
  }
}
