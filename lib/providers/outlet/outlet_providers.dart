import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/domain/repositories/local/outlet_repository.dart';
import 'package:mts/providers/outlet/outlet_state.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/outlet/outlet_list_response_model.dart';
import 'package:mts/domain/repositories/remote/outlet_repository.dart';

/// StateNotifier for Outlet domain
///
/// Migrated from: outlet_facade_impl.dart
class OutletNotifier extends StateNotifier<OutletState> {
  final LocalOutletRepository _localRepository;
  final OutletRepository _remoteRepository;
  final IWebService _webService;

  OutletNotifier({
    required LocalOutletRepository localRepository,
    required OutletRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const OutletState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<OutletModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<OutletModel>.from(state.items);
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
  Future<List<OutletModel>> getListOutletModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListOutletModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<OutletModel> list) async {
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
  Future<OutletModel?> getOutletModelById(String itemId) async {
    try {
      // First check current state
      final cachedItem =
          state.items.where((item) => item.id == itemId).firstOrNull;
      if (cachedItem != null) return cachedItem;

      // Fall back to repository
      return await _localRepository.getOutletModelById(itemId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<OutletModel> newData, {
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
    List<OutletModel> list, {
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
        final currentItems = List<OutletModel>.from(state.items);
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

  /// Get latest outlet model
  Future<OutletModel?> getLatestOutletModel() async {
    try {
      return await _localRepository.getLatestOutletModel();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Add or update list of outlets (old notifier method)
  void addOrUpdateList(List<OutletModel> list) {
    if (list.isEmpty) {
      return;
    }

    final currentItems = List<OutletModel>.from(state.items);

    for (final newItem in list) {
      final index = currentItems.indexWhere((item) => item.id == newItem.id);
      if (index >= 0) {
        currentItems[index] = newItem;
      } else {
        currentItems.add(newItem);
      }
    }

    state = state.copyWith(items: currentItems);

    // Update ServiceLocator outlet if it matches
    OutletModel? outletModel = getLatestOutletModelSync();
    if (outletModel != null) {
      setGetIt(outletModel);
    }
  }

  /// Remove outlet from list by ID (old notifier method)
  void remove(String id) {
    final updatedItems = state.items.where((item) => item.id != id).toList();
    state = state.copyWith(items: updatedItems);
  }

  /// Get outlet by ID (old notifier method)
  OutletModel? getOutletById(String id) {
    return state.items.where((item) => item.id == id).firstOrNull;
  }

  /// Get latest outlet model (synchronous version from old notifier)
  /// Returns the outlet matching the ServiceLocator registered outlet ID
  OutletModel? getLatestOutletModelSync() {
    try {
      final outletModel = ServiceLocator.get<OutletModel>();
      final outlet =
          state.items.where((element) => element.id == outletModel.id).toList();

      if (outlet.isNotEmpty) {
        return outlet.first;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get list of outlets (old notifier getter)
  List<OutletModel> get getListOutlets => state.items;

  /// Refresh state from repository
  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListOutletModel();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<List<OutletModel>> getListOutletsFromLocalDB() async {
    return await _localRepository.getListOutletModel();
  }

  Future<List<OutletModel>> syncFromRemote() async {
    List<OutletModel> allOutlets = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching outlets page $currentPage');
      OutletListResponseModel responseModel = await _webService.get(
        _remoteRepository.getOutletListPaginated(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Add outlets from current page to the list
        allOutlets.addAll(responseModel.data!);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination OUTLET: current page=$currentPage, last page=$lastPage, total outlets=${responseModel.paginator!.total}',
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
          'Failed to fetch outlets page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints('Fetched a total of ${allOutlets.length} outlets from all pages');
    return allOutlets;
  }

  void setGetIt(OutletModel outletModel) {
    if (!GetIt.instance.isRegistered<OutletModel>()) {
      GetIt.instance.registerSingleton<OutletModel>(outletModel);
    } else {
      GetIt.instance.unregister<OutletModel>();
      GetIt.instance.registerSingleton<OutletModel>(outletModel);
    }
  }

  Future<String> getCompanyId() async {
    // get list outlets
    List<OutletModel> listOutlet = await getListOutletsFromLocalDB();
    return listOutlet.first.companyId ?? '';
  }

  Future<void> incrementNextOrderNumber({
    required Function(int runningNumber) onRunningNumber,
  }) async {
    OutletModel? outletModel = await getLatestOutletModel();
    if (outletModel?.id != null && outletModel?.nextOrderNumber != null) {
      int latestNextOrderNumber = outletModel!.nextOrderNumber ?? 1;
      outletModel = outletModel.copyWith(
        nextOrderNumber: latestNextOrderNumber + 1,
        updatedAt: DateTime.now(),
      );
      await upsertBulk([outletModel]);
      prints(
        'INCREMENT NEXT ORDER NUMBER SUCCESS WITH VALUE $latestNextOrderNumber',
      );
      onRunningNumber(latestNextOrderNumber);
    } else {
      prints('LATEST OUTLET MODEL IS NULL, NO OUTLET TO UPDATE');
      await LogUtils.error('LATEST OUTLET MODEL IS NULL, NO OUTLET TO UPDATE');
      onRunningNumber(1);
    }
  }

  Future<void> resetNextOrderNumber() async {
    final outletNotifier = ServiceLocator.get<OutletNotifier>();
    OutletModel? outletModel = await getLatestOutletModel();

    if (outletModel?.id != null && outletModel?.nextOrderNumber != null) {
      outletModel = outletModel!.copyWith(
        nextOrderNumber: 1,
        updatedAt: DateTime.now(),
      );
      outletNotifier.addOrUpdateList([outletModel]);
      await insertBulk([outletModel]);
    } else {
      prints('LATEST SHIFT MODEL IS NULL, NO SHIFT TO UPDATE');
      await LogUtils.error('LATEST SHIFT MODEL IS NULL, NO SHIFT TO UPDATE');
    }
  }

  Future<int> getLatestNextOrderNumber() async {
    OutletModel? outletModel = await getLatestOutletModel();
    return outletModel?.nextOrderNumber ?? 1;
  }

  List<OutletModel> getListOutletFromHive() {
    return _localRepository.getListOutletFromHive();
  }
}

/// Provider for outlet domain
final outletProvider = StateNotifierProvider<OutletNotifier, OutletState>((
  ref,
) {
  return OutletNotifier(
    localRepository: ServiceLocator.get<LocalOutletRepository>(),
    remoteRepository: ServiceLocator.get<OutletRepository>(),
    webService: ServiceLocator.get<IWebService>(),
  );
});

/// Provider for sorted items (computed provider)
final sortedOutletsProvider = Provider<List<OutletModel>>((ref) {
  final items = ref.watch(outletProvider).items;
  final sorted = List<OutletModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for outlet by ID (family provider for indexed lookups)
final outletByIdProvider = FutureProvider.family<OutletModel?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(outletProvider.notifier);
  return notifier.getOutletModelById(id);
});

/// Provider for synchronous outlet by ID (from current state)
final outletByIdFromStateProvider = Provider.family<OutletModel?, String>((
  ref,
  id,
) {
  final notifier = ref.watch(outletProvider.notifier);
  return notifier.getOutletById(id);
});

/// Provider for outlets by company ID (family provider)
final outletsByCompanyIdProvider = Provider.family<List<OutletModel>, String>((
  ref,
  companyId,
) {
  final items = ref.watch(outletProvider).items;
  return items.where((outlet) => outlet.companyId == companyId).toList();
});

/// Provider for outlets by search query (family provider)
final outletsBySearchProvider = Provider.family<List<OutletModel>, String>((
  ref,
  query,
) {
  final items = ref.watch(outletProvider).items;
  if (query.isEmpty) return items;

  final lowerQuery = query.toLowerCase();
  return items.where((outlet) {
    final name = (outlet.name ?? '').toLowerCase();
    final address = (outlet.address ?? '').toLowerCase();
    return name.contains(lowerQuery) || address.contains(lowerQuery);
  }).toList();
});

/// Provider to check if an outlet exists by ID
final outletExistsProvider = Provider.family<bool, String>((ref, id) {
  final items = ref.watch(outletProvider).items;
  return items.any((item) => item.id == id);
});

/// Provider for total outlet count
final outletCountProvider = Provider<int>((ref) {
  final items = ref.watch(outletProvider).items;
  return items.length;
});

/// Provider for outlet count by company (family provider)
final outletCountByCompanyProvider = Provider.family<int, String>((
  ref,
  companyId,
) {
  final outlets = ref.watch(outletsByCompanyIdProvider(companyId));
  return outlets.length;
});

/// Provider for latest outlet model
final latestOutletProvider = FutureProvider<OutletModel?>((ref) async {
  final notifier = ref.watch(outletProvider.notifier);
  return await notifier.getLatestOutletModel();
});

/// Provider for latest outlet model (synchronous)
final latestOutletSyncProvider = Provider<OutletModel?>((ref) {
  final notifier = ref.watch(outletProvider.notifier);
  return notifier.getLatestOutletModelSync();
});

/// Provider for company ID from first outlet
final companyIdProvider = FutureProvider<String>((ref) async {
  final notifier = ref.watch(outletProvider.notifier);
  return await notifier.getCompanyId();
});

/// Provider for latest next order number
final latestNextOrderNumberProvider = FutureProvider<int>((ref) async {
  final notifier = ref.watch(outletProvider.notifier);
  return await notifier.getLatestNextOrderNumber();
});
