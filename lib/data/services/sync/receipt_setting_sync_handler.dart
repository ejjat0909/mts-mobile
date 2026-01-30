import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/receipt_setting/receipt_settings_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/services/media/asset_download_service.dart';
import 'package:mts/domain/repositories/local/receipt_settings_repository.dart';
import 'package:mts/providers/receipt_settings/receipt_settings_providers.dart';

/// Provider for ReceiptSettingSyncHandler
final receiptSettingSyncHandlerProvider = Provider<SyncHandler>((ref) {
  return ReceiptSettingSyncHandler(
    localRepository: ref.read(receiptSettingsLocalRepoProvider),
    assetDownloadService: ref.read(assetDownloadServiceProvider),
  );
});

class ReceiptSettingSyncHandler implements SyncHandler {
  final LocalReceiptSettingsRepository _localRepository;
  final AssetDownloadService _assetDownloadService;

  ReceiptSettingSyncHandler({
    required LocalReceiptSettingsRepository localRepository,
    required AssetDownloadService assetDownloadService,
  }) : _localRepository = localRepository,
       _assetDownloadService = assetDownloadService;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    ReceiptSettingsModel model = ReceiptSettingsModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);

    await _assetDownloadService.downloadPendingAssets();

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ReceiptSettingsModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    ReceiptSettingsModel model = ReceiptSettingsModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);

    await _assetDownloadService.downloadPendingAssets();
    prints("RECEIPT SETTING UPDATEEEEEEEEEEEEEEEEEEE");
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ReceiptSettingsModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    ReceiptSettingsModel model = ReceiptSettingsModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(ReceiptSettingsModel.modelName, meta);
  }
}
