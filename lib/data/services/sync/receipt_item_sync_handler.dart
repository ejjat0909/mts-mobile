import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/receipt_item_repository.dart';
import 'package:mts/providers/receipt_item/receipt_item_providers.dart';

/// Provider for ReceiptItemSyncHandler
final receiptItemSyncHandlerProvider = Provider<SyncHandler>((ref) {
  return ReceiptItemSyncHandler(
    localRepository: ref.read(receiptItemLocalRepoProvider),
  );
});

class ReceiptItemSyncHandler implements SyncHandler {
  final LocalReceiptItemRepository _localRepository;

  ReceiptItemSyncHandler({required LocalReceiptItemRepository localRepository})
    : _localRepository = localRepository;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    ReceiptItemModel model = ReceiptItemModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ReceiptItemModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    ReceiptItemModel model = ReceiptItemModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ReceiptItemModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    ReceiptItemModel model = ReceiptItemModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ReceiptItemModel.modelName, meta);
  }
}
