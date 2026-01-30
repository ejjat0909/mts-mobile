import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/domain/repositories/local/table_repository.dart';
import 'package:mts/providers/table/table_state.dart';
import 'package:mts/core/enum/table_status_enum.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/table/table_list_response_model.dart';
import 'package:mts/domain/repositories/remote/table_repository.dart';

/// StateNotifier for Table domain
///
/// Follows guideline: Providers call LocalRepository directly for CRUD operations
class TableNotifier extends StateNotifier<TableState> {
  final LocalTableRepository _localRepository;
  final TableRepository _remoteRepository;
  final IWebService _webService;

  TableNotifier({
    required LocalTableRepository localRepository,
    required IWebService webService,
    required TableRepository remoteRepository,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const TableState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<TableModel> list, {
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
  Future<List<TableModel>> getListTableModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getTables();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<TableModel> list) async {
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
  Future<TableModel?> getTableModelById(String itemId) async {
    try {
      final items = await _localRepository.getTables();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => TableModel(),
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
    List<TableModel> newData, {
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
    List<TableModel> list, {
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
      final items = await _localRepository.getTables();

      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<int> insert(TableModel tableModel) async {
    return await _localRepository.insert(tableModel, true);
  }

  Future<int> update(TableModel tableModel) async {
    return await _localRepository.update(tableModel, true);
  }

  Future<List<TableModel>> getTables() async {
    return await _localRepository.getTables();
  }

  Future<TableModel?> getTableById(String idTable) async {
    return await _localRepository.getTableById(idTable);
  }

  Future<List<TableModel>> syncFromRemote() async {
    List<TableModel> allTables = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching tables page $currentPage');
      TableListResponseModel responseModel = await _webService.get(
        getTableList(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Add tables from current page to the list
        allTables.addAll(responseModel.data!);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination TABLE: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch tables page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints('Fetched a total of ${allTables.length} tables from all pages');
    return allTables;
  }

  Resource getTableList(String page) {
    return _remoteRepository.getTableList(page);
  }

  Future<void> resetTable(TableModel tableModel) async {
    if (tableModel.id == null) {
      return;
    }

    tableModel.saleId = null;
    tableModel.staffId = null;
    tableModel.status = TableStatusEnum.UNOCCUPIED;
    tableModel.customerId = null;

    tableModel.predefinedOrderId = null;

    tableModel.updatedAt = DateTime.now();

    // Update in database
    prints("Resetting table ${tableModel.toJson()}");
    await update(tableModel);
  }
}

/// Provider for sorted items (computed provider)
final sortedTablesProvider = Provider<List<TableModel>>((ref) {
  final items = ref.watch(tableProvider).items;
  final sorted = List<TableModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for table domain
final tableProvider = StateNotifierProvider<TableNotifier, TableState>((ref) {
  return TableNotifier(
    localRepository: ServiceLocator.get<LocalTableRepository>(),
    remoteRepository: ServiceLocator.get<TableRepository>(),
    webService: ServiceLocator.get<IWebService>(),
  );
});

/// Provider for table by ID (family provider for indexed lookups)
final tableByIdProvider = FutureProvider.family<TableModel?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(tableProvider.notifier);
  return notifier.getTableModelById(id);
});
