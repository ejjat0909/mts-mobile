import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/division/division_list_response_model.dart';
import 'package:mts/data/models/division/division_model.dart';
import 'package:mts/domain/repositories/local/division_repository.dart';
import 'package:mts/domain/repositories/remote/division_repository.dart';
import 'package:mts/providers/division/division_state.dart';

/// StateNotifier for Division domain
///
/// Migrated from: division_facade_impl.dart
class DivisionNotifier extends StateNotifier<DivisionState> {
  final LocalDivisionRepository _localRepository;
  final DivisionRepository _remoteRepository;
  final IWebService _webService;

  DivisionNotifier({
    required LocalDivisionRepository localRepository,
    required DivisionRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const DivisionState());

  /// Fetch all divisions from API with pagination
  Future<List<DivisionModel>> syncFromRemote() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      List<DivisionModel> allDivisions = [];
      int currentPage = 1;
      int? lastPage;

      do {
        // Fetch current page
        prints('Fetching divisions page $currentPage');
        DivisionListResponseModel responseModel = await _webService.get(
          getDivisionListResource(currentPage.toString()),
        );

        if (responseModel.isSuccess && responseModel.data != null) {
          // Add divisions from current page to the list
          allDivisions.addAll(responseModel.data!);

          // Get pagination info
          if (responseModel.paginator != null) {
            lastPage = responseModel.paginator!.lastPage;
            prints(
              'Pagination DIVISION: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
            'Failed to fetch divisions page $currentPage: ${responseModel.message}',
          );
          break;
        }
      } while (lastPage != null && currentPage <= lastPage);

      prints(
        'Fetched a total of ${allDivisions.length} divisions from all pages',
      );

      state = state.copyWith(isLoading: false);
      return allDivisions;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Get paginated division list resource
  Resource getDivisionListResource(String page) {
    return _remoteRepository.getDivisionListWithPagination(page);
  }

  // ============================================================
  // CRUD Methods
  // ============================================================

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<DivisionModel> list, {
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

  /// Get all items from local storage
  Future<List<DivisionModel>> getListDivisionModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListDivisionModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<DivisionModel> list) async {
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

  /// Delete a single item by ID
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

  /// Find an item by its ID
  Future<DivisionModel?> getDivisionModelById(String itemId) async {
    try {
      final items = await _localRepository.getListDivisionModel();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => DivisionModel(),
        );
        return item.id != null ? item : null;
      } catch (e) {
        return null;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<DivisionModel> newData, {
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
    List<DivisionModel> list, {
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
      final items = await _localRepository.getListDivisionModel();

      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get division list (old notifier getter)
  List<DivisionModel> get getDivisionList => state.items;

  /// Get divisions filtered by country ID (old notifier method)
  List<DivisionModel> getDivisionsByCountryId(int countryId) {
    return state.items
        .where((division) => division.countryId == countryId)
        .toList();
  }

  /// Get a specific division by ID (old notifier method)
  DivisionModel? getDivisionById(int divisionId) {
    try {
      return state.items.firstWhere((division) => division.id == divisionId);
    } catch (e) {
      return null;
    }
  }
}

/// Provider for sorted items (computed provider)
final sortedDivisionsProvider = Provider<List<DivisionModel>>((ref) {
  final items = ref.watch(divisionProvider).items;
  final sorted = List<DivisionModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for division domain
final divisionProvider = StateNotifierProvider<DivisionNotifier, DivisionState>(
  (ref) {
    return DivisionNotifier(
      localRepository: ServiceLocator.get<LocalDivisionRepository>(),
      remoteRepository: ServiceLocator.get<DivisionRepository>(),
      webService: ServiceLocator.get<IWebService>(),
    );
  },
);

/// Provider for division by ID (family provider for indexed lookups)
final divisionByIdProvider = FutureProvider.family<DivisionModel?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(divisionProvider.notifier);
  return notifier.getDivisionModelById(id);
});

/// Provider for divisions by country ID (computed family provider)
final divisionsByCountryIdProvider = Provider.family<List<DivisionModel>, int>((
  ref,
  countryId,
) {
  final items = ref.watch(divisionProvider).items;
  return items.where((division) => division.countryId == countryId).toList();
});

/// Provider for a specific division by integer ID (computed family provider)
final divisionByIntIdProvider = Provider.family<DivisionModel?, int>((
  ref,
  divisionId,
) {
  final items = ref.watch(divisionProvider).items;
  try {
    return items.firstWhere((division) => division.id == divisionId);
  } catch (e) {
    return null;
  }
});

/// Provider for checking if a division exists by ID (computed family provider)
final divisionExistsByIdProvider = Provider.family<bool, int>((
  ref,
  divisionId,
) {
  final items = ref.watch(divisionProvider).items;
  return items.any((division) => division.id == divisionId);
});

/// Provider for sorted divisions by country ID (computed family provider)
final sortedDivisionsByCountryIdProvider =
    Provider.family<List<DivisionModel>, int>((ref, countryId) {
      final divisions = ref.watch(divisionsByCountryIdProvider(countryId));
      final sorted = List<DivisionModel>.from(divisions);
      sorted.sort(
        (a, b) => (a.name ?? '').toLowerCase().compareTo(
          (b.name ?? '').toLowerCase(),
        ),
      );
      return sorted;
    });

/// Provider for division count per country (computed family provider)
final divisionCountPerCountryProvider = Provider.family<int, int>((
  ref,
  countryId,
) {
  final divisions = ref.watch(divisionsByCountryIdProvider(countryId));
  return divisions.length;
});
