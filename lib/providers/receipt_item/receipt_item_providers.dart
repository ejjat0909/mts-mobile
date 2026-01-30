import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/data/models/receipt_item/receipt_item_list_response_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/domain/repositories/local/receipt_item_repository.dart';
import 'package:mts/domain/repositories/remote/receipt_item_repository.dart';
import 'package:mts/providers/receipt_item/receipt_item_state.dart';

/// StateNotifier for ReceiptItem domain
///
/// Migrated from: receipt_item_facade_impl.dart
///
class ReceiptItemNotifier extends StateNotifier<ReceiptItemState> {
  final LocalReceiptItemRepository _localRepository;
  final ReceiptItemRepository _remoteRepository;
  final IWebService _webService;

  ReceiptItemNotifier({
    required LocalReceiptItemRepository localRepository,
    required ReceiptItemRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const ReceiptItemState());

  // ============================================================
  // Business logic migrated from receipt_item_facade_impl.dart
  // ============================================================

  /// Insert a single receipt item into local storage
  Future<int> insert(ReceiptItemModel model) async {
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

  /// Update a single receipt item in local storage
  Future<int> update(ReceiptItemModel model) async {
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
    List<ReceiptItemModel> list, {
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
  Future<List<ReceiptItemModel>> getListReceiptItems() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListReceiptItems();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Get receipt items by receipt ID
  Future<List<ReceiptItemModel>> getListReceiptItemsByReceiptId(
    String receiptId,
  ) async {
    try {
      return await _localRepository.getListReceiptItemsByReceiptId(receiptId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get receipt items that are not refunded
  Future<List<ReceiptItemModel>> getListReceiptItemsNotRefunded() async {
    try {
      return await _localRepository.getListReceiptItemsNotRefunded();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get receipt items that are refunded
  Future<List<ReceiptItemModel>> getListReceiptItemsIsRefunded() async {
    try {
      return await _localRepository.getListReceiptItemsIsRefunded();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get count of receipt items
  Future<int> getCountListReceiptItems() async {
    try {
      return await _localRepository.getCountListReceiptItems();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return 0;
    }
  }

  /// Calculate total quantity not refunded sold by item
  Future<String> calcTotalQuantityNotRefundedSoldByItem() async {
    try {
      return await _localRepository.calcTotalQuantityNotRefundedSoldByItem();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return '0';
    }
  }

  /// Calculate total quantity not refunded sold by measurement
  Future<String> calcTotalQuantityNotRefundedSoldByMeasurement() async {
    try {
      return await _localRepository
          .calcTotalQuantityNotRefundedSoldByMeasurement();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return '0';
    }
  }

  /// Calculate total quantity that is refunded
  Future<String> calcTotalQuantityIsRefunded() async {
    try {
      return await _localRepository.calcTotalQuantityIsRefunded();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return '0';
    }
  }

  /// Calculate tax included after discount by receipt ID
  Future<double> calcTaxIncludedAfterDiscountByReceiptId(
    String receiptId,
  ) async {
    try {
      return await _localRepository.calcTaxIncludedAfterDiscountByReceiptId(
        receiptId,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return 0.0;
    }
  }

  /// Get all receipt items from API with pagination
  Future<List<ReceiptItemModel>> syncFromRemote() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      List<ReceiptItemModel> allReceiptItems = [];
      int currentPage = 1;
      int? lastPage;

      do {
        ReceiptItemListResponseModel responseModel = await _webService.get(
          _remoteRepository.getReceiptItemWithPagination(
            currentPage.toString(),
          ),
        );

        if (responseModel.isSuccess && responseModel.data != null) {
          await insertBulk(responseModel.data!, isInsertToPending: false);
          allReceiptItems.addAll(responseModel.data!);

          if (responseModel.paginator != null) {
            lastPage = responseModel.paginator!.lastPage;
          } else {
            break;
          }

          currentPage++;
        } else {
          break;
        }
      } while (lastPage != null && currentPage <= lastPage);

      state = state.copyWith(isLoading: false);
      return allReceiptItems;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Get all taxes with amounts by receipt ID
  /// Returns map with key format: 'taxName|taxRate|taxType' and value: calculated amount
  Future<Map<String, double>> getAllTaxesWithAmountsByReceiptId(
    String receiptId,
  ) async {
    try {
      final receiptItems = await getListReceiptItemsByReceiptId(receiptId);
      Map<String, double> taxAmountsMap = {};

      for (ReceiptItemModel item in receiptItems) {
        if (item.taxes == null ||
            item.taxes!.isEmpty ||
            item.price == null ||
            item.quantity == null) {
          continue;
        }

        List<TaxModel> taxes = _decodeTaxList(item.taxes!);

        for (TaxModel tax in taxes) {
          if (tax.name != null && tax.rate != null) {
            String taxKey =
                '\${tax.name}|\${tax.rate}|\${tax.type ?? '
                '}';
            double priceAfterDiscount = item.price! - (item.totalDiscount ?? 0);
            double taxAmount = priceAfterDiscount * (tax.rate! / 100);

            if (taxAmountsMap.containsKey(taxKey)) {
              taxAmountsMap[taxKey] = taxAmountsMap[taxKey]! + taxAmount;
            } else {
              taxAmountsMap[taxKey] = taxAmount;
            }
          }
        }
      }

      return taxAmountsMap;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return {};
    }
  }

  /// Helper method to decode tax list from JSON string
  List<TaxModel> _decodeTaxList(String jsonString) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => TaxModel.fromJson(json)).toList();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<ReceiptItemModel> list) async {
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
  Future<ReceiptItemModel?> getReceiptItemById(String itemId) async {
    try {
      return await _localRepository.getReceiptItemById(itemId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<ReceiptItemModel> newData, {
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
    List<ReceiptItemModel> list, {
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
      final items = await _localRepository.getListReceiptItems();

      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider for sorted items (computed provider)
final sortedReceiptItemsProvider = Provider<List<ReceiptItemModel>>((ref) {
  final items = ref.watch(receiptItemProvider).items;
  final sorted = List<ReceiptItemModel>.from(items);
  sorted.sort((a, b) {
    if (a.createdAt == null && b.createdAt == null) return 0;
    if (a.createdAt == null) return 1;
    if (b.createdAt == null) return -1;
    return b.createdAt!.compareTo(a.createdAt!);
  });
  return sorted;
});

/// Provider for receiptItem domain
final receiptItemProvider =
    StateNotifierProvider<ReceiptItemNotifier, ReceiptItemState>((ref) {
      return ReceiptItemNotifier(
        localRepository: ServiceLocator.get<LocalReceiptItemRepository>(),
        remoteRepository: ServiceLocator.get<ReceiptItemRepository>(),
        webService: ServiceLocator.get<IWebService>(),
      );
    });

/// Provider for receiptItem by ID (family provider for indexed lookups)
final receiptItemByIdProvider =
    FutureProvider.family<ReceiptItemModel?, String>((ref, id) async {
      final notifier = ref.watch(receiptItemProvider.notifier);
      return notifier.getReceiptItemById(id);
    });
