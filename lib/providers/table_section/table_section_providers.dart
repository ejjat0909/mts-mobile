import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/table_section/table_section_model.dart';
// import 'package:mts/data/models/table_section/table_section_list_response_model.dart';
import 'package:mts/domain/repositories/local/table_section_repository.dart';
import 'package:mts/providers/table_section/table_section_state.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/table_section/table_section_list_response_model.dart';
import 'package:mts/domain/repositories/remote/table_section_repository.dart';

/// StateNotifier for TableSection domain
///
/// Migrated from: table_section_facade_impl.dart
///
class TableSectionNotifier extends StateNotifier<TableSectionState> {
  final LocalTableSectionRepository _localRepository;
  final TableSectionRepository _remoteRepository;
  final IWebService _webService;

  TableSectionNotifier({
    required LocalTableSectionRepository localRepository,
    required TableSectionRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const TableSectionState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<TableSectionModel> list, {
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
  Future<List<TableSectionModel>> getListTableSectionModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getTableSections();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<TableSectionModel> list) async {
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
        state = state.copyWith(items: [], itemsFromHive: []);
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
  Future<TableSectionModel?> getTableSectionModelById(String itemId) async {
    try {
      final items = await _localRepository.getTableSections();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => TableSectionModel(),
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
    List<TableSectionModel> newData, {
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
    List<TableSectionModel> list, {
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
      final items = await _localRepository.getTableSections();

      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<int> insert(TableSectionModel sectionModel) async {
    return await _localRepository.insert(sectionModel, true);
  }

  Future<int> update(TableSectionModel sectionModel) async {
    return await _localRepository.update(sectionModel, true);
  }

  Future<List<TableSectionModel>> getTableSections() async {
    return await _localRepository.getTableSections();
  }

  Future<TableSectionModel?> getTableSectionById(String id) async {
    return await _localRepository.getTableSectionById(id);
  }

  Resource getTableSectionList(String page) {
    return _remoteRepository.getTableSectionList(page);
  }

  Future<List<TableSectionModel>> syncFromRemote() async {
    List<TableSectionModel> allTableSections = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching table sections page $currentPage');
      TableSectionListResponseModel responseModel = await _webService.get(
        getTableSectionList(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Process table sections from current page
        List<TableSectionModel> pageSections = responseModel.data!;

        // Add table sections from current page to the list
        allTableSections.addAll(pageSections);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination TABLE SECTION: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch table sections page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allTableSections.length} table sections from all pages',
    );
    return allTableSections;
  }
}

/// Provider for sorted items (computed provider)
final sortedTableSectionsProvider = Provider<List<TableSectionModel>>((ref) {
  final items = ref.watch(tableSectionProvider).items;
  final sorted = List<TableSectionModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for tableSection domain
final tableSectionProvider =
    StateNotifierProvider<TableSectionNotifier, TableSectionState>((ref) {
      return TableSectionNotifier(
        localRepository: ServiceLocator.get<LocalTableSectionRepository>(),
        remoteRepository: ServiceLocator.get<TableSectionRepository>(),
        webService: ServiceLocator.get<IWebService>(),
      );
    });

/// Provider for tableSection by ID (family provider for indexed lookups)
final tableSectionByIdProvider =
    FutureProvider.family<TableSectionModel?, String>((ref, id) async {
      final notifier = ref.watch(tableSectionProvider.notifier);
      return notifier.getTableSectionModelById(id);
    });
