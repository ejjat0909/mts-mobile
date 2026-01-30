import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/repositories/local/local_device_repository_impl.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/core/services/general_service.dart';
import 'package:mts/domain/repositories/local/device_repository.dart';
import 'package:mts/presentation/features/login/login_screen.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/device/device_providers.dart';
import 'package:mts/providers/user/user_providers.dart';

/// Provider for DeviceSyncHandler
final deviceSyncHandlerProvider = Provider<SyncHandler>((ref) {
  return DeviceSyncHandler(
    deviceNotifier: ref.read(deviceProvider.notifier),
    userNotifier: ref.read(userProvider.notifier),
  );
});

/// Sync handler for Device model
class DeviceSyncHandler implements SyncHandler {
  final DeviceNotifier _deviceNotifier;
  final UserNotifier _userNotifier;

  /// Constructor with dependency injection
  DeviceSyncHandler({
    required DeviceNotifier deviceNotifier,
    required UserNotifier userNotifier,
  }) : _deviceNotifier = deviceNotifier,
       _userNotifier = userNotifier;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    PosDeviceModel deviceModel = PosDeviceModel.fromJson(data);

    await _deviceNotifier.insertBulk([deviceModel], isInsertToPending: false);

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (deviceModel.updatedAt?.toUtc()));
    await SyncService.saveMetaData(PosDeviceModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    prints('DEVICE UPDATED DATA $data');
    PosDeviceModel deviceModel = PosDeviceModel.fromJson(data);
    await _deviceNotifier.insertBulk([deviceModel], isInsertToPending: false);

    PosDeviceModel? latestDeviceModel = _deviceNotifier.getLatestDeviceModel();
    if (latestDeviceModel.id == deviceModel.id) {
      if (deviceModel.isActive != null && !deviceModel.isActive!) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          await _userNotifier.signOut((isSuccess, errorMessage) async {
            if (isSuccess) {
              NavigationUtils.pushRemoveUntil(
                context,
                screen: const LoginScreen(),
                slideFromLeft: true,
              );

              context.read<MyNavigatorNotifier>().setPageIndex(0, '');
              await _generalFacade.deleteDatabaseProcess();
            }
          });
        }
      }
    }

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (deviceModel.updatedAt?.toUtc()));
    await SyncService.saveMetaData(PosDeviceModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    PosDeviceModel deviceModel = PosDeviceModel.fromJson(data);
    await _deviceNotifier.deleteBulk([deviceModel], isInsertToPending: false);

    PosDeviceModel? latestDeviceModel = _deviceNotifier.getLatestDeviceModel();
    if (latestDeviceModel.id == deviceModel.id) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        await _userNotifier.signOut((isSuccess, errorMessage) async {
          if (isSuccess) {
            NavigationUtils.pushRemoveUntil(
              context,
              screen: const LoginScreen(),
              slideFromLeft: true,
            );

            context.read<MyNavigatorNotifier>().setPageIndex(0, '');
            await _generalFacade.deleteDatabaseProcess();
          }
        });
      }
    }

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (deviceModel.updatedAt?.toUtc()));
    await SyncService.saveMetaData(PosDeviceModel.modelName, meta);
  }
}
