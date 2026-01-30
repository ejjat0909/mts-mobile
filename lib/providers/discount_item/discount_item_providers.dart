import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/discount/discount_model.dart';
import 'package:mts/data/models/discount_item/discount_item_list_response_model.dart';
import 'package:mts/data/models/discount_item/discount_item_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/domain/repositories/local/discount_item_repository.dart';
import 'package:mts/domain/repositories/remote/discount_item_repository.dart';
import 'package:mts/providers/discount/discount_providers.dart';
import 'package:mts/providers/discount_item/discount_item_state.dart';
import 'package:mts/providers/item/item_providers.dart';

/// StateNotifier for DiscountItem domain
///
/// Migrated from: discount_item_facade_impl.dart
class DiscountItemNotifier extends StateNotifier<DiscountItemState> {
  final LocalDiscountItemRepository _localRepository;
  final DiscountItemRepository _remoteRepository;
  final IWebService _webService;
  final Ref _ref;

  DiscountItemNotifier({
    required LocalDiscountItemRepository localRepository,
    required DiscountItemRepository remoteRepository,
    required IWebService webService,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _ref = ref,
       super(const DiscountItemState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<DiscountItemModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<DiscountItemModel>.from(state.items);
        for (final newItem in list) {
          final index = currentItems.indexWhere(
            (item) =>
                item.itemId == newItem.itemId &&
                item.discountId == newItem.discountId,
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
  Future<List<DiscountItemModel>> getListDiscountItem() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListDiscountItem();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<DiscountItemModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        final keysToRemove =
            list.map((item) => '${item.itemId}_${item.discountId}').toSet();
        final updatedItems =
            state.items
                .where(
                  (item) =>
                      !keysToRemove.contains(
                        '${item.itemId}_${item.discountId}',
                      ),
                )
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

  /// Delete a pivot record
  Future<int> deletePivot(
    DiscountItemModel discountItemModel, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deletePivot(
        discountItemModel,
        isInsertToPending,
      );

      if (result > 0) {
        final updatedItems =
            state.items
                .where(
                  (item) =>
                      !(item.itemId == discountItemModel.itemId &&
                          item.discountId == discountItemModel.discountId),
                )
                .toList();
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

  /// Find an item by its composite key (itemId + discountId)
  Future<DiscountItemModel?> getDiscountItemByKey(
    String itemId,
    String discountId,
  ) async {
    try {
      // First check current state
      final cachedItem =
          state.items
              .where(
                (item) =>
                    item.itemId == itemId && item.discountId == discountId,
              )
              .firstOrNull;
      if (cachedItem != null) return cachedItem;

      // Fall back to repository
      final items = await _localRepository.getListDiscountItem();
      return items
          .where(
            (item) => item.itemId == itemId && item.discountId == discountId,
          )
          .firstOrNull;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<DiscountItemModel> newData, {
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
    List<DiscountItemModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<DiscountItemModel>.from(state.items);
        for (final newItem in list) {
          final index = currentItems.indexWhere(
            (item) =>
                item.itemId == newItem.itemId &&
                item.discountId == newItem.discountId,
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
      final items = await _localRepository.getListDiscountItem();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<List<DiscountItemModel>> generateSeedDiscountItem() async {
    List<DiscountItemModel> discountItems = [];
    final itemNotifier = _ref.read(itemProvider.notifier);
    final discountNotifier = _ref.read(discountProvider.notifier);
    final listItems = await itemNotifier.getListItemModel();
    final listDiscount = await discountNotifier.getListDiscountModel();

    for (ItemModel itemModel in listItems) {
      for (DiscountModel discountModel in listDiscount) {
        discountItems.add(
          DiscountItemModel(
            itemId: itemModel.id.toString(),
            discountId: discountModel.id.toString(),
          ),
        );
      }
    }

    return discountItems;
  }

  Resource getRemoteDiscountItemList(String page) {
    return _remoteRepository.getDiscountItemList(page);
  }

  Future<List<DiscountItemModel>> syncFromRemote() async {
    List<DiscountItemModel> allDiscountItems = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching discount items page $currentPage');
      DiscountItemListResponseModel responseModel = await _webService.get(
        getRemoteDiscountItemList(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Add items from current page to the list
        allDiscountItems.addAll(responseModel.data!);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination DISCOUNT ITEM: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch discount items page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allDiscountItems.length} discount items from all pages',
    );
    return allDiscountItems;
  }

  Future<int> deleteByColumnName(
    String columnName,
    dynamic value, {
    bool isInsertToPending = true,
  }) async {
    return await _localRepository.deleteByColumnName(
      columnName,
      value,
      isInsertToPending,
    );
  }

  /// Get the current discount item list from state (synchronous)
  List<DiscountItemModel> getDiscountItemList() {
    return state.items;
  }

  /// Set the entire list of discount items in state
  void setListDiscountItem(List<DiscountItemModel> list) {
    state = state.copyWith(items: list);
  }

  /// Add or update a list of discount items in state
  void addOrUpdateList(List<DiscountItemModel> list) {
    final currentItems = List<DiscountItemModel>.from(state.items);

    for (final discountItem in list) {
      final index = currentItems.indexWhere(
        (element) =>
            element.itemId == discountItem.itemId &&
            element.discountId == discountItem.discountId,
      );

      if (index != -1) {
        // If found, replace existing item with the new one
        currentItems[index] = discountItem;
      } else {
        // Not found, add new item
        currentItems.add(discountItem);
      }
    }

    state = state.copyWith(items: currentItems);
  }

  /// Add or update a single discount item in state
  void addOrUpdate(DiscountItemModel discountItem) {
    final currentItems = List<DiscountItemModel>.from(state.items);

    final index = currentItems.indexWhere(
      (d) =>
          d.itemId == discountItem.itemId &&
          d.discountId == discountItem.discountId,
    );

    if (index != -1) {
      // If found, replace existing item with the new one
      currentItems[index] = discountItem;
    } else {
      // Not found, add new item
      currentItems.add(discountItem);
    }

    state = state.copyWith(items: currentItems);
  }

  /// Remove a discount item from state by itemId and discountId
  void remove(String itemId, String discountId) {
    final updatedItems =
        state.items
            .where(
              (discountItem) =>
                  !(discountItem.itemId == itemId &&
                      discountItem.discountId == discountId),
            )
            .toList();

    state = state.copyWith(items: updatedItems);
  }

  /// Returns a list of valid discount models for a specific item ID
  ///
  /// [itemId] The ID of the item to filter discounts for
  /// [listReceiveDiscountModel] List of available discount models
  /// [itemModel] The item model to check discounts for
  /// [discountModel] The discount model to validate
  ///
  /// Returns a list of [DiscountModel] objects that match the provided item ID
  /// and are valid based on their date ranges
  List<DiscountModel> getValidDiscountModelsByItemId(
    List<DiscountModel> listReceiveDiscountModel,
    ItemModel itemModel,
    DiscountModel discountModel,
  ) {
    final itemId = itemModel.id;
    if (itemId == null || itemId.isEmpty) {
      return []; // Return an empty list if itemId is invalid or empty
    }

    final now = DateTime.now();

    // Get all discount-item relations for this itemId
    final discountIds =
        state.items
            .where(
              (di) => di.itemId == itemId && di.discountId == discountModel.id,
            )
            .map((di) => di.discountId)
            .toList();

    // Filter discounts based on ID and valid date range
    return listReceiveDiscountModel.where((discount) {
      final isLinked = discountIds.contains(discount.id);
      final isValidFrom =
          discount.validFrom == null ||
          discount.validFrom!.isBefore(now) ||
          discount.validFrom!.isAtSameMomentAs(now);
      final isValidTo =
          discount.validTo == null ||
          discount.validTo!.isAfter(now) ||
          discount.validTo!.isAtSameMomentAs(now);
      return isLinked && isValidFrom && isValidTo;
    }).toList();
  }
}

/// Provider for discountItem domain
final discountItemProvider =
    StateNotifierProvider<DiscountItemNotifier, DiscountItemState>((ref) {
      return DiscountItemNotifier(
        localRepository: ServiceLocator.get<LocalDiscountItemRepository>(),
        remoteRepository: ServiceLocator.get<DiscountItemRepository>(),
        webService: ServiceLocator.get<IWebService>(),
        ref: ref,
      );
    });

/// Provider for sorted items (computed provider - sorted by discountId then itemId)
final sortedDiscountItemsProvider = Provider<List<DiscountItemModel>>((ref) {
  final items = ref.watch(discountItemProvider).items;
  final sorted = List<DiscountItemModel>.from(items);
  sorted.sort((a, b) {
    final discountCompare = (a.discountId ?? '').compareTo(b.discountId ?? '');
    if (discountCompare != 0) return discountCompare;
    return (a.itemId ?? '').compareTo(b.itemId ?? '');
  });
  return sorted;
});

/// Provider for discountItem by composite key (family provider)
final discountItemByKeyProvider = FutureProvider.family<
  DiscountItemModel?,
  ({String itemId, String discountId})
>((ref, key) async {
  final notifier = ref.watch(discountItemProvider.notifier);
  return notifier.getDiscountItemByKey(key.itemId, key.discountId);
});

/// Provider for discount items by item ID (computed provider)
final discountItemsByItemIdProvider =
    Provider.family<List<DiscountItemModel>, String>((ref, itemId) {
      final items = ref.watch(discountItemProvider).items;
      return items.where((item) => item.itemId == itemId).toList();
    });

/// Provider for discount items by discount ID (computed provider)
final discountItemsByDiscountIdProvider =
    Provider.family<List<DiscountItemModel>, String>((ref, discountId) {
      final items = ref.watch(discountItemProvider).items;
      return items.where((item) => item.discountId == discountId).toList();
    });

/// Provider for checking if a discount item exists (computed provider)
final discountItemExistsProvider =
    Provider.family<bool, ({String itemId, String discountId})>((ref, key) {
      final items = ref.watch(discountItemProvider).items;
      return items.any(
        (item) =>
            item.itemId == key.itemId && item.discountId == key.discountId,
      );
    });
