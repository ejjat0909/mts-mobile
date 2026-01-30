import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/calc_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/models/shift/shift_list_response_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/domain/repositories/local/printer_setting_repository.dart';
import 'package:mts/domain/repositories/local/receipt_repository.dart';
import 'package:mts/domain/repositories/local/shift_repository.dart';
import 'package:mts/domain/repositories/remote/shift_repository.dart';
import 'package:mts/domain/repositories/remote/sync_repository.dart';
import 'package:mts/providers/shift/shift_state.dart';

/// StateNotifier for Shift domain
///
/// Contains business logic for shift management, cash tracking, and calculations.
/// Orchestrates PrinterSettingRepository, ReceiptRepository for shift operations.
class ShiftNotifier extends StateNotifier<ShiftState> {
  final LocalShiftRepository _localRepository;
  final LocalPrinterSettingRepository _localPrinterSettingRepository;
  final ShiftRepository _remoteRepository;
  final IWebService _webService;
  final LocalReceiptRepository _localReceiptRepository;

  ShiftNotifier({
    required LocalShiftRepository localRepository,
    required LocalPrinterSettingRepository localPrinterSettingRepository,
    required ShiftRepository remoteRepository,
    required IWebService webService,
    required SyncRepository syncRepository,
    required LocalReceiptRepository localReceiptRepository,
  }) : _localRepository = localRepository,
       _localPrinterSettingRepository = localPrinterSettingRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _localReceiptRepository = localReceiptRepository,
       super(const ShiftState());

  /// Insert a single shift
  Future<int> insert(ShiftModel shiftModel) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(shiftModel, true);

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

  /// Update a shift
  Future<int> update(ShiftModel shiftModel) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.update(shiftModel, true);

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

  /// Delete a single shift by ID
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

  /// Check if there are any shifts
  Future<bool> hasShift() async {
    try {
      return await _localRepository.hasShift();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Get latest expected cash amount
  Future<double> getLatestExpectedCash() async {
    try {
      return await _localRepository.getLatestExpectedCash();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return 0.0;
    }
  }

  /// Get the latest shift
  Future<ShiftModel> getLatestShift() async {
    try {
      return await _localRepository.getLatestShift();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return ShiftModel();
    }
  }

  /// Get latest shift and list of printer settings
  Future<Map<String, dynamic>> getLatestShiftAndListPrinter() async {
    try {
      List<PrinterSettingModel> listPsm =
          await _localPrinterSettingRepository.getListPrinterSetting();
      return {
        'latestShift': await getLatestShift(),
        'listPrinterSetting': listPsm,
      };
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return {
        'latestShift': ShiftModel(),
        'listPrinterSetting': <PrinterSettingModel>[],
      };
    }
  }

  /// Get all shifts from API with pagination
  Future<List<ShiftModel>> syncFromRemote() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      List<ShiftModel> allShifts = [];
      int currentPage = 1;
      int? lastPage;

      do {
        prints('Fetching shifts page $currentPage');

        ShiftListResponseModel responseModel = await _webService.get(
          _remoteRepository.getShiftListWithPagination(currentPage.toString()),
        );

        if (responseModel.isSuccess && responseModel.data != null) {
          List<ShiftModel> pageShifts = responseModel.data!;
          for (ShiftModel shiftModel in pageShifts) {
            if (shiftModel.saleSummaryJson != null) {
              shiftModel.saleSummaryJson = shiftModel.saleSummaryJson;
            }
          }

          allShifts.addAll(pageShifts);

          if (responseModel.paginator != null) {
            lastPage = responseModel.paginator!.lastPage;
            prints(
              'Pagination SHIFT: current page=$currentPage, last page=$lastPage, total shifts=${responseModel.paginator!.total}',
            );
          } else {
            break;
          }

          currentPage++;
        } else {
          prints(
            'Failed to fetch shifts page $currentPage: ${responseModel.message}',
          );
          break;
        }
      } while (lastPage != null && currentPage <= lastPage);

      prints('Fetched a total of ${allShifts.length} shifts from all pages');

      state = state.copyWith(isLoading: false);
      return allShifts;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      prints('Error fetching shifts with pagination: $e');
      return [];
    }
  }

  /// Get list of shifts for history
  Future<List<ShiftModel>> getListShiftForHistory() async {
    try {
      return await _localRepository.getListShiftForHistory();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get shift where closed by specific staff and device
  Future<ShiftModel> getShiftWhereClosedBy(
    String staffId,
    String idPosDevice,
  ) async {
    try {
      return await _localRepository.getShiftWhereClosedBy(staffId, idPosDevice);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return ShiftModel();
    }
  }

  /// Calculate change cash rounding
  double calcChangeCashRounding(double amount) {
    double change = CalcUtils.calcCashRounding(amount) - amount;
    return change;
  }

  /// Update expected cash for the latest shift
  ///
  /// Recalculates expected cash based on receipts (refunded and not refunded)
  Future<void> updateExpectedCash() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      /// totalPa = totalPayableAmount
      double totalPaRefunded =
          await _localReceiptRepository.calcPayableAmountRefunded();
      double totalPaNotRefunded =
          await _localReceiptRepository.calcPayableAmountNotRefunded();
      double totalPa = totalPaNotRefunded - totalPaRefunded;
      ShiftModel latestShiftModel = await getLatestShift();

      if (latestShiftModel.id != null) {
        latestShiftModel = latestShiftModel.copyWith(
          expectedCash: latestShiftModel.startingCash! + totalPa,
          cashPayments: totalPaNotRefunded,
          cashRefunds: totalPaRefunded,
          updatedAt: DateTime.now(),
        );
        prints(latestShiftModel.saleSummaryJson);
        await update(latestShiftModel);
      } else {
        prints('LATEST SHIFT MODEL IS NULL');
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      prints('Error updating expected cash: $e');
    }
  }

  /// Notify changes to listeners
  Future<void> noitifyChanges() async {
    try {
      await _localRepository.notifyChanges();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Emit latest expected amount
  Future<void> emitLatestExpectedAmount() async {
    try {
      await _localRepository.emitLatestExpectedAmount();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Get stream of latest expected amount
  Stream<double> getLatestExpectedAmountStream() {
    return _localRepository.getLatestExpectedAmountStream;
  }

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<ShiftModel> list, {
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
  Future<List<ShiftModel>> getListShiftModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListShiftModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<ShiftModel> list) async {
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

  /// Find an item by its ID
  Future<ShiftModel?> getShiftModelById(String itemId) async {
    try {
      final items = await _localRepository.getListShiftModel();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => ShiftModel(),
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
    List<ShiftModel> newData, {
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
    List<ShiftModel> list, {
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

  // ============================================================
  // UI State Management Methods (migrated from old ShiftNotifier)
  // ============================================================

  /// Set current shift model for history view
  void setCurrShiftModel(ShiftModel? shiftModel) {
    state = state.copyWith(currShiftModel: shiftModel);
  }

  /// Set shift to closed state
  void setCloseShift() {
    state = state.copyWith(isCloseShift: true, isOpenShift: false);
  }

  /// Set shift to open state
  void setOpenShift() {
    state = state.copyWith(isOpenShift: true, isCloseShift: false);
  }

  /// Mark close shift button as pressed
  void pressCloseShift() {
    state = state.copyWith(isPressCloseShift: true);
  }

  /// Mark close shift button as not pressed (open shift)
  void pressOpenShift() {
    state = state.copyWith(isPressCloseShift: false);
  }

  /// Set the difference amount for shift reconciliation
  void setDifferenceAmount(double amount) {
    state = state.copyWith(differenceAmount: amount);
  }

  /// Toggle print report setting
  void setPrintReport(bool value) {
    state = state.copyWith(isPrintReport: value);
  }

  /// Toggle print item setting
  void setPrintItem(bool value) {
    state = state.copyWith(isPrintItem: value);
  }

  /// Set shift history title and current shift model for history sidebar
  void setShiftHistoryTitle(String title, ShiftModel? shiftModel) {
    state = state.copyWith(
      shiftHistoryTitle: title,
      currShiftModel: shiftModel,
    );
  }

  // ============================================================
  // Private helper methods
  // ============================================================

  /// Internal helper to load items and update state
  Future<void> _loadItems() async {
    try {
      final items = await _localRepository.getListShiftModel();

      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider for sorted items (computed provider)
final sortedShiftsProvider = Provider<List<ShiftModel>>((ref) {
  final items = ref.watch(shiftProvider).items;
  final sorted = List<ShiftModel>.from(items);
  sorted.sort((a, b) {
    if (a.createdAt == null && b.createdAt == null) return 0;
    if (a.createdAt == null) return 1;
    if (b.createdAt == null) return -1;
    return b.createdAt!.compareTo(a.createdAt!);
  });
  return sorted;
});

/// Provider for shift domain
final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftState>((ref) {
  return ShiftNotifier(
    localRepository: ServiceLocator.get<LocalShiftRepository>(),
    localPrinterSettingRepository:
        ServiceLocator.get<LocalPrinterSettingRepository>(),
    remoteRepository: ServiceLocator.get<ShiftRepository>(),
    webService: ServiceLocator.get<IWebService>(),
    syncRepository: ServiceLocator.get<SyncRepository>(),
    localReceiptRepository: ServiceLocator.get<LocalReceiptRepository>(),
  );
});

/// Provider for shift by ID (family provider for indexed lookups)
final shiftByIdProvider = FutureProvider.family<ShiftModel?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(shiftProvider.notifier);
  return notifier.getShiftModelById(id);
});
