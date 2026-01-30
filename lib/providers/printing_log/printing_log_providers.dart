import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/printing_log/printing_log_model.dart';
import 'package:mts/domain/repositories/local/printing_log_repository.dart';
import 'package:mts/providers/printing_log/printing_log_state.dart';
import 'package:mts/core/enum/printing_status_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/providers/device/device_providers.dart';
import 'package:mts/providers/shift/shift_providers.dart';
import 'package:mts/providers/user/user_providers.dart';

/// StateNotifier for PrintingLog domain
///
/// Migrated from: printing_log_facade_impl.dart
///
class PrintingLogNotifier extends StateNotifier<PrintingLogState> {
  final LocalPrintingLogRepository _localRepository;
  final Ref _ref;

  PrintingLogNotifier({
    required LocalPrintingLogRepository localRepository,
    required Ref ref,
  }) : _localRepository = localRepository,
       _ref = ref,
       super(const PrintingLogState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<PrintingLogModel> list, {
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
  Future<List<PrintingLogModel>> getListPrintingLogModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListPrintingLogModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<PrintingLogModel> list) async {
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
  Future<PrintingLogModel?> getPrintingLogModelById(String itemId) async {
    try {
      final items = await _localRepository.getListPrintingLogModel();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => PrintingLogModel(),
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
    List<PrintingLogModel> newData, {
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

  /// Internal helper to load items and update state
  Future<void> _loadItems() async {
    try {
      final items = await _localRepository.getListPrintingLogModel();

      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get printing log list (old notifier getter)
  List<PrintingLogModel> get getPrintingLogList => state.items;

  /// Set the list of printing logs (old notifier method)
  void setListPrintingLog(List<PrintingLogModel> list) {
    state = state.copyWith(items: list);
  }

  /// Add or update list of printing logs (old notifier method)
  void addOrUpdateList(List<PrintingLogModel> list) {
    final currentItems = List<PrintingLogModel>.from(state.items);

    for (PrintingLogModel printingLog in list) {
      int index = currentItems.indexWhere(
        (element) => element.id == printingLog.id,
      );

      if (index != -1) {
        currentItems[index] = printingLog;
      } else {
        currentItems.add(printingLog);
      }
    }
    state = state.copyWith(items: currentItems);
  }

  /// Add or update a single printing log (old notifier method)
  void addOrUpdate(PrintingLogModel printingLog) {
    final currentItems = List<PrintingLogModel>.from(state.items);
    int index = currentItems.indexWhere((p) => p.id == printingLog.id);

    if (index != -1) {
      currentItems[index] = printingLog;
    } else {
      currentItems.add(printingLog);
    }
    state = state.copyWith(items: currentItems);
  }

  /// Remove a printing log by ID (old notifier method)
  void remove(String id) {
    final updatedItems =
        state.items.where((printingLog) => printingLog.id != id).toList();
    state = state.copyWith(items: updatedItems);
  }

  Future<int> insert(PrintingLogModel model) async {
    return await _localRepository.insert(model, true);
  }

  Future<int> update(PrintingLogModel printingLogModel) async {
    return await _localRepository.update(printingLogModel, true);
  }

  Future<void> createAndInsertPrintingLogModel(
    PrinterSettingModel printerSetting,
    String reason,
  ) async {
    final deviceNotifier = _ref.read(deviceProvider.notifier);
    final userNotifier = _ref.read(userProvider.notifier);
    final staffModel = ServiceLocator.get<StaffModel>();
    UserModel? userModel = await userNotifier.getUserModelFromStaffId(
      staffModel.id!,
    );
    final shiftNotifier = _ref.read(shiftProvider.notifier);
    ShiftModel shiftModel = await shiftNotifier.getLatestShift();

    PosDeviceModel? device = deviceNotifier.getDeviceById(
      printerSetting.posDeviceId ?? '',
    );

    PrintingLogModel plm = PrintingLogModel(
      reason: reason,
      printerIp: printerSetting.identifierAddress,
      printerName: printerSetting.name,
      printerModel: printerSetting.model,
      printerInterface: printerSetting.interface,
      posDeviceName: device!.name,
      posDeviceId: printerSetting.posDeviceId,
      staffName: userModel!.name,
      shiftId: shiftModel.id,
      status: PrintingStatusEnum.success,
      companyId: staffModel.companyId,
      shiftStartAt: shiftModel.createdAt,
    );

    await insert(plm);
    prints('printing log created');
  }
}

/// Provider for sorted items (computed provider)
final sortedPrintingLogsProvider = Provider<List<PrintingLogModel>>((ref) {
  final items = ref.watch(printingLogProvider).items;
  final sorted = List<PrintingLogModel>.from(items);
  sorted.sort(
    (a, b) => (b.createdAt ?? DateTime(2000)).compareTo(
      a.createdAt ?? DateTime(2000),
    ),
  );
  return sorted;
});

/// Provider for printingLog domain
final printingLogProvider =
    StateNotifierProvider<PrintingLogNotifier, PrintingLogState>((ref) {
      return PrintingLogNotifier(
        localRepository: ServiceLocator.get<LocalPrintingLogRepository>(),
        ref: ref,
      );
    });

/// Provider for printingLog by ID (family provider for indexed lookups)
final printingLogByIdProvider =
    FutureProvider.family<PrintingLogModel?, String>((ref, id) async {
      final notifier = ref.watch(printingLogProvider.notifier);
      return notifier.getPrintingLogModelById(id);
    });

/// Provider for printingLog by ID (sync version - computed provider)
final printingLogByIdSyncProvider = Provider.family<PrintingLogModel?, String>((
  ref,
  id,
) {
  final items = ref.watch(printingLogProvider).items;
  try {
    return items.firstWhere((item) => item.id == id);
  } catch (e) {
    return null;
  }
});

/// Provider for printing logs count
final printingLogsCountProvider = Provider<int>((ref) {
  final items = ref.watch(printingLogProvider).items;
  return items.length;
});

/// Provider for printing logs by status
final printingLogsByStatusProvider =
    Provider.family<List<PrintingLogModel>, String>((ref, status) {
      final items = ref.watch(printingLogProvider).items;
      return items.where((item) => item.status == status).toList();
    });

/// Provider for printing logs by printer IP
final printingLogsByPrinterIpProvider =
    Provider.family<List<PrintingLogModel>, String>((ref, printerIp) {
      final items = ref.watch(printingLogProvider).items;
      return items.where((item) => item.printerIp == printerIp).toList();
    });

/// Provider for printing logs by shift ID
final printingLogsByShiftIdProvider =
    Provider.family<List<PrintingLogModel>, String>((ref, shiftId) {
      final items = ref.watch(printingLogProvider).items;
      return items.where((item) => item.shiftId == shiftId).toList();
    });
