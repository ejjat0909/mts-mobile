import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/discount/discount_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/discount_repository.dart';
import 'package:mts/providers/discount_notifier.dart';

/// Sync handler for Discount model
class DiscountSyncHandler implements SyncHandler {
  final LocalDiscountRepository _localRepository;
  final DiscountNotifier _discountNotifier;

  /// Constructor with dependency injection
  DiscountSyncHandler({
    LocalDiscountRepository? localRepository,
    DiscountNotifier? discountNotifier,
  }) : _localRepository =
           localRepository ?? ServiceLocator.get<LocalDiscountRepository>(),

       _discountNotifier =
           discountNotifier ?? ServiceLocator.get<DiscountNotifier>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    DiscountModel model = DiscountModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _discountNotifier.addOrUpdate(model);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(DiscountModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    DiscountModel model = DiscountModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _discountNotifier.addOrUpdate(model);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(DiscountModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    DiscountModel model = DiscountModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);
    _discountNotifier.remove(model.id!);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(DiscountModel.modelName, meta);
  }
}
