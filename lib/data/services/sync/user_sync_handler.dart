import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/core/services/general_service.dart';
import 'package:mts/domain/repositories/local/user_repository.dart';
import 'package:mts/presentation/features/login/login_screen.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:provider/provider.dart';

/// Sync handler for User model
class UserSyncHandler implements SyncHandler {
  final LocalUserRepository _localRepository;
  final PermissionNotifier _permissionNotifier;
  final UserFacade _userFacade;

  /// Constructor with dependency injection
  UserSyncHandler({
    LocalUserRepository? localRepository,
    PermissionNotifier? permissionNotifier,
    UserFacade? userFacade,
  }) : _localRepository =
           localRepository ?? ServiceLocator.get<LocalUserRepository>(),
       _permissionNotifier =
           permissionNotifier ?? ServiceLocator.get<PermissionNotifier>(),
       _userFacade = userFacade ?? ServiceLocator.get<UserFacade>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    UserModel model = UserModel.fromJson(data);

    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _permissionNotifier.assignStaffPermission(model, false);
    // _userNotifier.addOrUpdateList([model]);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(UserModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    UserModel model = UserModel.fromJson(data);

    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _permissionNotifier.assignStaffPermission(model, false);
    // _userNotifier.addOrUpdateList([model]);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(UserModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    UserModel currentUser = ServiceLocator.get<UserModel>();
    UserModel model = UserModel.fromJson(data);
    await _localRepository.deleteBulk([model], isInsertToPending: false);
    _permissionNotifier.assignStaffPermission(model, true);
    final GeneralService generalFacade = ServiceLocator.get<GeneralService>();

    // if deleted current user = logout
    if (currentUser.id == model.id) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        await _userFacade.signOut((isSuccess, errorMessage) async {
          // force logout, no need to check success or not
          NavigationUtils.pushRemoveUntil(
            context,
            screen: const LoginScreen(),
            slideFromLeft: true,
          );

          context.read<MyNavigatorNotifier>().setPageIndex(0, '');
          await generalFacade.deleteDatabaseProcess();
        });
      }
    }
    // _userNotifier.remove(model.id!);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(UserModel.modelName, meta);
  }
}
