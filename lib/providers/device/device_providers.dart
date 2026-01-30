import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/pos_device/pos_device_list_response_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/domain/repositories/local/device_repository.dart';
import 'package:mts/domain/repositories/remote/device_repository.dart';
import 'package:mts/providers/device/device_state.dart';

/// StateNotifier for Device domain
///
/// Migrated from: device_facade_impl.dart
class DeviceNotifier extends StateNotifier<DeviceState> {
  final LocalDeviceRepository _localRepository;
  final DeviceRepository _remoteRepository;
  final IWebService _webService;

  DeviceNotifier({
    required LocalDeviceRepository localRepository,
    required DeviceRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const DeviceState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<PosDeviceModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<PosDeviceModel>.from(state.items);
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
  Future<List<PosDeviceModel>> getListDeviceModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListDeviceModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(
    List<PosDeviceModel> list, {
    required bool isInsertToPending,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

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

  /// Delete a single item by ID
  Future<void> delete(String id, {bool isInsertToPending = true}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _localRepository.delete(id, isInsertToPending: isInsertToPending);

      final updatedItems = state.items.where((item) => item.id != id).toList();
      state = state.copyWith(items: updatedItems, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Update a single item in local storage
  Future<int> update(
    PosDeviceModel model, {
    bool isInsertToPending = true,
  }) async {
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

  /// Set device in GetIt service locator (for backward compatibility)
  void setGetIt(PosDeviceModel posDeviceModel) {
    if (!GetIt.instance.isRegistered<PosDeviceModel>()) {
      GetIt.instance.registerSingleton<PosDeviceModel>(posDeviceModel);
    } else {
      GetIt.instance.unregister<PosDeviceModel>();
      GetIt.instance.registerSingleton<PosDeviceModel>(posDeviceModel);
    }
  }

  /// Find an item by its ID
  Future<PosDeviceModel?> getDeviceModelById(String itemId) async {
    try {
      // First check current state
      final cachedItem =
          state.items.where((item) => item.id == itemId).firstOrNull;
      if (cachedItem != null) return cachedItem;

      // Fall back to repository
      return await _localRepository.getDeviceById(itemId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Get latest device model
  Future<PosDeviceModel?> getLatestDeviceModel() async {
    try {
      return await _localRepository.getLatestDeviceModel();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Add or update device (old notifier method)
  void addOrUpdate(PosDeviceModel deviceModel) {
    final currentItems = List<PosDeviceModel>.from(state.items);
    final index = currentItems.indexWhere((item) => item.id == deviceModel.id);

    if (index >= 0) {
      currentItems[index] = deviceModel;
    } else {
      currentItems.add(deviceModel);
    }

    state = state.copyWith(items: currentItems);
  }

  /// Get device by ID (old notifier method)
  PosDeviceModel? getDeviceById(String id) {
    return state.items.where((item) => item.id == id).firstOrNull;
  }

  /// Get list of devices (old notifier getter)
  List<PosDeviceModel> get getListDevices => state.items;

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<PosDeviceModel> newData, {
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

  /// Upsert bulk items to Hive box
  Future<bool> upsertBulk(
    List<PosDeviceModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<PosDeviceModel>.from(state.items);
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
      final items = await _localRepository.getListDeviceModel();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<List<PosDeviceModel>> getListDevicesFromLocalDB() async {
    return await _localRepository.getListDeviceModel();
  }

  Future<List<PosDeviceModel>> syncFromRemote() async {
    List<PosDeviceModel> allDevices = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching devices page $currentPage');
      PosDeviceListResponseModel responseModel = await _webService.get(
        getDeviceListWithPagination(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Add devices from current page to the list
        allDevices.addAll(responseModel.data!);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination DEVICE: current page=$currentPage, last page=$lastPage, total devices=${responseModel.paginator!.total}',
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
          'Failed to fetch devices page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints('Fetched a total of ${allDevices.length} devices from all pages');
    return allDevices;
  }

  Resource getDeviceListWithPagination(String page) {
    return _remoteRepository.getDeviceListWithPagination(page);
  }

  List<PosDeviceModel> getListDeviceFromHive() {
    return _localRepository.getListDeviceFromHive();
  }
}

/// Provider for device domain
final deviceProvider = StateNotifierProvider<DeviceNotifier, DeviceState>((
  ref,
) {
  return DeviceNotifier(
    localRepository: ServiceLocator.get<LocalDeviceRepository>(),
    remoteRepository: ServiceLocator.get<DeviceRepository>(),
    webService: ServiceLocator.get<IWebService>(),
  );
});

/// Provider for sorted items (computed provider)
final sortedDevicesProvider = Provider<List<PosDeviceModel>>((ref) {
  final items = ref.watch(deviceProvider).items;
  final sorted = List<PosDeviceModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for device by ID (family provider for indexed lookups)
final deviceByIdProvider = Provider.family<PosDeviceModel?, String>((ref, id) {
  final items = ref.watch(deviceProvider).items;
  try {
    return items.firstWhere((item) => item.id == id);
  } catch (_) {
    return null;
  }
});
