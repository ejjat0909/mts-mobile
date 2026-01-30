import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/discount_outlet/discount_outlet_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/discount_outlet_repository.dart';
import 'package:mts/providers/discount_outlet_notifier.dart';

class DiscountOutletSyncHandler implements SyncHandler {
  final LocalDiscountOutletRepository _localRepository;
  final DiscountOutletNotifier _discountOutletNotifier;

  DiscountOutletSyncHandler({
    LocalDiscountOutletRepository? localRepository,
    DiscountOutletNotifier? discountOutletNotifier,
  }) : _localRepository =
           localRepository ??
           ServiceLocator.get<LocalDiscountOutletRepository>(),
       _discountOutletNotifier =
           discountOutletNotifier ??
           ServiceLocator.get<DiscountOutletNotifier>();
  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    DiscountOutletModel model = DiscountOutletModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _discountOutletNotifier.addOrUpdate(model);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(DiscountOutletModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    DiscountOutletModel model = DiscountOutletModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _discountOutletNotifier.addOrUpdate(model);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(DiscountOutletModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    DiscountOutletModel model = DiscountOutletModel.fromJson(data);
    await _localRepository.deleteBulk([model], isInsertToPending: false);
    _discountOutletNotifier.remove(model.outletId!, model.discountId!);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(DiscountOutletModel.modelName, meta);
  }
}
