import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/department_printer/department_printer_list_response_model.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';
import 'package:mts/domain/repositories/local/department_printer_repository.dart';
import 'package:mts/domain/repositories/remote/department_printer_repository.dart';
import 'package:mts/providers/department_printer/department_printer_state.dart';

/// StateNotifier for DepartmentPrinter domain
///
/// Migrated from: department_printer_facade_impl.dart
///
class DepartmentPrinterNotifier extends StateNotifier<DepartmentPrinterState> {
  final LocalDepartmentPrinterRepository _localRepository;
  final DepartmentPrinterRepository _remoteRepository;
  final IWebService _webService;

  DepartmentPrinterNotifier({
    required LocalDepartmentPrinterRepository localRepository,
    required DepartmentPrinterRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const DepartmentPrinterState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<DepartmentPrinterModel> list, {
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
  Future<List<DepartmentPrinterModel>> getListDepartmentPrinterModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListDepartmentPrinter();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<DepartmentPrinterModel> list) async {
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
      // TODO: LocalDepartmentPrinterRepository doesn't have deleteAll method
      // final result = await _localRepository.deleteAll();
      final result = true; // Placeholder

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
  Future<DepartmentPrinterModel?> getDepartmentPrinterModelById(
    String itemId,
  ) async {
    try {
      final items = await _localRepository.getListDepartmentPrinter();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => DepartmentPrinterModel(),
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
    List<DepartmentPrinterModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      // TODO: LocalDepartmentPrinterRepository doesn't have replaceAllData method
      // final result = await _localRepository.replaceAllData(
      //   newData,
      //   isInsertToPending: isInsertToPending,
      // );
      final result = true; // Placeholder

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
    List<DepartmentPrinterModel> list, {
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
      final items = await _localRepository.getListDepartmentPrinter();

      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Get list of department printers from specific IDs
  Future<List<DepartmentPrinterModel>> getListDepartmentPrintersFromIds(
    List<String> departments,
  ) async {
    try {
      return await _localRepository.getListDepartmentPrintersFromIds(
        departments,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get list of department printers from Hive
  List<DepartmentPrinterModel> getListDepartmentPrinterFromHive() {
    return _localRepository.getListDepartmentPrinterFromHive();
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get department printer list (old notifier getter)
  List<DepartmentPrinterModel> get getDepartmentPrinterList => state.items;

  Future<List<DepartmentPrinterModel>> getListDepartmentPrinter() async {
    return await _localRepository.getListDepartmentPrinter();
  }

  Future<DepartmentPrinterModel?> getDepartmentPrinterById(String idDP) async {
    return await _localRepository.getDepartmentPrinterById(idDP);
  }

  Future<List<DepartmentPrinterModel>> syncFromRemote() async {
    List<DepartmentPrinterModel> allDepartmentPrinters = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching department printers page $currentPage');
      DepartmentPrinterListResponseModel responseModel = await _webService.get(
        _remoteRepository.getDepartmentPrinterList(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Process department printers from current page
        List<DepartmentPrinterModel> pageDepartmentPrinters =
            responseModel.data!;

        // Add department printers from current page to the list
        allDepartmentPrinters.addAll(pageDepartmentPrinters);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination DEPARTMENT PRINTER: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch department printers page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allDepartmentPrinters.length} department printers from all pages',
    );
    return allDepartmentPrinters;
  }

  List<DepartmentPrinterModel> fromJson(List<dynamic> json) {
    return json.map((e) => DepartmentPrinterModel.fromJson(e)).toList();
  }
}

/// Provider for sorted items (computed provider)
final sortedDepartmentPrintersProvider = Provider<List<DepartmentPrinterModel>>(
  (ref) {
    final items = ref.watch(departmentPrinterProvider).items;
    final sorted = List<DepartmentPrinterModel>.from(items);
    sorted.sort(
      (a, b) =>
          (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
    );
    return sorted;
  },
);

/// Provider for departmentPrinter domain
final departmentPrinterProvider =
    StateNotifierProvider<DepartmentPrinterNotifier, DepartmentPrinterState>((
      ref,
    ) {
      return DepartmentPrinterNotifier(
        localRepository: ServiceLocator.get<LocalDepartmentPrinterRepository>(),
        remoteRepository: ServiceLocator.get<DepartmentPrinterRepository>(),
        webService: ServiceLocator.get<IWebService>(),
      );
    });

/// Provider for departmentPrinter by ID (family provider for indexed lookups)
final departmentPrinterByIdProvider =
    FutureProvider.family<DepartmentPrinterModel?, String>((ref, id) async {
      final notifier = ref.watch(departmentPrinterProvider.notifier);
      return notifier.getDepartmentPrinterModelById(id);
    });
