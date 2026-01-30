import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/city/city_list_response_model.dart';
import 'package:mts/data/models/city/city_model.dart';
import 'package:mts/domain/repositories/local/city_repository.dart';
import 'package:mts/domain/repositories/remote/city_repository.dart';
import 'package:mts/providers/city/city_state.dart';

/// StateNotifier for City domain
///
/// Migrated from: city_facade_impl.dart
class CityNotifier extends StateNotifier<CityState> {
  final LocalCityRepository _localRepository;
  final CityRepository _remoteRepository;
  final IWebService _webService;

  CityNotifier({
    required LocalCityRepository localRepository,
    required CityRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const CityState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<CityModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<CityModel>.from(state.items);
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
  Future<List<CityModel>> getListCityModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListCityModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<CityModel> list) async {
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
  Future<CityModel?> getCityModelById(String itemId) async {
    try {
      // First check current state
      final cachedItem =
          state.items.where((item) => item.id == itemId).firstOrNull;
      if (cachedItem != null) return cachedItem;

      // Fall back to repository
      return await _localRepository.getCityModelById(itemId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get cities by division ID (old notifier method)
  List<CityModel> getCitiesByDivisionId(String divisionId) {
    return state.items.where((item) => item.divisionId == divisionId).toList();
  }

  /// Get city by ID (old notifier method)
  CityModel? getCityById(String id) {
    return state.items.where((item) => item.id == id).firstOrNull;
  }

  /// Get city list (old notifier getter)
  List<CityModel> get getCityList => state.items;

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<CityModel> newData, {
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
    List<CityModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<CityModel>.from(state.items);
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
      final items = await _localRepository.getListCityModel();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<List<CityModel>> syncFromRemote() async {
    List<CityModel> allCities = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching cities page $currentPage');
      CityListResponseModel responseModel = await _webService.get(
        _remoteRepository.getCityListWithPagination(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Add cities from current page to the list
        allCities.addAll(responseModel.data!);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination CITY: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch cities page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints('Fetched a total of ${allCities.length} cities from all pages');
    return allCities;
  }

  List<CityModel> getListCityFromHive() {
    return _localRepository.getListCityFromHive();
  }
}

/// Provider for city domain
final cityProvider = StateNotifierProvider<CityNotifier, CityState>((ref) {
  return CityNotifier(
    localRepository: ServiceLocator.get<LocalCityRepository>(),
    remoteRepository: ServiceLocator.get<CityRepository>(),
    webService: ServiceLocator.get<IWebService>(),
  );
});

/// Provider for sorted items (computed provider)
final sortedCitiesProvider = Provider<List<CityModel>>((ref) {
  final items = ref.watch(cityProvider).items;
  final sorted = List<CityModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for city by ID (family provider for indexed lookups)
final cityByIdProvider = Provider.family<CityModel?, String>((ref, id) {
  final items = ref.watch(cityProvider).items;
  try {
    return items.firstWhere((item) => item.id == id);
  } catch (_) {
    return null;
  }
});
