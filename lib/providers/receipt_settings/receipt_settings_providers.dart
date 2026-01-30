import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/data/models/receipt_setting/receipt_settings_list_response_model.dart';
import 'package:mts/data/models/receipt_setting/receipt_settings_model.dart';
import 'package:mts/domain/repositories/local/receipt_settings_repository.dart';
import 'package:mts/domain/repositories/remote/receipt_settings_repository.dart';
import 'package:mts/providers/receipt_settings/receipt_settings_state.dart';

/// StateNotifier for ReceiptSettings domain
///
/// Migrated from: receipt_settings_facade_impl.dart
///
class ReceiptSettingsNotifier extends StateNotifier<ReceiptSettingsState> {
  final LocalReceiptSettingsRepository _localRepository;
  final ReceiptSettingsRepository _remoteRepository;
  final IWebService _webService;

  ReceiptSettingsNotifier({
    required LocalReceiptSettingsRepository localRepository,
    required ReceiptSettingsRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const ReceiptSettingsState());

  // ============================================================
  // Business logic migrated from receipt_settings_facade_impl.dart
  // ============================================================

  /// Insert a single receipt settings into local storage
  Future<int> insert(ReceiptSettingsModel model) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(model, true);

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

  /// Update a single receipt settings in local storage
  Future<int> update(ReceiptSettingsModel model) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.update(model, true);

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
    List<ReceiptSettingsModel> list, {
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
  Future<List<ReceiptSettingsModel>> getListReceiptSettings() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListReceiptSettings();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Get receipt settings from Hive (synchronous)
  List<ReceiptSettingsModel> getListReceiptSettingsFromHive() {
    try {
      return _localRepository.getListReceiptSettingsFromHive();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get receipt settings from API
  Future<List<ReceiptSettingsModel>> syncFromRemote() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      ReceiptSettingsListResponseModel responseModel = await _webService.get(
        _remoteRepository.getListReceiptSettings(),
      );

      final items =
          responseModel.isSuccess && responseModel.data != null
              ? responseModel.data!
              : <ReceiptSettingsModel>[];

      state = state.copyWith(isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<ReceiptSettingsModel> list) async {
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
  Future<ReceiptSettingsModel?> getReceiptSettingsModelById(
    String itemId,
  ) async {
    try {
      final items = await _localRepository.getListReceiptSettings();

      try {
        final item = items.firstWhere((item) => item.id == itemId);
        return item;
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
    List<ReceiptSettingsModel> newData, {
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
    List<ReceiptSettingsModel> list, {
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
      final items = await _localRepository.getListReceiptSettings();

      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================-

  /// Get receipt settings list (old notifier getter)
  List<ReceiptSettingsModel> get getReceiptSettingsList => state.items;
}

/// Provider for sorted items (computed provider)
final sortedReceiptSettingssProvider = Provider<List<ReceiptSettingsModel>>((
  ref,
) {
  final items = ref.watch(receiptSettingsProvider).items;
  final sorted = List<ReceiptSettingsModel>.from(items);
  sorted.sort((a, b) {
    if (a.createdAt == null && b.createdAt == null) return 0;
    if (a.createdAt == null) return 1;
    if (b.createdAt == null) return -1;
    return b.createdAt!.compareTo(a.createdAt!);
  });
  return sorted;
});

/// Provider for receiptSettings domain
final receiptSettingsProvider =
    StateNotifierProvider<ReceiptSettingsNotifier, ReceiptSettingsState>((ref) {
      return ReceiptSettingsNotifier(
        localRepository: ServiceLocator.get<LocalReceiptSettingsRepository>(),
        remoteRepository: ServiceLocator.get<ReceiptSettingsRepository>(),
        webService: ServiceLocator.get<IWebService>(),
      );
    });

/// Provider for receiptSettings by ID (family provider for indexed lookups)
final receiptSettingsByIdProvider =
    FutureProvider.family<ReceiptSettingsModel?, String>((ref, id) async {
      final notifier = ref.watch(receiptSettingsProvider.notifier);
      return notifier.getReceiptSettingsModelById(id);
    });
