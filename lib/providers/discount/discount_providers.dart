import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/enum/discount_type_enum.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/discount/discount_list_response_model.dart';
import 'package:mts/data/models/discount/discount_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/domain/repositories/local/discount_repository.dart';
import 'package:mts/domain/repositories/remote/discount_repository.dart';
import 'package:mts/providers/discount/discount_state.dart';

/// StateNotifier for Discount domain
///
/// Migrated from: discount_facade_impl.dart
class DiscountNotifier extends StateNotifier<DiscountState> {
  final LocalDiscountRepository _localRepository;
  final DiscountRepository _remoteRepository;
  final IWebService _webService;

  DiscountNotifier({
    required LocalDiscountRepository localRepository,
    required DiscountRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const DiscountState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<DiscountModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<DiscountModel>.from(state.items);
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
  Future<List<DiscountModel>> getListDiscountModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListDiscountModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<DiscountModel> list) async {
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
  Future<DiscountModel?> getDiscountModelById(String itemId) async {
    try {
      // First check current state
      final cachedItem =
          state.items.where((item) => item.id == itemId).firstOrNull;
      if (cachedItem != null) return cachedItem;

      // Fall back to repository
      final items = await _localRepository.getListDiscountModel();
      return items.where((item) => item.id == itemId).firstOrNull;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<DiscountModel> newData, {
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
    List<DiscountModel> list, {
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
        final currentItems = List<DiscountModel>.from(state.items);
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
      final items = await _localRepository.getListDiscountModel();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ============================================================
  // UI State Management Methods (from old DiscountNotifier)
  // ============================================================

  /// Get discount list (getter for compatibility)
  List<DiscountModel> get getDiscountList => state.items;

  /// Set the entire discount list
  void setListDiscount(List<DiscountModel> list) {
    state = state.copyWith(items: list);
  }

  /// Add or update multiple discounts in the list
  void addOrUpdateList(List<DiscountModel> list) {
    final currentItems = List<DiscountModel>.from(state.items);

    for (DiscountModel discount in list) {
      int index = currentItems.indexWhere(
        (element) => element.id == discount.id,
      );

      if (index != -1) {
        currentItems[index] = discount;
      } else {
        currentItems.add(discount);
      }
    }

    state = state.copyWith(items: currentItems);
  }

  /// Add or update a single discount
  void addOrUpdate(DiscountModel discount) {
    final currentItems = List<DiscountModel>.from(state.items);
    int index = currentItems.indexWhere((d) => d.id == discount.id);

    if (index != -1) {
      currentItems[index] = discount;
    } else {
      currentItems.add(discount);
    }

    state = state.copyWith(items: currentItems);
  }

  /// Remove a discount by ID
  void remove(String id) {
    final currentItems = List<DiscountModel>.from(state.items);
    currentItems.removeWhere((discount) => discount.id == id);
    state = state.copyWith(items: currentItems);
  }

  bool isNowWithinRange(DateTime? validFrom, DateTime? validTo) {
    if (validFrom != null && validTo != null) {
      DateTime now = DateTime.now();
      return now.isAfter(validFrom) && now.isBefore(validTo);
    }
    return false;
  }

  List<DiscountModel> listDiscountWithinRange(
    List<DiscountModel> listDiscount,
    DateTime? validFrom,
    DateTime? validTo,
  ) {
    return listDiscount
        .where(
          (discount) => isNowWithinRange(discount.validFrom, discount.validTo),
        )
        .toList();
  }

  double getTotalDiscountPercentage(List<DiscountModel> listDiscount) {
    return listDiscount
        .where(
          (discount) =>
              isNowWithinRange(discount.validFrom, discount.validTo) &&
              discount.type == DiscountTypeEnum.percentage,
        )
        .fold(0.0, (total, discount) {
          total += discount.value!;
          return total;
        });
  }

  double getTotalDiscountAmount(List<DiscountModel> listDiscount) {
    return listDiscount
        .where(
          (discount) =>
              isNowWithinRange(discount.validFrom, discount.validTo) &&
              discount.type == DiscountTypeEnum.amount,
        )
        .fold(0.0, (total, discount) {
          total += discount.value!;
          return total;
        });
  }

  double getTotalDiscountPercentageBasedOnThatSaleItem(
    List<DiscountModel> listDiscount,
    double saleItemPrice,
  ) {
    // ex: saleItemPrice = 100
    // ex: totalDiscountPercentage = 10

    return saleItemPrice * getTotalDiscountPercentage(listDiscount) / 100;
  }

  double getGrandTotalDiscountAmountBasedOnSaleItems(
    List<DiscountModel> listDiscount,
    double subTotalPrice,
  ) {
    double totalGrandDiscount =
        getTotalDiscountAmount(listDiscount) +
        getTotalDiscountPercentageBasedOnThatSaleItem(
          listDiscount,
          subTotalPrice,
        );
    return totalGrandDiscount;
  }

  Resource getDiscountListPaginated(String page) {
    return _remoteRepository.getDiscountListPaginated(page);
  }

  Future<List<DiscountModel>> syncFromRemote() async {
    List<DiscountModel> allDiscounts = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching discounts page $currentPage');
      DiscountListResponseModel responseModel = await _webService.get(
        getDiscountListPaginated(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Add discounts from current page to the list
        allDiscounts.addAll(responseModel.data!);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination DISCOUNT: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch discounts page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allDiscounts.length} discounts from all pages',
    );
    return allDiscounts;
  }

  List<DiscountModel> ensureUniqueDiscountList(
    List<DiscountModel> listDiscounts,
  ) {
    Set<String> seenIds = {}; // Set to track unique ids
    List<DiscountModel> uniqueList = [];

    for (DiscountModel discount in listDiscounts) {
      if (!seenIds.contains(discount.id)) {
        seenIds.add(discount.id!); // Add the id to the set
        uniqueList.add(discount); // Add the discount to the unique list
      }
    }

    return uniqueList;
  }

  Future<List<DiscountModel>> getDiscountModelByItemId(String itemID) async {
    return await _localRepository.getDiscountModelByItemId(itemID);
  }

  List<DiscountModel> getAllDiscountModelsForThatItem(
    ItemModel itemModel,
    List<DiscountModel> listDiscounts, {
    required List<DiscountModel> originDiscountList,
    required List<dynamic> discountOutletList,
    required List<dynamic> discountItemList,
    required List<dynamic> categoryDiscountList,
  }) {
    // Business logic: Find all discounts applicable to this item
    // based on outlet, item, and category associations

    List<DiscountModel> resultDiscounts = [];

    // Get the current outlet ID from ServiceLocator
    final OutletModel currentOutlet = ServiceLocator.get<OutletModel>();
    final String? currentOutletId = currentOutlet.id;

    // 1. Get discount IDs associated with the current outlet
    List<String> discountIdsByOutlet =
        discountOutletList
            .where((element) => element.outletId == currentOutletId)
            .map((element) => element.discountId as String)
            .toList();

    // 2. Get discount IDs associated with this item
    List<String> discountIdsByItem =
        discountItemList
            .where((element) => element.itemId == itemModel.id)
            .map((element) => element.discountId as String)
            .toList();

    // 3. Get discount IDs associated with this item's category
    List<String> discountIdsByCategory =
        categoryDiscountList
            .where((element) => element.categoryId == itemModel.categoryId)
            .map((element) => element.discountId as String)
            .toList();

    // 4. Combine all discount IDs (remove duplicates)
    Set<String> allApplicableDiscountIds = {
      ...discountIdsByOutlet,
      ...discountIdsByItem,
      ...discountIdsByCategory,
    };

    // 5. Filter origin discount list to get only applicable discounts
    resultDiscounts =
        originDiscountList
            .where((discount) => allApplicableDiscountIds.contains(discount.id))
            .toList();

    return resultDiscounts;
  }

  List<DiscountModel> decodeDiscountList(String jsonString) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => DiscountModel.fromJson(json)).toList();
    } catch (e) {
      prints('Error decoding discount list: $e');
      return [];
    }
  }
}

/// Provider for discount domain
final discountProvider = StateNotifierProvider<DiscountNotifier, DiscountState>(
  (ref) {
    return DiscountNotifier(
      localRepository: ServiceLocator.get<LocalDiscountRepository>(),
      remoteRepository: ServiceLocator.get<DiscountRepository>(),
      webService: ServiceLocator.get<IWebService>(),
    );
  },
);

/// Provider for sorted items (computed provider)
final sortedDiscountsProvider = Provider<List<DiscountModel>>((ref) {
  final items = ref.watch(discountProvider).items;
  final sorted = List<DiscountModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for discount by ID (family provider for indexed lookups)
final discountByIdProvider = FutureProvider.family<DiscountModel?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(discountProvider.notifier);
  return notifier.getDiscountModelById(id);
});

/// Provider for discounts within valid date range (computed provider)
final validDiscountsProvider = Provider<List<DiscountModel>>((ref) {
  final items = ref.watch(discountProvider).items;
  final notifier = ref.read(discountProvider.notifier);
  return items
      .where(
        (discount) =>
            notifier.isNowWithinRange(discount.validFrom, discount.validTo),
      )
      .toList();
});

/// Provider for percentage discounts within valid range (computed provider)
final validPercentageDiscountsProvider = Provider<List<DiscountModel>>((ref) {
  final items = ref.watch(discountProvider).items;
  final notifier = ref.read(discountProvider.notifier);
  return items
      .where(
        (discount) =>
            notifier.isNowWithinRange(discount.validFrom, discount.validTo) &&
            discount.type == DiscountTypeEnum.percentage,
      )
      .toList();
});

/// Provider for amount discounts within valid range (computed provider)
final validAmountDiscountsProvider = Provider<List<DiscountModel>>((ref) {
  final items = ref.watch(discountProvider).items;
  final notifier = ref.read(discountProvider.notifier);
  return items
      .where(
        (discount) =>
            notifier.isNowWithinRange(discount.validFrom, discount.validTo) &&
            discount.type == DiscountTypeEnum.amount,
      )
      .toList();
});

/// Provider for total discount percentage (computed provider)
final totalDiscountPercentageProvider = Provider<double>((ref) {
  final validPercentageDiscounts = ref.watch(validPercentageDiscountsProvider);
  return validPercentageDiscounts.fold(
    0.0,
    (total, discount) => total + (discount.value ?? 0.0),
  );
});

/// Provider for total discount amount (computed provider)
final totalDiscountAmountProvider = Provider<double>((ref) {
  final validAmountDiscounts = ref.watch(validAmountDiscountsProvider);
  return validAmountDiscounts.fold(
    0.0,
    (total, discount) => total + (discount.value ?? 0.0),
  );
});

/// Provider for discounts by item ID (family provider)
final discountsByItemIdProvider =
    FutureProvider.family<List<DiscountModel>, String>((ref, itemId) async {
      final notifier = ref.watch(discountProvider.notifier);
      return notifier.getDiscountModelByItemId(itemId);
    });

/// Provider for checking if a discount exists by ID (synchronous)
final discountExistsByIdProvider = Provider.family<bool, String>((ref, id) {
  final items = ref.watch(discountProvider).items;
  return items.any((item) => item.id == id);
});
