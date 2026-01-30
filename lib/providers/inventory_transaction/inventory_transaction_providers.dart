import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/data/models/inventory_transaction/inventory_transaction_model.dart';
import 'package:mts/domain/repositories/local/error_log_repository.dart';
import 'package:mts/domain/repositories/local/inventory_transaction_repository.dart';
import 'package:mts/domain/repositories/remote/inventory_transaction_repository.dart';
import 'package:mts/providers/inventory_transaction/inventory_transaction_state.dart';
import 'package:mts/core/enums/inventory_transaction_type_enum.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/inventory/inventory_model.dart';
import 'package:mts/data/models/inventory_transaction/inventory_transaction_list_response_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';

/// StateNotifier for InventoryTransaction domain
///
/// Migrated from: inventory_transaction_facade_impl.dart
class InventoryTransactionNotifier
    extends StateNotifier<InventoryTransactionState> {
  final LocalInventoryTransactionRepository _localRepository;
  final InventoryTransactionRepository _remoteRepository;
  final IWebService _webService;
  final LocalErrorLogRepository _localErrorLogRepository;

  InventoryTransactionNotifier({
    required LocalInventoryTransactionRepository localRepository,
    required InventoryTransactionRepository remoteRepository,
    required LocalErrorLogRepository localErrorLogRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _localErrorLogRepository = localErrorLogRepository,
       super(const InventoryTransactionState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<InventoryTransactionModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final updatedItems = [...state.items, ...list];
        state = state.copyWith(items: updatedItems);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Get all items from local storage
  Future<List<InventoryTransactionModel>>
  getListInventoryTransactionModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListInventoryTransactionModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<InventoryTransactionModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        final idsToDelete = list.map((e) => e.id).toSet();
        final updatedItems =
            state.items.where((e) => !idsToDelete.contains(e.id)).toList();
        state = state.copyWith(items: updatedItems);
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
        final updatedItems = state.items.where((e) => e.id != id).toList();
        state = state.copyWith(items: updatedItems);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Find an item by its ID
  Future<InventoryTransactionModel?> getInventoryTransactionModelById(
    String itemId,
  ) async {
    try {
      final items = await _localRepository.getListInventoryTransactionModel();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => InventoryTransactionModel(),
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
    List<InventoryTransactionModel> newData, {
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
    List<InventoryTransactionModel> list, {
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
        // Merge upserted items with existing items
        final existingItems = List<InventoryTransactionModel>.from(state.items);
        for (final item in list) {
          final index = existingItems.indexWhere((e) => e.id == item.id);
          if (index >= 0) {
            existingItems[index] = item;
          } else {
            existingItems.add(item);
          }
        }
        state = state.copyWith(items: existingItems);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Insert or update a single item
  Future<int> insert(
    InventoryTransactionModel inventoryTransactionModel, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(
        inventoryTransactionModel,
        isInsertToPending,
      );

      if (result > 0) {
        final updatedItems = [...state.items, inventoryTransactionModel];
        state = state.copyWith(items: updatedItems);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Update an existing item
  Future<int> update(
    InventoryTransactionModel inventoryTransactionModel, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.update(
        inventoryTransactionModel,
        isInsertToPending,
      );

      if (result > 0) {
        final updatedItems =
            state.items.map((item) {
              return item.id == inventoryTransactionModel.id
                  ? inventoryTransactionModel
                  : item;
            }).toList();
        state = state.copyWith(items: updatedItems);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Refresh items from repository (explicit reload)
  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListInventoryTransactionModel();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Resource getInventoryTransactionListWithPagination(String page) {
    return _remoteRepository.getInventoryTransactionListWithPagination(page);
  }

  Future<List<InventoryTransactionModel>> syncFromRemote() async {
    List<InventoryTransactionModel> allInventoryTransactions = [];
    int currentPage = 1;

    while (true) {
      InventoryTransactionListResponseModel responseModel = await _webService
          .get(
            _remoteRepository.getInventoryTransactionListWithPagination(
              currentPage.toString(),
            ),
          );

      if (responseModel.isSuccess && responseModel.data != null) {
        allInventoryTransactions.addAll(responseModel.data!);

        // Check if there are more pages
        if (responseModel.data!.length < 100) {
          break; // Last page
        }

        currentPage++;
      } else {
        break;
      }
    }

    return allInventoryTransactions;
  }

  Future<bool> createAndInsertInvTransaction({
    required String invName,
    required int transactionTypeEnum,
    required StaffModel staffModel,
    required OutletModel outletModel,
    required PosDeviceModel posDeviceModel,
    required InventoryModel invModel,
    required double saleItemQty,
    required Function(String errorMessage) onError,
  }) async {
    try {
      String companyId = staffModel.companyId!;

      // get inventoryId by itemId

      // if (invModel == null || invModel.id == null) {
      //   await _localErrorLogRepository.createAndInsertErrorLog(
      //     'Inventory not found - Cannot update inventory transaction',
      //   );
      //   onError('Inventory not found');
      //   return false;
      // } else {
      //   inventoryId = invModel.id!;
      // }

      InventoryTransactionModel invTranModel = InventoryTransactionModel(
        id: IdUtils.generateUUID(),
        inventoryId: invModel.id,
        companyId: companyId,
        outletId: outletModel.id,

        type: transactionTypeEnum,
        reason: getReason(posDeviceModel, transactionTypeEnum),
        // Stock level before the transaction
        quantity: invModel.currentQuantity ?? 0.0,

        // The amount being transacted (sold/returned)
        countedQuantity: saleItemQty,

        // The change in inventory always positive
        differenceQuantity: saleItemQty,

        // Stock level after the transaction is applied
        stockAfter: getStockAfter(invModel, saleItemQty, transactionTypeEnum),

        unitCost: 0,
        totalCost: 0,

        notes: invName,
        name: invName,
        performedById: staffModel.id,
        performedAt: DateTime.now(),
      );
      return upsertBulk([invTranModel]);
    } catch (e) {
      await _localErrorLogRepository.createAndInsertErrorLog(
        'Error createAndInsertInvTransaction: $e',
      );
      return false;
    }
  }

  double getStockAfter(
    InventoryModel invModel,
    double saleItemQty,
    int transactionTypeEnum,
  ) {
    if (transactionTypeEnum == InventoryTransactionTypeEnum.stockOut) {
      return invModel.currentQuantity! - saleItemQty;
    } else if (transactionTypeEnum == InventoryTransactionTypeEnum.stockIn) {
      return invModel.currentQuantity! + saleItemQty;
    } else {
      return invModel.currentQuantity!;
    }
  }

  double getDifferenceQty(double saleItemQty, int transactionTypeEnum) {
    return switch (transactionTypeEnum) {
      InventoryTransactionTypeEnum.stockOut => -saleItemQty,
      InventoryTransactionTypeEnum.stockIn => saleItemQty,
      _ => 0,
    };
  }

  String getReason(PosDeviceModel posDeviceModel, int transactionTypeEnum) {
    if (transactionTypeEnum == InventoryTransactionTypeEnum.stockOut) {
      return 'Stock deduction (NEW ORDER) from POS device ${posDeviceModel.name}';
    } else if (transactionTypeEnum == InventoryTransactionTypeEnum.stockIn) {
      // if the user void order
      return 'Stock addition (VOID ORDER) from POS device ${posDeviceModel.name}';
    } else {
      return 'Adjustment from POS device ${posDeviceModel.name}';
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get inventory transaction list from Hive (synchronous)
  List<InventoryTransactionModel> getListInventoryTransactionFromHive() {
    return _localRepository.getListInventoryTransactionFromHive();
  }

  /// Get inventory transaction list (old notifier getter)
  List<InventoryTransactionModel> get getInventoryTransactionList =>
      state.items;
}

/// Provider for sorted items (computed provider)
final sortedInventoryTransactionsProvider =
    Provider<List<InventoryTransactionModel>>((ref) {
      final items = ref.watch(inventoryTransactionProvider).items;
      final sorted = List<InventoryTransactionModel>.from(items);
      sorted.sort(
        (a, b) => (a.name ?? '').toLowerCase().compareTo(
          (b.name ?? '').toLowerCase(),
        ),
      );
      return sorted;
    });

/// Provider for inventoryTransaction domain
final inventoryTransactionProvider = StateNotifierProvider<
  InventoryTransactionNotifier,
  InventoryTransactionState
>((ref) {
  return InventoryTransactionNotifier(
    localRepository: ServiceLocator.get<LocalInventoryTransactionRepository>(),
    remoteRepository: ServiceLocator.get<InventoryTransactionRepository>(),
    webService: ServiceLocator.get<IWebService>(),
    localErrorLogRepository: ServiceLocator.get<LocalErrorLogRepository>(),
  );
});

/// Provider for inventoryTransaction by ID (family provider for indexed lookups)
final inventoryTransactionByIdProvider =
    Provider.family<InventoryTransactionModel?, String>((ref, id) {
      final items = ref.watch(inventoryTransactionProvider).items;
      try {
        return items.firstWhere((item) => item.id == id);
      } catch (e) {
        return null;
      }
    });

/// Provider for inventory transactions from Hive cache (synchronous)
final inventoryTransactionsFromHiveProvider =
    Provider<List<InventoryTransactionModel>>((ref) {
      final notifier = ref.watch(inventoryTransactionProvider.notifier);
      return notifier.getListInventoryTransactionFromHive();
    });

/// Provider for inventory transaction count (computed provider)
final inventoryTransactionCountProvider = Provider<int>((ref) {
  final items = ref.watch(inventoryTransactionProvider).items;
  return items.length;
});

/// Provider for inventory transactions by inventory ID (computed family provider)
final inventoryTransactionsByInventoryIdProvider =
    Provider.family<List<InventoryTransactionModel>, String>((
      ref,
      inventoryId,
    ) {
      final items = ref.watch(inventoryTransactionProvider).items;
      return items.where((item) => item.inventoryId == inventoryId).toList();
    });

/// Provider for inventory transactions by outlet ID (computed family provider)
final inventoryTransactionsByOutletIdProvider =
    Provider.family<List<InventoryTransactionModel>, String>((ref, outletId) {
      final items = ref.watch(inventoryTransactionProvider).items;
      return items.where((item) => item.outletId == outletId).toList();
    });

/// Provider for inventory transactions by type (computed family provider)
final inventoryTransactionsByTypeProvider =
    Provider.family<List<InventoryTransactionModel>, int>((ref, type) {
      final items = ref.watch(inventoryTransactionProvider).items;
      return items.where((item) => item.type == type).toList();
    });

/// Provider for stock in transactions (computed provider)
final stockInTransactionsProvider = Provider<List<InventoryTransactionModel>>((
  ref,
) {
  final items = ref.watch(inventoryTransactionProvider).items;
  return items
      .where((item) => item.type == InventoryTransactionTypeEnum.stockIn)
      .toList();
});

/// Provider for stock out transactions (computed provider)
final stockOutTransactionsProvider = Provider<List<InventoryTransactionModel>>((
  ref,
) {
  final items = ref.watch(inventoryTransactionProvider).items;
  return items
      .where((item) => item.type == InventoryTransactionTypeEnum.stockOut)
      .toList();
});

/// Provider for adjustment transactions (computed provider)
final adjustmentTransactionsProvider =
    Provider<List<InventoryTransactionModel>>((ref) {
      final items = ref.watch(inventoryTransactionProvider).items;
      return items
          .where(
            (item) => item.type == InventoryTransactionTypeEnum.stockAdjustment,
          )
          .toList();
    });

/// Provider for recent transactions (computed family provider)
final recentTransactionsProvider =
    Provider.family<List<InventoryTransactionModel>, int>((ref, count) {
      final items = ref.watch(inventoryTransactionProvider).items;
      final sorted = List<InventoryTransactionModel>.from(items);
      sorted.sort((a, b) {
        if (a.performedAt == null && b.performedAt == null) return 0;
        if (a.performedAt == null) return 1;
        if (b.performedAt == null) return -1;
        return b.performedAt!.compareTo(a.performedAt!);
      });
      return sorted.take(count).toList();
    });

/// Provider for transactions by date range (computed family provider)
final transactionsByDateRangeProvider = Provider.family<
  List<InventoryTransactionModel>,
  ({DateTime start, DateTime end})
>((ref, dateRange) {
  final items = ref.watch(inventoryTransactionProvider).items;
  return items.where((transaction) {
    if (transaction.performedAt == null) return false;
    return transaction.performedAt!.isAfter(dateRange.start) &&
        transaction.performedAt!.isBefore(dateRange.end);
  }).toList();
});

/// Provider for total quantity by inventory ID (computed family provider)
final totalQuantityByInventoryIdTransactionProvider =
    Provider.family<double, String>((ref, inventoryId) {
      final transactions = ref.watch(
        inventoryTransactionsByInventoryIdProvider(inventoryId),
      );
      return transactions.fold(
        0.0,
        (sum, transaction) => sum + (transaction.differenceQuantity ?? 0),
      );
    });
