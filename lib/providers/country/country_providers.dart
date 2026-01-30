import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/country/country_list_response_model.dart';
import 'package:mts/data/models/country/country_model.dart';
import 'package:mts/domain/repositories/local/country_repository.dart';
import 'package:mts/domain/repositories/remote/country_repository.dart';
import 'package:mts/providers/country/country_state.dart';

/// StateNotifier for Country domain
///
/// Migrated from: country_facade_impl.dart
class CountryNotifier extends StateNotifier<CountryState> {
  final LocalCountryRepository _localRepository;
  final CountryRepository _remoteRepository;
  final IWebService _webService;

  CountryNotifier({
    required LocalCountryRepository localRepository,
    required CountryRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const CountryState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<CountryModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<CountryModel>.from(state.items);
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
  Future<List<CountryModel>> getListCountryModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListCountryModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<CountryModel> list) async {
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
  Future<CountryModel?> getCountryModelById(String itemId) async {
    try {
      // First check current state
      final cachedItem =
          state.items.where((item) => item.id == itemId).firstOrNull;
      if (cachedItem != null) return cachedItem;

      // Fall back to repository
      return await _localRepository.getCountryModelById(itemId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<int> update(CountryModel countryModel) async {
    return await _localRepository.update(countryModel, true);
  }

  Future<List<CountryModel>> syncFromRemote() async {
    List<CountryModel> allCountries = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching countries page $currentPage');
      CountryListResponseModel responseModel = await _webService.get(
        getListCountryWithPagination(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Add countries from current page to the list
        allCountries.addAll(responseModel.data!);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination COUNTRY: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch countries page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allCountries.length} countries from all pages',
    );
    return allCountries;
  }

  Resource getListCountryWithPagination(String page) {
    return _remoteRepository.getCountryListWithPagination(page);
  }

  List<CountryModel> getListCountryFromHive() {
    return _localRepository.getListCountryFromHive();
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get country by ID (old notifier method)
  CountryModel? getCountryById(int id) {
    return state.items.where((item) => item.id == id).firstOrNull;
  }

  /// Get default country only (old notifier method)
  CountryModel? getDefaultCountryOnly() {
    return state.items.where((item) => item.id == 87).firstOrNull;
  }

  /// Get country list (old notifier getter)
  List<CountryModel> get getCountryList => state.items;

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<CountryModel> newData, {
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
    List<CountryModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<CountryModel>.from(state.items);
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
      final items = await _localRepository.getListCountryModel();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Provider for country domain
final countryProvider = StateNotifierProvider<CountryNotifier, CountryState>((
  ref,
) {
  return CountryNotifier(
    localRepository: ServiceLocator.get<LocalCountryRepository>(),
    remoteRepository: ServiceLocator.get<CountryRepository>(),
    webService: ServiceLocator.get<IWebService>(),
  );
});

/// Provider for sorted items (computed provider)
final sortedCountriesProvider = Provider<List<CountryModel>>((ref) {
  final items = ref.watch(countryProvider).items;
  final sorted = List<CountryModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for country by ID (family provider for indexed lookups)
final countryByIdProvider = Provider.family<CountryModel?, String>((ref, id) {
  final items = ref.watch(countryProvider).items;
  try {
    return items.firstWhere((item) => item.id == id);
  } catch (_) {
    return null;
  }
});
