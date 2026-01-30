import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/staff_repository.dart';
import 'package:mts/presentation/features/after_login/after_login_screen.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/staff/staff_providers.dart';
import 'package:mts/providers/error_log/error_log_providers.dart';
import 'package:mts/domain/facades/error_log_facade.dart';

/// Provider for StaffSyncHandler
final staffSyncHandlerProvider = Provider<SyncHandler>((ref) {
  return StaffSyncHandler(
    localRepository: ref.read(staffLocalRepoProvider),
    myNavigatorNotifier: ref.read(myNavigatorProvider.notifier),
    errorLogFacade: ref.read(errorLogFacadeProvider),
  );
});

/// Sync handler for Staff model
class StaffSyncHandler implements SyncHandler {
  final LocalStaffRepository _localRepository;
  final MyNavigatorNotifier _myNavigator;
  final ErrorLogFacade _errorLogFacade;

  /// Constructor with dependency injection
  StaffSyncHandler({
    required LocalStaffRepository localRepository,
    required MyNavigatorNotifier myNavigatorNotifier,
    required ErrorLogFacade errorLogFacade,
  }) : _localRepository = localRepository,
       _myNavigator = myNavigatorNotifier,
       _errorLogFacade = errorLogFacade;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    StaffModel model = StaffModel.fromJson(data);

    if (model.id != null) {
      await _localRepository.upsertBulk([model], isInsertToPending: false);
    } else {
      await _errorLogFacade.createAndInsertErrorLog(
        "Staff id is null - PUSHER - handleCreated - StaffSyncHandler",
      );
    }

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(StaffModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    UserModel userModel = ServiceLocator.get<UserModel>();
    StaffModel model = StaffModel.fromJson(data);

    await _localRepository.upsertBulk([model], isInsertToPending: false);

    final currentStaff = await _localRepository.getStaffModelByUserId(
      userModel.id?.toString() ?? '-1',
    );

    if (currentStaff.id != null) {
      if (currentStaff.currentShiftId == null) {
        // auto logout sebab dah buang current shift from MH
        // Navigate to pinLock screen
        final context = navigatorKey.currentContext;
        if (context != null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) {
                return AfterLoginScreen(isFromHome: true);
              },
            ),
            (Route<dynamic> route) => false,
          );
        }
        _myNavigator.setPageIndex(2, 'pinLock'.tr());
      }
    } else {
      await _errorLogFacade.createAndInsertErrorLog(
        "Staff id is null - PUSHER - handleUpdated - StaffSyncHandler",
      );
    }

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(StaffModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    StaffModel model = StaffModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(StaffModel.modelName, meta);
  }
}
