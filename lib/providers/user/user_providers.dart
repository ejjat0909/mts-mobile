import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/domain/repositories/local/user_repository.dart';
import 'package:mts/providers/app/app_providers.dart';
import 'package:mts/providers/customer/customer_providers.dart';
import 'package:mts/providers/device/device_providers.dart';
import 'package:mts/providers/outlet/outlet_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/shift/shift_providers.dart';
import 'package:mts/providers/staff/staff_providers.dart';
import 'package:mts/providers/sync_real_time/sync_real_time_providers.dart';
import 'package:mts/providers/user/user_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/network/http_response.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/services/hive_init_helper.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/datasources/remote/pusher_datasource.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/default_response_model.dart';
import 'package:mts/data/models/license/license_response_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/user/user_list_response_model.dart';
import 'package:mts/data/models/user/user_response_model.dart';
import 'package:mts/core/services/general_service.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/remote/user_repository.dart';
import 'package:mts/presentation/common/dialogs/confirm_dialogue.dart';
import 'package:mts/presentation/common/dialogs/loading_dialogue.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/features/login/login_screen.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';

/// StateNotifier for User domain
///
/// Migrated from: user_facade_impl.dart
class UserNotifier extends StateNotifier<UserState> {
  final LocalUserRepository _localRepository;
  final LocalPendingChangesRepository _localPendingChangesRepository;
  final UserRepository _remoteRepository;
  final IWebService _webService;
  final PusherDatasource _pusherService;
  final SecureStorageApi _secureStorage;

  final Ref _ref;

  UserNotifier({
    required LocalUserRepository localRepository,
    required UserRepository remoteRepository,
    required IWebService webService,
    required PusherDatasource pusherService,
    required SecureStorageApi secureStorage,
    required LocalPendingChangesRepository localPendingChangesRepository,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _pusherService = pusherService,
       _secureStorage = secureStorage,
       _localPendingChangesRepository = localPendingChangesRepository,
       _ref = ref,
       super(const UserState());

  /// Insert a single item into local storage
  Future<int> insert(UserModel model, {bool isInsertToPending = true}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(
        model,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        final updatedItems = List<UserModel>.from(state.items)..add(model);
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
  Future<int> update(UserModel model, {bool isInsertToPending = true}) async {
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
    List<UserModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<UserModel>.from(state.items);
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
  Future<List<UserModel>> getListUserModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListUserModels();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<UserModel> list) async {
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
        final idInt = int.tryParse(id);
        final updatedItems =
            state.items.where((item) => item.id != idInt).toList();
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
  Future<UserModel?> getUserModelById(String itemId) async {
    try {
      // First check current state - convert string to int for comparison
      final itemIdInt = int.tryParse(itemId);
      final cachedItem =
          state.items.where((item) => item.id == itemIdInt).firstOrNull;
      if (cachedItem != null) return cachedItem;

      // Fall back to repository
      if (itemIdInt != null) {
        return await _localRepository.getUserModelByIdUser(itemIdInt);
      }
      return null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Find a user by user ID
  Future<UserModel?> getUserModelByIdUser(int userId) async {
    try {
      return await _localRepository.getUserModelByIdUser(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<UserModel> newData, {
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
    List<UserModel> list, {
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
        final currentItems = List<UserModel>.from(state.items);
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
      final items = await _localRepository.getListUserModels();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ============================================================
  // UI State Management Methods (from old UserNotifier)
  // ============================================================

  /// Get user list (getter for compatibility)
  List<UserModel> get getUserList => state.items;

  /// Set current user (similar to setGetIt in facade)
  /// Updates state with current logged in user
  void setCurrentUser(UserModel userModel) {
    // Update the items list if user exists, otherwise add
    final currentItems = List<UserModel>.from(state.items);
    final index = currentItems.indexWhere((u) => u.id == userModel.id);

    if (index >= 0) {
      currentItems[index] = userModel;
    } else if (userModel.id != null) {
      currentItems.add(userModel);
    }

    state = state.copyWith(items: currentItems, currentUser: userModel);
  }

  /// Get current logged-in user
  UserModel? get currentUser => state.currentUser;

  Future<List<UserModel>> getListUserModels() async {
    return await _localRepository.getListUserModels();
  }

  Future<UserModel?> getUserModelFromStaffId(String staffId) async {
    return await _localRepository.getUserModelFromStaffId(staffId);
  }

  Future<void> signOut(Function(bool, String?) onIsSuccess) async {
    // STEP 1: Get required services and models from the ServiceLocator

    final syncRealTimeProviderRef = _ref.read(syncRealTimeProvider.notifier);
    final customerNotifier = _ref.read(customerProvider.notifier);
    final myNavigator = _ref.read(myNavigatorProvider.notifier);
    final secondDisplayNotifier = _ref.read(secondDisplayProvider.notifier);
    bool successSyncRealTime = false;
    String? errorMessage;

    // STEP 3: Perform a final sync with the server before completing sign-out
    // - This ensures all pending changes are sent to the server
    // - The callback (isSuccess) is empty as we're not taking any action based on the result
    await syncRealTimeProviderRef.onSyncOrder(
      null,
      false,
      manuallyClick: false,
      isSuccess: (isSuccess, syncErrorMessage) async {
        successSyncRealTime = isSuccess;
        if (!isSuccess) {
          // means have failed pending changes
          errorMessage = syncErrorMessage ?? 'Server Error';
        }
      },
      isAfterActivateLicense: true,
      needToDownloadImage: false,
      onlyCheckPendingChanges: true,
    );

    if (!successSyncRealTime) {
      //means have failed pending changes
      onIsSuccess(false, errorMessage); // Return early if sync fails

      return;
    } else {
      // update shift closeAt
      // get it will be clear below to handle if server error, they cannot logout
      await updateImportantDataBeforeSignOut(isClearGetIt: false);
      // sync kat sini
      await syncRealTimeProviderRef.onSyncOrder(
        null,
        false,
        manuallyClick: false,
        isSuccess: (isSuccess, syncErrorMessage) async {
          successSyncRealTime = isSuccess;
          if (!isSuccess) {
            // means have failed pending changes
            errorMessage = syncErrorMessage ?? 'Server Error';
          }
        },
        isAfterActivateLicense: true,
        needToDownloadImage: false,
        onlyCheckPendingChanges: true,
      );
      // success sync real time
      // Unsubscribe Pusher
      // pusher need to unscribe first to avoid call the pending changes twice
      String channelName = await _secureStorage.read(key: 'channelName');
      if (channelName != '') {
        LogUtils.log('channelName length: ${channelName.length}');
        LogUtils.log('channelName  : $channelName');
        _pusherService.unsubscribe(channelName);
      }

      // Revoked User Token
      DefaultResponseModel defaultResponseModel = await _webService.get(
        _remoteRepository.logout(),
      );
      prints('Logout response: ${defaultResponseModel.isSuccess}');

      // If success or already unauthorized clear data in storage
      if (defaultResponseModel.isSuccess ||
          defaultResponseModel.statusCode == HttpResponse.HTTP_UNAUTHORIZED) {
        // clear order in sale item
        final saleItemsNotifier = _ref.read(saleItemProvider.notifier);
        saleItemsNotifier.removeAllSaleItems();
        saleItemsNotifier.setCategoryId('');

        // clear selected customer for that order
        customerNotifier.setOrderCustomerModel(null);

        // Reset secondary display via provider
        await secondDisplayNotifier.stopSecondaryDisplay();
        // clear and close hive box

        await HiveInitHelper.clearAllBoxes();
        // Reset all sync metadata so next login will trigger full sync
        // dah panggil dalaam GeneralBloc.deleteDatabaseProcess()
        // await _secureStorage.resetAllSyncMetadata();
        // await HiveInitHelper.closeAllBoxes();

        setGetIt(UserModel());
        _ref.read(staffProvider.notifier).setGetIt(StaffModel());
        _ref.read(outletProvider.notifier).setGetIt(OutletModel());
        _ref.read(deviceProvider.notifier).setGetIt(PosDeviceModel());
        await _secureStorage.delete(key: 'device');

        await _secureStorage.delete(key: 'access_token');
        String? token = await _secureStorage.read(key: 'staff_access_token');

        // kalau tak buat checking nanti error
        if (token.isNotEmpty == true) {
          await _secureStorage.delete(key: 'staff_access_token');
        }

        // then reset or delete all metadata
        await SyncService.deleteAllMetadata();

        myNavigator.setLastPageIndex(null, null);
        myNavigator.setLastSelectedTab(null, null);
        _ref.read(shiftProvider.notifier).setCloseShift();
        onIsSuccess(true, null);
        return;
      }
    }

    onIsSuccess(false, 'Logout failed');
    return;
  }

  Future<LicenseResponseModel> validateLicense(String licenseKey) async {
    // Call the API to login
    return await _webService.post(
      _remoteRepository.validateLicense(licenseKey),
    );
  }

  Future<void> operationForceSignOut() async {
    final secondDisplayNotifier = _ref.read(secondDisplayProvider.notifier);
    final myNavigator = _ref.read(myNavigatorProvider.notifier);
    String channelName = await _secureStorage.read(key: 'channelName');
    if (channelName != '') {
      LogUtils.log('channelName length: ${channelName.length}');
      LogUtils.log('channelName  : $channelName');
      _pusherService.unsubscribe(channelName);
    }

    // Revoked User Token
    DefaultResponseModel defaultResponseModel = await _webService.get(
      _remoteRepository.logout(),
    );
    prints('Logout response: ${defaultResponseModel.isSuccess}');
    // If success or already unauthorized clear data in storage
    if (defaultResponseModel.isSuccess ||
        defaultResponseModel.statusCode == HttpResponse.HTTP_UNAUTHORIZED) {
      // clear order in sale item
      final saleItemsNotifier = _ref.read(saleItemProvider.notifier);
      saleItemsNotifier.removeAllSaleItems();
      saleItemsNotifier.setCategoryId('');
      // update the chosen device to make it active

      // Reset secondary display via provider
      await secondDisplayNotifier.stopSecondaryDisplay();
      // clear and close hive box

      await HiveInitHelper.clearAllBoxes();
      // Reset all sync metadata so next login will trigger full sync
      // dah panggil dalaam GeneralBloc.deleteDatabaseProcess()
      // await _secureStorage.resetAllSyncMetadata();
      // await HiveInitHelper.closeAllBoxes();

      setGetIt(UserModel());
      _ref.read(staffProvider.notifier).setGetIt(StaffModel());
      _ref.read(outletProvider.notifier).setGetIt(OutletModel());

      await _secureStorage.delete(key: 'access_token');
      String? token = await _secureStorage.read(key: 'staff_access_token');

      // kalau tak buat checking nanti error
      if (token.isNotEmpty == true) {
        await _secureStorage.delete(key: 'staff_access_token');
      }

      // then reset or delete all metadata
      await SyncService.deleteAllMetadata();

      myNavigator.setLastPageIndex(null, null);
      myNavigator.setLastSelectedTab(null, null);
      _ref.read(shiftProvider.notifier).setCloseShift();

      return;
    }
  }

  Future<UserResponseModel> login(String email, String password) async {
    // Call the API to login
    final String licenseKey = await _secureStorage.read(key: 'license_key');
    final UserResponseModel response = await _webService.post(
      _remoteRepository.login(email, password, licenseKey),
    );
    if (response.statusCode == HttpResponse.HTTP_OK) {
      if (response.data != null && response.data!.accessToken != null) {
        //save in secured storage
        await _secureStorage.write('access_token', response.data!.accessToken!);
        //save in secured storage
        await _secureStorage.saveObject('user', response.data);
        //save in GetIt using ServiceLocator
        setGetIt(response.data!);
      }
    }

    return response;
  }

  Future<UserResponseModel> loginUsingPin(String pin) async {
    // Call the API to login
    final UserResponseModel response = await _webService.post(
      _remoteRepository.loginUsingPin(pin),
    );
    if (response.statusCode == HttpResponse.HTTP_OK) {
      if (response.data != null) {
        //save in secured storage
        await _secureStorage.saveObject('user', response.data);
        //save in GetIt using ServiceLocator
        setGetIt(response.data!);
      }
    }

    return response;
  }

  Future<void> changeLicense(BuildContext context) async {
    try {
      // Delete all data in storage using ServiceLocator
      // await ServiceLocator.resetAll();
      // await _secureStorage.deleteAll();

      // Simulate loading process
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      // Handle error
      prints('Error changing license: $e');
    }
  }

  Resource getListUsersWithPagination(String page) {
    return _remoteRepository.getListUsersWithPagination(page);
  }

  Future<List<UserModel>> syncFromRemote() async {
    List<UserModel> allUsers = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching users page $currentPage');
      UserListResponseModel responseModel = await _webService.get(
        getListUsersWithPagination(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Add users from current page to the list
        await insertBulk(responseModel.data!, isInsertToPending: false);
        allUsers.addAll(responseModel.data!);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination USER: current page=$currentPage, last page=$lastPage, total users=${responseModel.paginator!.total}',
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
          'Failed to fetch users page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints('Fetched a total of ${allUsers.length} users from all pages');
    return allUsers;
  }

  Future<void> logoutConfirmation(BuildContext uiContext) async {
    final GeneralService generalFacade = ServiceLocator.get<GeneralService>();
    ConfirmDialog.show(
      uiContext,
      onPressed: () async {
        // close the dialog confirmation
        NavigationUtils.pop(uiContext);
        LoadingDialog.show(uiContext);

        // call method sign out
        await signOut((isSuccess, errorMessage) async {
          LoadingDialog.hide(uiContext);
          _ref.read(appProvider.notifier).setIsSyncing(false);
          if (isSuccess) {
            NavigationUtils.pushRemoveUntil(
              uiContext,
              screen: const LoginScreen(),
              slideFromLeft: true,
            );

            _ref.read(myNavigatorProvider.notifier).setPageIndex(0, '');
            await generalFacade.deleteDatabaseProcess();
            String licenseKey = await _secureStorage.read(key: 'license_key');
            prints('🟡🟡🟡🟡🟡🟡🟡🟡license key: $licenseKey');

            // await ServiceLocator.resetAll();
            return;
          } else {
            ThemeSnackBar.showSnackBar(
              uiContext,
              errorMessage ?? 'Server Error',
            );

            forceProceedDialogue(uiContext);

            return;
          }
        });
      },
      description: "\n${'logoutDialogDesc'.tr()}\n",
      icon: const Icon(FontAwesomeIcons.rightFromBracket, color: kPrimaryColor),
    );
  }

  void setGetIt(UserModel userModel) {
    if (!GetIt.instance.isRegistered<UserModel>()) {
      GetIt.instance.registerSingleton<UserModel>(userModel);
    } else {
      GetIt.instance.unregister<UserModel>();
      GetIt.instance.registerSingleton<UserModel>(userModel);
    }
  }

  List<UserModel> getListUserFromHive() {
    return _localRepository.getListUserFromHive();
  }

  void forceProceedDialogue(BuildContext uiContext) {
    ConfirmDialog.show(
      uiContext,
      onPressed: () async {
        final syncRealTimeNotifier = _ref.read(syncRealTimeProvider.notifier);
        // when user want to force logout, just sync but need to update shift, staff and device
        await updateImportantDataBeforeSignOut();
        await syncRealTimeNotifier.onSyncOrder(
          null,
          false,
          manuallyClick: false,
          isSuccess: (isSuccess, syncErrorMessage) async {
            if (!isSuccess) {
              // bagi lepas je sebab nak force logout
            }
          },
          isAfterActivateLicense: true,
          needToDownloadImage: false,
          onlyCheckPendingChanges: true,
        );
        // sync kat sini
        // close the dialog confirmation
        await _localPendingChangesRepository.deleteAll();
        NavigationUtils.pop(uiContext);
        await operationForceSignOut();
        NavigationUtils.pushRemoveUntil(
          uiContext,
          screen: const LoginScreen(),
          slideFromLeft: true,
        );
      },
      description: 'pleaseContactSupport'.tr(),
      icon: const Icon(
        FontAwesomeIcons.triangleExclamation,
        color: kWarningColor,
      ),
    );
  }

  Future<void> updateImportantDataBeforeSignOut({
    bool isClearGetIt = true,
  }) async {
    final SecureStorageApi secureStorageApi =
        ServiceLocator.get<SecureStorageApi>();

    PosDeviceModel? deviceModel =
        await _ref.read(deviceProvider.notifier).getLatestDeviceModel();
    StaffModel currentStaff = ServiceLocator.get<StaffModel>();

    ShiftModel latestShift =
        await _ref.read(shiftProvider.notifier).getLatestShift();
    if (latestShift.id != null) {
      await _ref
          .read(shiftProvider.notifier)
          .update(
            latestShift.copyWith(
              closedAt: DateTime.now(),
              closedBy: currentStaff.id,
              updatedAt: DateTime.now(),
            ),
          );
    }

    // update staff to assign null to current shift id

    // get list staff
    List<StaffModel> listStaff = await _ref
        .read(staffProvider.notifier)
        .getListStaffByCurrentShiftId(latestShift.id ?? '-1');

    for (StaffModel staffModel in listStaff) {
      if (staffModel.id != null) {
        StaffModel updatedStaff = staffModel.copyWith(
          currentShiftId: null,
          updatedAt: DateTime.now(),
        ); // Update the currentShiftId field
        await _ref.read(staffProvider.notifier).insertBulk([
          updatedStaff,
        ], isInsertToPending: true);
      }
    }
    // STEP 2: Mark the current device as inactive during sign-out
    // - We create a copy of the current device model with isActive set to false
    // - This prevents the device from receiving further updates while signed out
    if (deviceModel?.id != null) {
      PosDeviceModel updatedDeviceModel = deviceModel!.copyWith(
        isActive: false,
      );
      await _ref.read(deviceProvider.notifier).update(updatedDeviceModel);
      if (isClearGetIt) {
        _ref.read(deviceProvider.notifier).setGetIt(PosDeviceModel());
        await secureStorageApi.clear('device');
      }
    }
  }
}

/// Provider for user domain
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(
    localRepository: ServiceLocator.get<LocalUserRepository>(),
    remoteRepository: ServiceLocator.get<UserRepository>(),
    webService: ServiceLocator.get<IWebService>(),
    pusherService: ServiceLocator.get<PusherDatasource>(),
    secureStorage: ServiceLocator.get<SecureStorageApi>(),
    localPendingChangesRepository:
        ServiceLocator.get<LocalPendingChangesRepository>(),

    ref: ref,
  );
});

/// Provider for sorted items (computed provider)
final sortedUsersProvider = Provider<List<UserModel>>((ref) {
  final items = ref.watch(userProvider).items;
  final sorted = List<UserModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for user by ID (family provider for indexed lookups)
final userByIdProvider = FutureProvider.family<UserModel?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(userProvider.notifier);
  return notifier.getUserModelById(id);
});
