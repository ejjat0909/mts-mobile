import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/data/models/error_log/error_log_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/domain/repositories/local/error_log_repository.dart';
import 'package:mts/providers/error_log/error_log_state.dart';

/// StateNotifier for ErrorLog domain
///
/// Migrated from: error_log_facade_impl.dart
class ErrorLogNotifier extends StateNotifier<ErrorLogState> {
  final LocalErrorLogRepository _localRepository;

  ErrorLogNotifier({required LocalErrorLogRepository localRepository})
    : _localRepository = localRepository,
      super(const ErrorLogState());

  /// Insert a single item
  Future<int> insert(
    ErrorLogModel model, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(
        model,
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

  /// Update an existing item
  Future<int> update(ErrorLogModel errorLogModel) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.update(errorLogModel, true);

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

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<ErrorLogModel> list, {
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
  Future<List<ErrorLogModel>> getListErrorLogModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListErrorLogModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Get items (sync version for state access)
  List<ErrorLogModel> getListErrorLogSync() {
    return state.items;
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<ErrorLogModel> list) async {
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

  /// Delete a single item by ID
  Future<int> delete(String id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.delete(id, true);

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
  Future<ErrorLogModel?> getErrorLogModelById(String itemId) async {
    try {
      final items = await _localRepository.getListErrorLogModel();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => ErrorLogModel(),
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

  /// Create and insert a dummy error log for testing
  Future<void> createAndInsertDummyErrorLog() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final PosDeviceModel deviceModel = ServiceLocator.get<PosDeviceModel>();
      final UserModel userModel = ServiceLocator.get<UserModel>();

      ErrorLogModel errorLogModel = ErrorLogModel(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        id: IdUtils.generateUUID(),
        description: jsonEncode(
          jsonEncode({
            'error_message': 'No Error',
            'response_message': '-',
            'sync_operation': 'pending_changes_sync',
            'response_success': false,
          }),
        ),
        posDeviceId: deviceModel.id,
        deviceName: deviceModel.name,
        currentUserName: userModel.name,
        userId: userModel.id,
      );

      await _localRepository.insert(errorLogModel, true);
      await _loadItems();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create and insert an error log with a custom message
  Future<void> createAndInsertErrorLog(String message) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _localRepository.createAndInsertErrorLog(message);
      await _loadItems();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Internal helper to load items and update state
  Future<void> _loadItems() async {
    try {
      final items = await _localRepository.getListErrorLogModel();
      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get error log list (old notifier getter)
  List<ErrorLogModel> get getErrorLogList => state.items;

  /// Set the list of error logs (old notifier method)
  void setListErrorLog(List<ErrorLogModel> list) {
    state = state.copyWith(items: list);
  }

  /// Add or update list of error logs (old notifier method)
  void addOrUpdateList(List<ErrorLogModel> list) {
    final currentItems = List<ErrorLogModel>.from(state.items);

    for (ErrorLogModel errorLog in list) {
      int index = currentItems.indexWhere(
        (element) => element.id == errorLog.id,
      );

      if (index != -1) {
        currentItems[index] = errorLog;
      } else {
        currentItems.add(errorLog);
      }
    }
    state = state.copyWith(items: currentItems);
  }

  /// Add or update a single error log (old notifier method)
  void addOrUpdate(ErrorLogModel errorLog) {
    final currentItems = List<ErrorLogModel>.from(state.items);
    int index = currentItems.indexWhere((p) => p.id == errorLog.id);

    if (index != -1) {
      currentItems[index] = errorLog;
    } else {
      currentItems.add(errorLog);
    }
    state = state.copyWith(items: currentItems);
  }

  /// Remove an error log by ID (old notifier method)
  void remove(String id) {
    final updatedItems =
        state.items.where((errorLog) => errorLog.id != id).toList();
    state = state.copyWith(items: updatedItems);
  }
}

/// Provider for sorted items (computed provider)
final sortedErrorLogsProvider = Provider<List<ErrorLogModel>>((ref) {
  final items = ref.watch(errorLogProvider).items;
  final sorted = List<ErrorLogModel>.from(items);
  sorted.sort((a, b) {
    final aTime = a.createdAt;
    final bTime = b.createdAt;
    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    return aTime.compareTo(bTime);
  });
  return sorted;
});

/// Provider for errorLog domain
final errorLogProvider = StateNotifierProvider<ErrorLogNotifier, ErrorLogState>(
  (ref) {
    return ErrorLogNotifier(
      localRepository: ServiceLocator.get<LocalErrorLogRepository>(),
    );
  },
);

/// Provider for errorLog by ID (family provider for indexed lookups)
final errorLogByIdProvider = FutureProvider.family<ErrorLogModel?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(errorLogProvider.notifier);
  return notifier.getErrorLogModelById(id);
});

/// Provider for error log count (computed provider)
final errorLogCountProvider = Provider<int>((ref) {
  final items = ref.watch(errorLogProvider).items;
  return items.length;
});

/// Provider for recent error logs (computed family provider)
final recentErrorLogsProvider = Provider.family<List<ErrorLogModel>, int>((
  ref,
  count,
) {
  final sortedItems = ref.watch(sortedErrorLogsProvider);
  return sortedItems.take(count).toList();
});

/// Provider for error logs by user ID (computed family provider)
final errorLogsByUserIdProvider = Provider.family<List<ErrorLogModel>, String>((
  ref,
  userId,
) {
  final items = ref.watch(errorLogProvider).items;
  return items.where((log) => log.userId == userId).toList();
});

/// Provider for error logs by device ID (computed family provider)
final errorLogsByDeviceIdProvider =
    Provider.family<List<ErrorLogModel>, String>((ref, deviceId) {
      final items = ref.watch(errorLogProvider).items;
      return items.where((log) => log.posDeviceId == deviceId).toList();
    });

/// Provider for error logs by date range (computed family provider)
final errorLogsByDateRangeProvider =
    Provider.family<List<ErrorLogModel>, ({DateTime start, DateTime end})>((
      ref,
      dateRange,
    ) {
      final items = ref.watch(errorLogProvider).items;
      return items.where((log) {
        if (log.createdAt == null) return false;
        return log.createdAt!.isAfter(dateRange.start) &&
            log.createdAt!.isBefore(dateRange.end);
      }).toList();
    });

/// Provider for today's error logs (computed provider)
final todayErrorLogsProvider = Provider<List<ErrorLogModel>>((ref) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final items = ref.watch(errorLogProvider).items;
  return items.where((log) {
    if (log.createdAt == null) return false;
    return log.createdAt!.isAfter(startOfDay) &&
        log.createdAt!.isBefore(endOfDay);
  }).toList();
});

/// Provider for error log count by user (computed family provider)
final errorLogCountByUserProvider = Provider.family<int, String>((ref, userId) {
  final logs = ref.watch(errorLogsByUserIdProvider(userId));
  return logs.length;
});

/// Provider for error log count by device (computed family provider)
final errorLogCountByDeviceProvider = Provider.family<int, String>((
  ref,
  deviceId,
) {
  final logs = ref.watch(errorLogsByDeviceIdProvider(deviceId));
  return logs.length;
});
