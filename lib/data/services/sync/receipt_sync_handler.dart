import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/core/enum/receipt_status_enum.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/receipt_item_repository.dart';
import 'package:mts/domain/repositories/local/receipt_repository.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';
import 'package:mts/providers/receipt_item/receipt_item_providers.dart';

/// Provider for ReceiptSyncHandler
final receiptSyncHandlerProvider = Provider<SyncHandler>((ref) {
  return ReceiptSyncHandler(
    localRepository: ref.read(receiptLocalRepoProvider),
    localReceiptItemRepository: ref.read(receiptItemLocalRepoProvider),
  );
});

/// Sync handler for Receipt model
class ReceiptSyncHandler implements SyncHandler {
  final LocalReceiptRepository _localRepository;
  final LocalReceiptItemRepository _localReceiptItemRepository;

  /// Constructor with dependency injection
  ReceiptSyncHandler({
    required LocalReceiptRepository localRepository,
    required LocalReceiptItemRepository localReceiptItemRepository,
  }) : _localRepository = localRepository,
       _localReceiptItemRepository = localReceiptItemRepository;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    ReceiptModel model = ReceiptModel.fromJson(data);
    List<ReceiptModel> list = [model];

    await _localRepository.upsertBulk(list, isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ReceiptModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    ReceiptModel model = ReceiptModel.fromJson(data);
    List<ReceiptModel> list = [model];

    await _localRepository.upsertBulk(list, isInsertToPending: false);

    // handle if receipt status is cancelled, delete it
    if (model.receiptStatus == ReceiptStatusEnum.cancelled) {
      await _localReceiptItemRepository.delete(model.id ?? '-1', false);
      await _localReceiptItemRepository.deleteByReceiptId(model.id ?? '-1');
    }

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ReceiptModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    ReceiptModel model = ReceiptModel.fromJson(data);
    List<ReceiptModel> list = [model];

    await _localRepository.deleteBulk(list, false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ReceiptModel.modelName, meta);
  }
}
