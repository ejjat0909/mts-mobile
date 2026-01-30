import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/domain/repositories/local/staff_repository.dart';
import 'package:mts/domain/repositories/local/user_repository.dart';
import 'package:mts/providers/error_log/error_log_providers.dart';
import 'package:mts/providers/staff/staff_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/network_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/cash_management/cash_management_model.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/staff/staff_list_response_model.dart';
import 'package:mts/data/models/user/user_response_model.dart';
import 'package:mts/data/repositories/local/local_staff_repository_impl.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/remote/staff_repository.dart';
import 'package:mts/providers/sync_real_time/sync_real_time_providers.dart';

class StaffNotifier extends StateNotifier<StaffState> {
  final LocalStaffRepository _localRepository;
  final StaffRepository _remoteRepository;
  final IWebService _webService;
  final LocalStaffRepository _staffRepository;
  final LocalUserRepository _userRepository;
  final SecureStorageApi _secureStorageApi;
  final Ref _ref;

  StaffNotifier({
    required LocalStaffRepository localRepository,
    required StaffRepository remoteRepository,
    required IWebService webService,
    required LocalStaffRepository staffRepository,
    required LocalUserRepository userRepository,
    required SecureStorageApi secureStorageApi,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _staffRepository = staffRepository,
       _userRepository = userRepository,
       _secureStorageApi = secureStorageApi,
       _ref = ref,
       super(const StaffState());

  /// Insert a single item into local storage
  Future<int> insert(StaffModel model, {bool isInsertToPending = true}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(
        model,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        final updatedItems = List<StaffModel>.from(state.items)..add(model);
        state = state.copyWith(items: updatedItems, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Update a single item in local storage
  Future<int> update(StaffModel model, {bool isInsertToPending = true}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.update(
        model,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        final updatedItems =
            state.items.map((item) {
              return item.id == model.id ? model : item;
            }).toList();
        state = state.copyWith(items: updatedItems, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<StaffModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<StaffModel>.from(state.items);
        for (final newItem in list) {
          final index = currentItems.indexWhere(
            (item) => item.id == newItem.id,
          );
          if (index >= 0) {
            currentItems[index] = newItem;
          } else {
            currentItems.add(newItem);
          }
        }
        state = state.copyWith(items: currentItems, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Get all items from local storage
  Future<List<StaffModel>> getListStaffModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListStaffModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<StaffModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        final idsToRemove = list.map((item) => item.id).toSet();
        final updatedItems =
            state.items
                .where((item) => !idsToRemove.contains(item.id))
                .toList();
        state = state.copyWith(items: updatedItems, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete all items from local storage
  Future<bool> deleteAll() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteAll();

      if (result) {
        state = state.copyWith(items: [], isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete a single item by ID
  Future<int> delete(String id, {bool isInsertToPending = true}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.delete(
        id,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        final updatedItems =
            state.items.where((item) => item.id != id).toList();
        state = state.copyWith(items: updatedItems, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Find an item by its ID
  Future<StaffModel?> getStaffModelById(String itemId) async {
    try {
      // First check current state
      final cachedItem =
          state.items.where((item) => item.id == itemId).firstOrNull;
      if (cachedItem != null) return cachedItem;

      // Fall back to repository
      return await _localRepository.getStaffModelById(itemId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<StaffModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.replaceAllData(
        newData,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        state = state.copyWith(items: newData, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Upsert bulk items to Hive box without replacing all items
  Future<bool> upsertBulk(
    List<StaffModel> list, {
    bool isInsertToPending = true,
    bool isQueue = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
        isQueue: isQueue,
      );

      if (result) {
        final currentItems = List<StaffModel>.from(state.items);
        for (final newItem in list) {
          final index = currentItems.indexWhere(
            (item) => item.id == newItem.id,
          );
          if (index >= 0) {
            currentItems[index] = newItem;
          } else {
            currentItems.add(newItem);
          }
        }
        state = state.copyWith(items: currentItems, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Refresh state from repository
  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListStaffModel();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Check if PIN exists in staff table
  /// Returns StaffModel if PIN exists, otherwise returns empty StaffModel()
  Future<StaffModel> checkPinExist(String pin) async {
    try {
      return await _localRepository.isStaffPinValid(pin);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return StaffModel();
    }
  }

  /// Get staff model by user ID
  Future<StaffModel?> getStaffModelByUserId(String userId) async {
    try {
      return await _localRepository.getStaffModelByUserId(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Get user model by staff ID
  Future<UserModel?> getUserModelByStaffId(String staffId) async {
    try {
      return await _localRepository.getUserModelByStaffId(staffId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Get closed by and opened by names for shift history
  Future<Map<String, dynamic>> getClosedByAndOpenedBy({
    required String closedBy,
    required String openedBy,
  }) async {
    String closeByName = await getUserModelByStaffId(
      closedBy,
    ).then((userModel) => userModel?.name ?? 'Owner');

    String openByName = await getUserModelByStaffId(
      openedBy,
    ).then((userModel) => userModel?.name ?? 'Owner');

    return {'closeByName': closeByName, 'openByName': openByName};
  }

  /// Assign current shift to staff
  /// Updates the currentShiftId field of the staff
  Future<void> assignCurrentShift(String staffId, String shiftId) async {
    try {
      // Find staff in current state
      final staff = state.items.firstWhere(
        (s) => s.id == staffId,
        orElse: () => StaffModel(),
      );

      if (staff.id == null) return;

      // Update the staff with new shift ID
      final updatedStaff = staff.copyWith(
        currentShiftId: shiftId,
        updatedAt: DateTime.now(),
      );

      // Update in repository
      await _localRepository.update(updatedStaff, true);

      // Update state
      final updatedItems =
          state.items.map((item) {
            return item.id == staffId ? updatedStaff : item;
          }).toList();
      state = state.copyWith(items: updatedItems);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<String?> getFirstCompanyId() async {
    return await _staffRepository.getFirstCompanyId();
  }

  Future<List<StaffModel>> syncFromRemote() async {
    List<StaffModel> allStaff = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching staff page $currentPage');
      StaffListResponseModel responseModel = await _webService.get(
        getStaffListWithPagination(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Add staff from current page to the list
        await insertBulk(responseModel.data!, isInsertToPending: false);
        allStaff.addAll(responseModel.data!);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination STAFF: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
          );
        } else {
          // If no paginator info, assume we're done
          break;
        }

        // Move to next page
        currentPage++;
      } else {
        // If request failed, stop pagination
        prints(
          'Failed to fetch staff page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints('Fetched a total of ${allStaff.length} staff from all pages');
    return allStaff;
  }

  Resource getStaffListWithPagination(String page) {
    return _remoteRepository.getStaffListWithPagination(page);
  }

  Future<UserModel> validateStaffPin(
    String staffPin,
    Function(String errorMessage) onError,
  ) async {
    if (!await NetworkUtils.hasInternetConnection()) {
      onError('noInternet'.tr());
      return UserModel();
    }
    UserModel? userModel;
    UserResponseModel responseModel = await _webService.post(
      _remoteRepository.validateStaffPin(staffPin),
    );

    if (responseModel.isSuccess) {
      userModel = responseModel.data;
      prints('Staff Pin is Valid from response');

      // isSynced property removed
    } else {
      prints('Staff Pin is Not Valid from response');
      prints(responseModel.message);
      // maybe pin wujud tapi dekat company lain
      onError("MHUB said : ${responseModel.message}");
      userModel = UserModel();
    }
    return userModel ?? UserModel();
  }

  void setGetIt(StaffModel staffModel) {
    if (!GetIt.instance.isRegistered<StaffModel>()) {
      GetIt.instance.registerSingleton<StaffModel>(staffModel);
    } else {
      GetIt.instance.unregister<StaffModel>();
      GetIt.instance.registerSingleton<StaffModel>(staffModel);
    }
  }

  Future<UserModel> isStaffPinValid(
    String pin,
    Function(String errorMessage) onError, {
    bool hasInternet = true,
  }) async {
    // final userFacade = ServiceLocator.get<UserFacade>();
    // final userNotifier = ServiceLocator.get<UserNotifier>();
    // final staffNotifier = ServiceLocator.get<StaffNotifier>();

    // this is to refresh user and staff data incase have change the data but not sync

    await Future.wait([
      SyncService.resetLastSyncTime(StaffModel.modelName),
      SyncService.resetLastSyncTime(UserModel.modelName),
    ]);

    if (hasInternet) {
      try {
        // Use Future.timeout which is more appropriate for this use case

        return await _processStaffPinValidation(pin, onError).timeout(
          const Duration(seconds: 30),
          onTimeout: () async {
            onError(
              'Request timed out after 30 seconds. Please check your Internet connection',
            );
            await LogUtils.error(
              'Request timed out after 30 seconds. Please check your Internet connection',
            );
            return UserModel();
          },
        );
      } catch (e) {
        onError('Error validating staff PIN: ${e.toString()}');
        await LogUtils.error('Error validating staff PIN: ${e.toString()}');
        return UserModel();
      }
    } else {
      // await dummyPendingChanges();
      // dont have internet
      // get staff only where pin id
      List<StaffModel> listStaffWithShift =
          await _localRepository.getListStaffByShiftNotNull();
      if (listStaffWithShift.isEmpty) {
        onError('No Internet Connection');
        return UserModel();
      }
      final StaffModel staffModel = listStaffWithShift.firstWhere(
        (staff) => staff.pin == pin,
        orElse: () => StaffModel(),
      );
      // get user by staff model
      if (staffModel.id != null) {
        final UserModel? userModel = await _userRepository
            .getUserModelFromStaffId(staffModel.id!);

        if (userModel != null && userModel.id != null) {
          return userModel;
        } else {
          onError('Staff not found');
          return UserModel();
        }
      } else {
        onError('Staff not found');
        return UserModel();
      }
    }
  }

  Future<void> unlockPermission({
    required String permission,
    required String pin,
    required Function() onSuccess,
    required Function(String message) onError,
  }) async {
    String errMsg = "Wrong PIN";
    String errLogMessage = "Unlock permission failed";

    StaffModel staff = await checkPinExist(pin);

    final errorLogNotifier = _ref.read(errorLogProvider.notifier);

    if (staff.id == null) {
      //
      errLogMessage = "Wrong PIN - $permission - Staff id is null";
      await errorLogNotifier.createAndInsertErrorLog(errLogMessage);
      onError(errMsg); // wrong pin
      return;
    }

    if (staff.userId == null) {
      // rare case
      errLogMessage = "Wrong PIN - $permission - Staff userId is null";
      await errorLogNotifier.createAndInsertErrorLog(errLogMessage);
      onError(errMsg); // wrong pin
      return;
    }

    if (staff.id != null && staff.userId != null) {
      UserModel? user = await _userRepository.getUserModelByIdUser(
        staff.userId!,
      );

      if (user == null) {
        errLogMessage =
            "Unlock permission failed - $permission - User is null - Try to re-sync";
        errMsg = "Wrong PIN - Try re-sync";
        await errorLogNotifier.createAndInsertErrorLog(errLogMessage);
        onError(errMsg); // wrong pin
        return;
      }

      if (user.id == null) {
        errLogMessage =
            "Unlock permission failed - $permission - User ID is null - Try to re-sync";
        errMsg = "Wrong PIN - Try re-sync";
        await errorLogNotifier.createAndInsertErrorLog(errLogMessage);
        onError(errMsg); // wrong pin
        return;
      }

      if (user.posPermissionJson == null) {
        errLogMessage =
            "Unlock permission failed - $permission - Pos Permission JSON is null";
        errMsg = "Something went wrong - Try re-sync";
        await errorLogNotifier.createAndInsertErrorLog(errLogMessage);
        onError(errMsg); // wrong pin
        return;
      }

      if (user.id != null &&
          user.posPermissionJson != null &&
          user.posPermissionJson!.isNotEmpty) {
        dynamic permissionNameJson = jsonDecode(user.posPermissionJson!);
        List<String> permissionNames = List<String>.from(permissionNameJson);

        if (permissionNames.contains(permission)) {
          // Permission exists in the list
          onSuccess(); // Unlock successful
          return;
        } else {
          // Permission does not exist in the list
          errLogMessage =
              "Staff exist - $permission - Access is denied - trying to use PIN staff ${user.name ?? ''}";
          errMsg = "Access Denied";
          await errorLogNotifier.createAndInsertErrorLog(errLogMessage);
          onError(errMsg); // Wrong PIN
          return;
        }
      }
    }
  }

  // Helper method to process the validation
  Future<UserModel> _processStaffPinValidation(
    String pin,
    Function(String errorMessage) onError,
  ) async {
    final errorLogNotifier = _ref.read(errorLogProvider.notifier);
    String message = "Staff id is null masa _processStaffPinValidation";
    UserModel? userModel;

    // if (staffToken.isEmpty) {
    //  if takde access token staff, panggil api login pin
    // api akan return user model
    userModel = await validateStaffPin(pin, (errorMsg) {
      if (errorMsg.isNotEmpty) {
        message = errorMsg;
      }
    });
    StaffModel staffModel = await _staffRepository.getStaffModelByUserId(
      userModel.id?.toString() ?? '',
    );
    // get the token from the user model from the response set it as staff access token

    if (staffModel.id != null) {
      setGetIt(staffModel);
      await _secureStorageApi.write(
        'staff_access_token',
        userModel.accessToken ?? 'no staff token',
      );

      await _secureStorageApi.saveObject('staff', staffModel);

      // await dummyPendingChanges();
    } else {
      if (userModel.id == null || userModel.accessToken == null) {
        errorLogNotifier.createAndInsertErrorLog(message);
        userModel = UserModel();
        onError(message);
      } else {
        StaffModel? staffModel = await _getStaffModelWithRetries(
          userModel.id?.toString() ?? '',
          1,
        );

        if (staffModel?.id != null) {
          setGetIt(staffModel!);
          await _secureStorageApi.write(
            'staff_access_token',
            userModel.accessToken ?? 'no staff token',
          );
          await _secureStorageApi.saveObject('staff', staffModel);
        } else {
          errorLogNotifier.createAndInsertErrorLog(message);
          userModel = UserModel();
          onError(message);
        }
      }
    }
    // }
    // else {

    //   LogUtils.log('DB ALREADY FILLED');
    //   // means db already filled
    //   // boleh query direct from db
    //   StaffModel staffModel = await _staffRepository.isStaffPinValid(pin);
    //   // pin valid
    //   // set staff model to get  it
    //   if (staffModel.id != null) {
    //     setGetIt(staffModel);
    //     userModel = await _userRepository.getUserModelByIdUser(
    //       staffModel.userId!,
    //     );
    //   }

    //   // set get it user model
    //   if (userModel != null) {
    //     _userFacade.setGetIt(userModel);
    //   }
    // }

    return userModel.id != null ? userModel : UserModel();
  }

  Future<void> dummyPendingChanges() async {
    final localPCRepository =
        ServiceLocator.get<LocalPendingChangesRepository>();
    final customerModel = CustomerModel(
      id: IdUtils.generateUUID(),
      name: "EMULATOR",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final pc = PendingChangesModel(
      id: IdUtils.generateUUID(),
      operation: 'created',
      modelName: CashManagementModel.modelName,
      modelId: customerModel.id ?? '',
      data: jsonEncode(customerModel.toJson()),
      createdAt: DateTime.now(),
    );

    await localPCRepository.insert(pc);
  }

  Future<List<StaffModel>> getListStaffByCurrentShiftId(String idShift) async {
    return await _localRepository.getListStaffByCurrentShiftId(idShift);
  }

  Future<int> deleteStaffWhereIdNull() async {
    return await _localRepository.deleteStaffWhereIdNull();
  }

  List<StaffModel> getListStaffFromHive() {
    return _localRepository.getListStaffFromHive();
  }

  Future<String> getCurrentShiftFromStaffId(String staffId) async {
    return await _staffRepository.getCurrentShiftFromStaffId(staffId);
  }

  Future<StaffModel?> _getStaffModelWithRetries(
    String userId,
    int maxAttempts,
  ) async {
    for (int i = 0; i < maxAttempts; i++) {
      await _ref
          .read(syncRealTimeProvider.notifier)
          .seedingProcess(
            'After choose POS Device onSuccess',
            (isLoading) {},
            isInitData: true,
            needToDownloadImage: true,
          );

      StaffModel staffModel = await _staffRepository.getStaffModelByUserId(
        userId,
      );

      if (staffModel.id != null) {
        return staffModel;
      }
    }
    return null;
  }

  // ============================================================
  // UI State Management Methods (from old StaffNotifier)
  // ============================================================

  /// Get staff list (getter for compatibility)
  List<StaffModel> get getListStaff => state.items;
}

/// Provider for staff domain
final staffProvider = StateNotifierProvider<StaffNotifier, StaffState>((ref) {
  return StaffNotifier(
    localRepository: ServiceLocator.get<LocalStaffRepository>(),
    remoteRepository: ServiceLocator.get<StaffRepository>(),
    webService: ServiceLocator.get<IWebService>(),
    userRepository: ServiceLocator.get<LocalUserRepository>(),
    secureStorageApi: ServiceLocator.get<SecureStorageApi>(),
    staffRepository: LocalStaffRepositoryImpl(dbHelper: GetIt.instance.get()),
    ref: ref,
  );
});

/// Provider for sorted items (computed provider - sorted by pin)
final sortedStaffsProvider = Provider<List<StaffModel>>((ref) {
  final items = ref.watch(staffProvider).items;
  final sorted = List<StaffModel>.from(items);
  sorted.sort((a, b) => (a.pin ?? '').compareTo(b.pin ?? ''));
  return sorted;
});

/// Provider for staff by ID (family provider for indexed lookups)
final staffByIdProvider = FutureProvider.family<StaffModel?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(staffProvider.notifier);
  return notifier.getStaffModelById(id);
});
