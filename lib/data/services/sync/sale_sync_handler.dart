import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/error_log_repository.dart';
import 'package:mts/domain/repositories/local/sale_repository.dart';
import 'package:mts/domain/repositories/local/staff_repository.dart';

/// Sync handler for Sale model
class SaleSyncHandler implements SyncHandler {
  final LocalSaleRepository _localRepository;
  final LocalStaffRepository _localStaffRepisotory;
  final LocalErrorLogRepository _localErrorLogRepository;

  /// Constructor with dependency injection
  SaleSyncHandler({
    LocalSaleRepository? localRepository,
    LocalStaffRepository? localStaffRepisotory,
    LocalErrorLogRepository? localErrorLogRepository,
  }) : _localRepository =
           localRepository ?? ServiceLocator.get<LocalSaleRepository>(),
       _localStaffRepisotory =
           localStaffRepisotory ?? ServiceLocator.get<LocalStaffRepository>(),
       _localErrorLogRepository =
           localErrorLogRepository ??
           ServiceLocator.get<LocalErrorLogRepository>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    SaleModel model = SaleModel.fromJson(data);

    await _localRepository.upsertBulk([model], isInsertToPending: false);
    await _localRepository.upsertBulk(
      [model],
      isInsertToPending: false,
      isQueue: false,
    );

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(SaleModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    UserModel userModel = ServiceLocator.get<UserModel>();
    SaleModel model = SaleModel.fromJson(data);

    final currentStaff = await _localStaffRepisotory.getStaffModelByUserId(
      userModel.id?.toString() ?? '-1',
    );
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    await _localRepository.upsertBulk(
      [model],
      isInsertToPending: false,
      isQueue: false,
    );

    if (currentStaff.id == null) {
      await _localErrorLogRepository.createAndInsertErrorLog(
        "Staff id null at - PUSHER - handleUpdated - SaleSyncHandler",
      );
      return;
    }
    // a wait Future.delayed(Duration(milliseconds: 500));

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(SaleModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    SaleModel model = SaleModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(SaleModel.modelName, meta);
  }
}
