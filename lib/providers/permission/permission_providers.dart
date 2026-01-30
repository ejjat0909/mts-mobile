import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/enums/permission_enum.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/string_utils.dart';
import 'package:mts/data/models/permission/permission_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/domain/repositories/local/permission_repository.dart';
import 'package:mts/providers/permission/permission_state.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/data/models/default_response_model.dart';
import 'package:mts/domain/repositories/remote/permission_repository.dart';

/// StateNotifier for Permission domain
///
/// Migrated from: permission_facade_impl.dart
class PermissionNotifier extends StateNotifier<PermissionState> {
  final LocalPermissionRepository _localRepository;
  final PermissionRepository _remoteRepository;
  final IWebService _webService;

  PermissionNotifier({
    required LocalPermissionRepository localRepository,
    required PermissionRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const PermissionState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<PermissionModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<PermissionModel>.from(state.items);
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
  Future<List<PermissionModel>> getListPermissionModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListPermissionModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<PermissionModel> list) async {
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
  Future<PermissionModel?> getPermissionModelById(String itemId) async {
    try {
      // First check current state
      final cachedItem =
          state.items.where((item) => item.id == itemId).firstOrNull;
      if (cachedItem != null) return cachedItem;

      // Fall back to repository
      return await _localRepository.getPermissionById(itemId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<PermissionModel> newData, {
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

  /// Upsert bulk items to Hive box without replacing all items
  Future<bool> upsertBulk(
    List<PermissionModel> list, {
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
        final currentItems = List<PermissionModel>.from(state.items);
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
      final items = await _localRepository.getListPermissionModel();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get permission list (old notifier getter)
  List<PermissionModel> get getPermissionList => state.items;

  /// Get list staff permission (old notifier getter)
  List<PermissionModel> get getListStaffPM => state.listStaffPM;

  /// Assign staff permission (old notifier method)
  void assignStaffPermission(UserModel incomingUser, bool isDeleteUser) {
    final currentUser = ServiceLocator.get<UserModel>();
    if (incomingUser.id == null) {
      return;
    }

    // check if incoming user is current user
    if (incomingUser.id == currentUser.id) {
      // assign
      if (incomingUser.posPermissionJson == null) {
        return;
      }

      // clear list staff permission
      if (isDeleteUser) {
        state = state.copyWith(listStaffPM: []);
        return;
      }

      dynamic nameJson = jsonDecode(incomingUser.posPermissionJson!);
      List<String> names = List<String>.from(nameJson);

      final listStaffPM = <PermissionModel>[];
      for (String name in names) {
        PermissionModel pm = PermissionModel(
          id: IdUtils.generateUUID(),
          name: name,
          description: StringUtils.convertPermissionNameToDesc(name),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        listStaffPM.add(pm);
      }

      state = state.copyWith(listStaffPM: listStaffPM);
    } else {
      return;
    }
  }

  /// Check if staff has a specific permission (old notifier method)
  bool hasStaffPermission(String permission) {
    return state.listStaffPM.any((pm) => pm.name == permission);
  }

  // Perform Refund Permission
  bool hasPerformRefundPermission() {
    return hasStaffPermission(PermissionEnum.PERFORM_REFUND);
  }

  // Accept Payment Permission
  bool hasAcceptPaymentPermission() {
    return hasStaffPermission(PermissionEnum.ACCEPT_PAYMENT);
  }

  // Access POS Permission
  bool hasAccessPOSPermission() {
    return hasStaffPermission(PermissionEnum.ACCESS_POS);
  }

  // Change Settings Permission
  bool hasChangeSettingsPermission() {
    return hasStaffPermission(PermissionEnum.CHANGE_SETTINGS);
  }

  // Manage All Open Orders Permission
  bool hasManageAllOpenOrdersPermission() {
    return hasStaffPermission(PermissionEnum.MANAGE_ALL_OPEN_ORDERS);
  }

  // Open Cash Drawer Without Making Sale Permission
  bool hasOpenCashDrawerWithoutMakingSalePermission() {
    return hasStaffPermission(
      PermissionEnum.OPEN_CASH_DRAWER_WITHOUT_MAKING_SALE,
    );
  }

  // View All Receipt Permission
  bool hasViewAllReceiptPermission() {
    return hasStaffPermission(PermissionEnum.VIEW_ALL_RECEIPT);
  }

  // View Shift Reports Permission
  bool hasViewShiftReportsPermission() {
    return hasStaffPermission(PermissionEnum.VIEW_SHIFT_REPORTS);
  }

  // Void Saved Items In Open Order Permission
  bool hasVoidSavedItemsInOpenOrderPermission() {
    return hasStaffPermission(PermissionEnum.VOID_SAVED_ITEMS_IN_OPEN_ORDER);
  }

  Future<int> insert(PermissionModel permissionModel) async {
    return await _localRepository.insert(permissionModel, true);
  }

  List<PermissionModel> getListPermissionFromHive() {
    return _localRepository.getListPermissionFromHive();
  }

  Future<int> update(PermissionModel permissionModel) async {
    return await _localRepository.update(permissionModel, true);
  }

  Future<List<PermissionModel>> getListPermissions() async {
    return await _localRepository.getListPermissions();
  }

  Future<PermissionModel?> getPermissionById(String id) async {
    return await _localRepository.getPermissionById(id);
  }

  Future<List<PermissionModel>> syncFromRemote() async {
    List<PermissionModel> listPM = [];
    DefaultResponseModel responseModel = await _webService.get(
      _remoteRepository.getAllPermissions(),
    );

    if (responseModel.isSuccess && responseModel.data != null) {
      List<String> names = List<String>.from(responseModel.data!);

      for (String name in names) {
        DateTime now = DateTime.now();
        PermissionModel pm = PermissionModel(
          id: IdUtils.generateUUID(),
          name: name,
          description: StringUtils.convertPermissionNameToDesc(name),
          createdAt: now,
          updatedAt: now,
        );

        listPM.add(pm);
      }

      return listPM;
    } else {
      return [];
    }
  }
}

/// Provider for permission domain
final permissionProvider =
    StateNotifierProvider<PermissionNotifier, PermissionState>((ref) {
      return PermissionNotifier(
        localRepository: ServiceLocator.get<LocalPermissionRepository>(),
        remoteRepository: ServiceLocator.get<PermissionRepository>(),
        webService: ServiceLocator.get<IWebService>(),
      );
    });

/// Provider for sorted items (computed provider)
final sortedPermissionsProvider = Provider<List<PermissionModel>>((ref) {
  final items = ref.watch(permissionProvider).items;
  final sorted = List<PermissionModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for permission by ID (family provider for indexed lookups)
final permissionByIdProvider = FutureProvider.family<PermissionModel?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(permissionProvider.notifier);
  return notifier.getPermissionModelById(id);
});

/// Provider for permission by ID (sync version - computed provider)
final permissionByIdSyncProvider = Provider.family<PermissionModel?, String>((
  ref,
  id,
) {
  final items = ref.watch(permissionProvider).items;
  try {
    return items.firstWhere((item) => item.id == id);
  } catch (e) {
    return null;
  }
});

/// Provider for list staff permissions
final listStaffPermissionsProvider = Provider<List<PermissionModel>>((ref) {
  return ref.watch(permissionProvider).listStaffPM;
});

/// Provider to check if staff has a specific permission
final hasStaffPermissionProvider = Provider.family<bool, String>((
  ref,
  permission,
) {
  final notifier = ref.read(permissionProvider.notifier);
  return notifier.hasStaffPermission(permission);
});

/// Provider to check if staff has perform refund permission
final hasPerformRefundPermissionProvider = Provider<bool>((ref) {
  final notifier = ref.read(permissionProvider.notifier);
  return notifier.hasPerformRefundPermission();
});

/// Provider to check if staff has accept payment permission
final hasAcceptPaymentPermissionProvider = Provider<bool>((ref) {
  final notifier = ref.read(permissionProvider.notifier);
  return notifier.hasAcceptPaymentPermission();
});

/// Provider to check if staff has access POS permission
final hasAccessPOSPermissionProvider = Provider<bool>((ref) {
  final notifier = ref.read(permissionProvider.notifier);
  return notifier.hasAccessPOSPermission();
});

/// Provider to check if staff has change settings permission
final hasChangeSettingsPermissionProvider = Provider<bool>((ref) {
  final notifier = ref.read(permissionProvider.notifier);
  return notifier.hasChangeSettingsPermission();
});

/// Provider to check if staff has manage all open orders permission
final hasManageAllOpenOrdersPermissionProvider = Provider<bool>((ref) {
  final notifier = ref.read(permissionProvider.notifier);
  return notifier.hasManageAllOpenOrdersPermission();
});

/// Provider to check if staff has open cash drawer without making sale permission
final hasOpenCashDrawerWithoutMakingSalePermissionProvider = Provider<bool>((
  ref,
) {
  final notifier = ref.read(permissionProvider.notifier);
  return notifier.hasOpenCashDrawerWithoutMakingSalePermission();
});

/// Provider to check if staff has view all receipt permission
final hasViewAllReceiptPermissionProvider = Provider<bool>((ref) {
  final notifier = ref.read(permissionProvider.notifier);
  return notifier.hasViewAllReceiptPermission();
});

/// Provider to check if staff has view shift reports permission
final hasViewShiftReportsPermissionProvider = Provider<bool>((ref) {
  final notifier = ref.read(permissionProvider.notifier);
  return notifier.hasViewShiftReportsPermission();
});

/// Provider to check if staff has void saved items in open order permission
final hasVoidSavedItemsInOpenOrderPermissionProvider = Provider<bool>((ref) {
  final notifier = ref.read(permissionProvider.notifier);
  return notifier.hasVoidSavedItemsInOpenOrderPermission();
});

/// Provider for permissions count
final permissionsCountProvider = Provider<int>((ref) {
  final items = ref.watch(permissionProvider).items;
  return items.length;
});
