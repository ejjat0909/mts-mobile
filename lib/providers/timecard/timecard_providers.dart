import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/time_card/timecard_list_response_model.dart';
import 'package:mts/data/models/time_card/timecard_model.dart';
import 'package:mts/domain/repositories/local/timecard_repository.dart';
import 'package:mts/domain/repositories/remote/sync_repository.dart';
import 'package:mts/domain/repositories/remote/timecard_repository.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/features/home/home_screen.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/staff/staff_providers.dart';
import 'package:mts/providers/timecard/timecard_state.dart';

/// StateNotifier for Timecard domain
///
/// Contains complex business logic for clock in/out, timecard checking, and API sync.
/// Orchestrates StaffFacade, SecureStorageApi, navigation, and dialogs.
class TimecardNotifier extends StateNotifier<TimecardState> {
  final LocalTimecardRepository _localRepository;
  final TimecardRepository _remoteRepository;
  final IWebService _webService;
  final SecureStorageApi _secureStorageApi;
  final Ref _ref;

  TimecardNotifier({
    required LocalTimecardRepository localRepository,
    required TimecardRepository remoteRepository,
    required IWebService webService,
    required SyncRepository syncRepository,
    required SecureStorageApi secureStorageApi,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _secureStorageApi = secureStorageApi,
       _ref = ref,
       super(const TimecardState());

  /// Insert a single timecard
  Future<int> insert(TimecardModel model) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(model, true);

      if (result > 0) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Update a timecard
  Future<int> update(TimecardModel model) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.update(model, true);

      if (result > 0) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Delete a single timecard by ID
  Future<int> delete(String id, {bool isInsertToPending = true}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.delete(
        id,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Get list of timecards
  Future<List<TimecardModel>> getListTimeCard() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListTimeCard();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Get current active timecard for a staff
  Future<TimecardModel> getCurrentTimecard(String idStaff) async {
    try {
      return await _localRepository.getCurrentTimecard(idStaff);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return TimecardModel();
    }
  }

  /// Handle staff clock in
  Future<void> staffClockIn({
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      StaffModel staffModel = ServiceLocator.get<StaffModel>();
      OutletModel outletModel = ServiceLocator.get<OutletModel>();
      DateTime clockInTime = DateTime.now();

      if (staffModel.id == null) {
        staffModel = await _secureStorageApi.readObject('staff');
      }

      TimecardModel tcm = TimecardModel(
        staffId: staffModel.id,
        outletId: outletModel.id,
        clockIn: clockInTime,
      );

      int result = await insert(tcm);
      state = state.copyWith(isLoading: false);

      if (result != 0) {
        onSuccess();
      } else {
        onError('failCreateTimeCard'.tr());
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      onError(e.toString());
    }
  }

  /// Handle staff clock out
  Future<void> staffClockOut({
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      StaffModel staffModel = ServiceLocator.get<StaffModel>();
      DateTime clockOutTime = DateTime.now();
      final staffNotifier = _ref.read(staffProvider.notifier);

      TimecardModel currentTcm = await getCurrentTimecard(staffModel.id!);
      if (currentTcm.id == null) {
        state = state.copyWith(isLoading: false);
        onError('youAreNotClockIn'.tr());
        return;
      }

      DateTime clockInTime = currentTcm.clockIn!;
      Duration diff = clockOutTime.difference(clockInTime);
      double totalHours = diff.inHours + (diff.inMinutes % 60) / 60;

      TimecardModel newTcm = currentTcm.copyWith(
        clockOut: clockOutTime,
        totalHour: totalHours,
        updatedAt: DateTime.now(),
      );

      int result = await update(newTcm);

      if (result != 0) {
        StaffModel updatedStaff = staffModel.copyWith(
          currentShiftId: null,
          updatedAt: DateTime.now(),
        );

        await staffNotifier.insertBulk([updatedStaff], isInsertToPending: true);

        String? token = await _secureStorageApi.read(key: 'staff_access_token');
        if (token.isNotEmpty == true) {
          await _secureStorageApi.delete(key: 'staff_access_token');
        }

        state = state.copyWith(isLoading: false);
        onSuccess();
      } else {
        state = state.copyWith(isLoading: false);
        onError('failUpdateTimeCard'.tr());
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      onError(e.toString());
    }
  }

  /// Check current timecard and navigate accordingly
  Future<void> checkCurrentTimecard(
    BuildContext pinInputFieldContext,
    String staffId,
    bool mounted,
    int? currentScreenIndex,
  ) async {
    try {
      final featureCompNotifier = _ref.read(featureCompanyProvider.notifier);
      final isFeatureActive = featureCompNotifier.isTimeClockActive();
      TimecardModel currentTcm = await getCurrentTimecard(staffId);
      final dialogueNav = ServiceLocator.get<MyNavigatorNotifier>();

      if (!isFeatureActive) {
        final lastPageIndex = dialogueNav.lastPageIndex;
        if (mounted) {
          if (lastPageIndex == null) {
            NavigationUtils.pushRemoveUntil(
              pinInputFieldContext,
              screen: const Home(),
            );
          } else {
            await dialogueNav.setUINavigatorAndIndex();
            NavigationUtils.pop(pinInputFieldContext);
          }
        }
        return;
      }

      if (currentTcm.id == null) {
        if (mounted) {
          CustomDialog.show(
            pinInputFieldContext,
            icon: FontAwesomeIcons.idBadge,
            title: 'noShift'.tr(),
            description: 'noShiftDescription'.tr(),
            btnOkText: 'OK'.tr(),
            btnOkOnPress: () {
              NavigationUtils.pop(pinInputFieldContext);
              if (currentScreenIndex != null) {
                dialogueNav.setPageIndex(
                  currentScreenIndex + 1,
                  'timeInOut'.tr(),
                );
              }
            },
          );
        }
      } else {
        final lastPageIndex = dialogueNav.lastPageIndex;
        if (mounted) {
          if (lastPageIndex == null) {
            NavigationUtils.pushRemoveUntil(
              pinInputFieldContext,
              screen: const Home(),
            );
          } else {
            await dialogueNav.setUINavigatorAndIndex();
            NavigationUtils.pop(pinInputFieldContext);
          }
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Get resource for paginated timecard list
  Resource getTimecardListPaginated(String page) {
    return _remoteRepository.getTimecardListPaginated(page);
  }

  /// Get all timecards from API with pagination
  Future<List<TimecardModel>> syncFromRemote() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      List<TimecardModel> allTimecards = [];
      int currentPage = 1;
      int? lastPage;

      do {
        prints('Fetching timecards page $currentPage');
        TimeCardListResponseModel responseModel = await _webService.get(
          getTimecardListPaginated(currentPage.toString()),
        );

        if (responseModel.isSuccess && responseModel.data != null) {
          List<TimecardModel> pageTimecards = responseModel.data!;
          allTimecards.addAll(pageTimecards);

          if (responseModel.paginator != null) {
            lastPage = responseModel.paginator!.lastPage;
            prints(
              'Pagination TIMECARD: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
            );
          } else {
            break;
          }

          currentPage++;
        } else {
          prints(
            'Failed to fetch timecards page $currentPage: ${responseModel.message}',
          );
          break;
        }
      } while (lastPage != null && currentPage <= lastPage);

      prints(
        'Fetched a total of ${allTimecards.length} timecards from all pages',
      );

      state = state.copyWith(isLoading: false);
      return allTimecards;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      prints('Error fetching timecards with pagination: $e');
      return [];
    }
  }

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<TimecardModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<TimecardModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
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
        state = state.copyWith(items: []);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<TimecardModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.replaceAllData(
        newData,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        state = state.copyWith(items: newData);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Upsert bulk items to Hive box without replacing all items
  Future<bool> upsertBulk(
    List<TimecardModel> list, {
    bool isInsertToPending = true,
    bool isQueue = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Internal helper to load items and update state
  Future<void> _loadItems() async {
    try {
      final items = await _localRepository.getListTimeCard();

      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get the list of timecards (old notifier getter)
  List<TimecardModel> get listTimecard => state.items;

  /// Get the current timecard (old notifier getter)
  TimecardModel? get currentTimecard => state.currentTimecard;

  /// Set the list of timecards (old notifier method)
  void setListTimecard(List<TimecardModel> timecards) {
    state = state.copyWith(items: timecards);
  }

  /// Set the current timecard (old notifier method)
  void setCurrentTimecard(TimecardModel? timecard) {
    state = state.copyWith(currentTimecard: timecard);
  }

  /// Add or update multiple timecards in the list (old notifier method)
  void addOrUpdateList(List<TimecardModel> timecards) {
    final currentItems = List<TimecardModel>.from(state.items);

    for (final timecard in timecards) {
      final index = currentItems.indexWhere((tc) => tc.id == timecard.id);
      if (index != -1) {
        currentItems[index] = timecard;
      } else {
        currentItems.add(timecard);
      }
    }
    state = state.copyWith(items: currentItems);
  }

  /// Remove a timecard from the list (old notifier method)
  void removeTimecard(String timecardId) {
    final updatedItems =
        state.items.where((timecard) => timecard.id != timecardId).toList();
    state = state.copyWith(items: updatedItems);
  }

  /// Clear all timecards (old notifier method)
  void clearTimecards() {
    state = state.copyWith(items: [], currentTimecard: null);
  }

  /// Set loading state (old notifier method)
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Get active timecards (not clocked out) - old notifier method
  List<TimecardModel> getActiveTimecards() {
    return state.items.where((timecard) => timecard.clockOut == null).toList();
  }
}

/// Provider for sorted items (computed provider)
final sortedTimecardsProvider = Provider<List<TimecardModel>>((ref) {
  final items = ref.watch(timecardProvider).items;
  final sorted = List<TimecardModel>.from(items);
  sorted.sort(
    (a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
  );
  return sorted;
});

/// Provider for timecard domain
final timecardProvider = StateNotifierProvider<TimecardNotifier, TimecardState>(
  (ref) {
    return TimecardNotifier(
      localRepository: ServiceLocator.get<LocalTimecardRepository>(),
      remoteRepository: ServiceLocator.get<TimecardRepository>(),
      webService: ServiceLocator.get<IWebService>(),
      syncRepository: ServiceLocator.get<SyncRepository>(),
      secureStorageApi: ServiceLocator.get<SecureStorageApi>(),
      ref: ref,
    );
  },
);
