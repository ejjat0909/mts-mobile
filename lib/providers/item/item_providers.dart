import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/item_representation/item_representation_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';
import 'package:mts/domain/repositories/local/item_repository.dart';
import 'package:mts/presentation/features/sales/components/menu_item.dart';
import 'package:mts/providers/item/item_state.dart';
import 'package:mts/providers/item_representation/item_representation_providers.dart';
import 'package:mts/providers/modifier_option/modifier_option_providers.dart';
import 'package:mts/core/enum/polymorphic_enum.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/item/item_list_response_model.dart';
import 'package:mts/data/models/page_item/page_item_model.dart';
import 'package:mts/domain/repositories/remote/item_repository.dart';

/// StateNotifier for Item domain
///
/// Migrated from: item_facade_impl.dart
class ItemNotifier extends StateNotifier<ItemState> {
  final LocalItemRepository _localRepository;
  final ItemRepository _remoteRepository;
  final IWebService _webService;
  final Ref _ref;

  ItemNotifier({
    required LocalItemRepository localRepository,
    required ItemRepository remoteRepository,
    required IWebService webService,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _ref = ref,
       super(const ItemState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<ItemModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<ItemModel>.from(state.items);
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
  Future<List<ItemModel>> getListItemModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListItemModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<ItemModel> list) async {
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
  Future<ItemModel?> getItemModelById(String itemId) async {
    try {
      final items = await _localRepository.getListItemModel();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => ItemModel(),
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
    List<ItemModel> newData, {
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
    List<ItemModel> list, {
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
        final existingItems = List<ItemModel>.from(state.items);
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

  /// Refresh items from repository (explicit reload)
  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListItemModel();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Get items filtered by category ID
  List<ItemModel> getItemsWithCategoryId(String categoryId) {
    return state.items.where((item) => item.categoryId == categoryId).toList();
  }

  /// Get multiple items by their IDs (async version - from facade)
  /// Note: Old notifier had sync version, kept below for compatibility
  // Future<List<ItemModel>> getItemModelsByIds(List<String> itemIds) async {
  //   try {
  //     return await _localRepository.getItemModelsByIds(itemIds);
  //   } catch (e) {
  //     state = state.copyWith(error: e.toString());
  //     return [];
  //   }
  // }

  /// Get variant option JSON by item ID
  Future<String?> getVariantOptionJsonByItemId(String idItem) async {
    try {
      return await _localRepository.getVariantOptionJsonByItemId(idItem);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get list items (old notifier getter)
  List<ItemModel> get getListItems => state.items;

  /// Get item name (old notifier getter)
  String get getItemName => state.itemName;

  /// Get search item name (old notifier getter)
  String get getSearchItemName => state.searchItemName;

  /// Get list item representations (old notifier getter)
  List<ItemRepresentationModel> get getListItemRepresentations {
    final itemRepresentationNotifier = _ref.read(
      itemRepresentationProvider.notifier,
    );
    return itemRepresentationNotifier.getListItemRepresentationFromHive();
  }

  /// Get dialogue navigation (old notifier getter)
  String get getDialogueNavigation => state.dialogueNavigation;

  /// Get temp variant option model (old notifier getter)
  VariantOptionModel? get getTempVariantOptionModel =>
      state.tempVariantOptionModel;

  /// Get list variant options (old notifier getter)
  List<VariantOptionModel> get getListVariantOptions =>
      state.listVariantOptions;

  /// Get temp price (old notifier getter)
  String? get getTempPrice => state.tempPrice;

  /// Get previous price (old notifier getter)
  String? get getPreviousPrice => state.previousPrice;

  /// Get selected price (old notifier getter)
  String? get getSelectedPrice => state.selectedPrice;

  /// Get temp qty (old notifier getter)
  String? get getTempQty => state.tempQty;

  /// Get previous qty (old notifier getter)
  String? get getPreviousQty => state.previousQty;

  /// Get selected qty (old notifier getter)
  String? get getSelectedQty => state.selectedQty;

  /// Set selected price (old notifier method)
  void setSelectedPrice(String? price, {bool isRefresh = true}) {
    state = state.copyWith(selectedPrice: price);
  }

  /// Get item by ID (old notifier method)
  ItemModel getItemById(String id) {
    return state.items.firstWhere(
      (item) => item.id == id,
      orElse: () => ItemModel(),
    );
  }

  /// Get items with category (old notifier method)
  List<ItemModel> getItemWithCategory(String categoryId) {
    return state.items.where((item) => item.categoryId == categoryId).toList();
  }

  /// Get item models by IDs (old notifier method)
  List<ItemModel> getItemModelsByIds(List<String> ids) {
    return state.items.where((item) => ids.contains(item.id)).toList();
  }

  /// Get item models by name (old notifier method)
  List<ItemModel> getItemModelsByName() {
    if (state.itemName.trim().isEmpty) {
      return getListItemsThatDoesNotHaveCategoryAndHaveCategory();
    }

    return state.items.where((item) {
      final query = state.itemName.toLowerCase();
      return (item.name?.toLowerCase().contains(query) ?? false) ||
          (item.barcode?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  /// Set item name (old notifier method)
  void setItemName(String name) {
    state = state.copyWith(itemName: name);
  }

  /// Set search item name (old notifier method)
  void setSearchItemName(String name) {
    state = state.copyWith(searchItemName: name);
  }

  /// Get filtered item list (old notifier method)
  List<ItemModel> getFilteredItemList(String categoryId) {
    final listItemWithCategoryId = getItemWithCategory(categoryId);
    if (state.itemName.trim().isEmpty) {
      return listItemWithCategoryId;
    }

    return listItemWithCategoryId.where((item) {
      final query = state.itemName.toLowerCase();
      return (item.name?.toLowerCase().contains(query) ?? false) ||
          (item.barcode?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  /// Initialize for second screen (old notifier method)
  void initializeForSecondScreen(List<ItemModel> items) {
    final listMoFromNotifier =
        _ref.read(modifierOptionProvider.notifier).getModifierOptionList;
    MenuItem.reInitializeCache(state.items, listMoFromNotifier);
  }

  /// Get list variant option by item ID (old notifier method)
  List<VariantOptionModel> getListVariantOptionByItemId(String itemId) {
    List<dynamic> listVariantOptions = [];
    ItemModel item = getItemById(itemId);
    String? variantOptionJson = item.variantOptionJson;

    listVariantOptions =
        variantOptionJson == null
            ? []
            : jsonDecode(variantOptionJson.isEmpty ? '[]' : variantOptionJson);

    List<VariantOptionModel> variantOptionList =
        listVariantOptions.map((item) {
          return VariantOptionModel.fromJson(item);
        }).toList();

    return variantOptionList;
  }

  /// Get item model by ID for transfer (old notifier method)
  ItemModel? getItemModelByIdForTransfer(String id, List<ItemModel> items) {
    final matches = items.where((item) => item.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  /// Get variant option model by ID (old notifier method)
  VariantOptionModel? getVariantOptionModelById(
    String? varOptId,
    String? itemId,
  ) {
    if (varOptId == null) return null;

    if (itemId != null) {
      ItemModel? item = getItemById(itemId);
      if (item.id != null &&
          item.variantOptionJson != null &&
          item.variantOptionJson!.isNotEmpty) {
        try {
          List<dynamic> variantOptions = jsonDecode(item.variantOptionJson!);
          for (var variantOption in variantOptions) {
            if (variantOption['id'] == varOptId) {
              return VariantOptionModel.fromJson(variantOption);
            }
          }
        } catch (e) {
          prints('Error parsing variant option JSON: $e');
        }
      }
      return null;
    }

    for (ItemModel item in state.items) {
      if (item.variantOptionJson != null &&
          item.variantOptionJson!.isNotEmpty) {
        try {
          List<dynamic> variantOptions = jsonDecode(item.variantOptionJson!);
          for (var variantOption in variantOptions) {
            if (variantOption['id'] == varOptId) {
              return VariantOptionModel.fromJson(variantOption);
            }
          }
        } catch (e) {
          prints('Error parsing variant option JSON: $e');
        }
      }
    }
    return null;
  }

  /// Get variant option model by ID for transfer (old notifier method)
  VariantOptionModel? getVariantOptionModelByIdForTransfer(
    String? varOptId,
    String? itemId,
    List<ItemModel> listItems,
  ) {
    if (varOptId == null) return null;

    if (itemId != null) {
      ItemModel? item = getItemModelByIdForTransfer(itemId, listItems);
      if (item != null &&
          item.variantOptionJson != null &&
          item.variantOptionJson!.isNotEmpty) {
        try {
          List<dynamic> variantOptions = jsonDecode(item.variantOptionJson!);
          for (var variantOption in variantOptions) {
            if (variantOption['id'] == varOptId) {
              return VariantOptionModel.fromJson(variantOption);
            }
          }
        } catch (e) {
          prints('Error parsing variant option JSON: $e');
        }
      }
      return null;
    }

    for (ItemModel item in listItems) {
      if (item.variantOptionJson != null &&
          item.variantOptionJson!.isNotEmpty) {
        try {
          List<dynamic> variantOptions = jsonDecode(item.variantOptionJson!);
          for (var variantOption in variantOptions) {
            if (variantOption['id'] == varOptId) {
              return VariantOptionModel.fromJson(variantOption);
            }
          }
        } catch (e) {
          prints('Error parsing variant option JSON: $e');
        }
      }
    }
    return null;
  }

  /// Set temp price (old notifier method)
  void setTempPrice(String? price) {
    state = state.copyWith(tempPrice: price, selectedPrice: price);
  }

  /// Apply previous price (old notifier method)
  void applyPreviousPrice() {
    state = state.copyWith(
      previousPrice: state.tempPrice,
      selectedPrice: state.tempPrice,
    );
  }

  /// Reset previous price (old notifier method)
  void resetPreviousPrice() {
    state = state.copyWith(tempPrice: state.previousPrice);
  }

  /// Set selected qty (old notifier method)
  void setSelectedQty(String? qty, {bool isRefresh = true}) {
    state = state.copyWith(selectedQty: qty);
  }

  /// Set temp qty (old notifier method)
  void setTempQty(String? qty) {
    state = state.copyWith(tempQty: qty, selectedQty: qty);
  }

  /// Apply previous qty (old notifier method)
  void applyPreviousQty() {
    state = state.copyWith(
      previousQty: state.tempQty,
      selectedQty: state.tempQty,
    );
  }

  /// Reset previous qty (old notifier method)
  void resetPreviousQty() {
    state = state.copyWith(tempQty: state.previousQty);
  }

  /// Set list variant options (old notifier method)
  void setListVariantOptions(List<VariantOptionModel> options) {
    state = state.copyWith(listVariantOptions: options);
  }

  /// Set temp variant option model (old notifier method)
  void setTempVariantOptionModel(VariantOptionModel? model) {
    state = state.copyWith(tempVariantOptionModel: model);
  }

  /// Set dialogue navigation (old notifier method)
  void setDialogueNavigation(String navigation) {
    state = state.copyWith(dialogueNavigation: navigation);
  }

  /// Get list items that does not have category and have category (old notifier method)
  List<ItemModel> getListItemsThatDoesNotHaveCategoryAndHaveCategory() {
    final items = List<ItemModel>.from(state.items);
    items.sort(
      (a, b) => a.name!.toLowerCase().compareTo(b.name!.toLowerCase()),
    );
    return items;
  }

  /// Reset temp qty and price (old notifier method)
  void resetTempQtyAndPrice() {
    state = state.copyWith(
      tempQty: '0.000',
      tempPrice: "0.00",
      selectedQty: '0.000',
      selectedPrice: "0.00",
    );
  }

  /// Load item representations
  Future<void> loadItemRepresentations() async {
    try {
      final itemRepresentationNotifier = _ref.read(
        itemRepresentationProvider.notifier,
      );
      final representations =
          itemRepresentationNotifier.getListItemRepresentationFromHive();
      state = state.copyWith(itemRepresentations: representations);
    } catch (e) {
      prints('Error loading item representations: $e');
    }
  }

  /// Convert variant option to JSON
  /// This method is used to extract variant option JSON from a sale item
  String convertVariantOptionToJson(
    SaleItemModel saleItem,
    List<SaleItemModel> listSaleItems,
  ) {
    /// get specific sale item model
    SaleItemModel usedSaleItemModel = listSaleItems.firstWhere((e) {
      return e.id == saleItem.id &&
          e.variantOptionId == saleItem.variantOptionId &&
          e.comments == saleItem.comments &&
          e.updatedAt == saleItem.updatedAt;
    }, orElse: () => SaleItemModel());

    String variantOptionJson = '';

    if (usedSaleItemModel.variantOptionId != null) {
      dynamic varOptJson =
          usedSaleItemModel.variantOptionJson != null
              ? jsonDecode(usedSaleItemModel.variantOptionJson!)
              : jsonDecode('{}');

      VariantOptionModel variantOptModel = VariantOptionModel.fromJson(
        varOptJson,
      );

      variantOptionJson = jsonEncode(variantOptModel);
    }

    return variantOptionJson;
  }

  ItemModel? getSelectedItemByPageId(
    String pageId,
    List<PageItemModel> pageItems,
    ItemModel? item,
  ) {
    if (item == null) return null;

    PageItemModel? pageItem = pageItems.firstWhere(
      (pageItem) =>
          pageItem.pageId == pageId &&
          pageItem.pageItemableType == PolymorphicEnum.item &&
          pageItem.pageItemableId == item.id,
      orElse: () => PageItemModel(), // Provide a fallback value
    );

    return pageItem.id != null ? item : null;
  }

  Future<List<ItemModel>> syncFromRemote() async {
    List<ItemModel> allItems = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching items page $currentPage');
      ItemListResponseModel responseModel = await _webService.get(
        getItemList(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Process items from current page
        List<ItemModel> listItems = responseModel.data!;
        for (ItemModel item in listItems) {
          if (item.requiredModifierNum != null &&
              item.requiredModifierNum! <= 0) {
            item.requiredModifierNum = null;
          }
        }

        // Add items from current page to the list
        await insertBulk(listItems, isInsertToPending: false);
        allItems.addAll(listItems);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination ITEM MODEL: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch items page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints('Fetched a total of ${allItems.length} items from all pages');
    return allItems;
  }

  Resource getItemList(String page) {
    return _remoteRepository.getItemList(page);
  }

  List<ItemModel> getListItemFromHive() {
    return _localRepository.getListItemFromHive();
  }
}

/// Provider for sorted items (computed provider)
final sortedItemsProvider = Provider<List<ItemModel>>((ref) {
  final items = ref.watch(itemProvider).items;
  final sorted = List<ItemModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for item domain
final itemProvider = StateNotifierProvider<ItemNotifier, ItemState>((ref) {
  return ItemNotifier(
    localRepository: ServiceLocator.get<LocalItemRepository>(),
    remoteRepository: ServiceLocator.get<ItemRepository>(),
    webService: ServiceLocator.get<IWebService>(),
    ref: ref,
  );
});

/// Provider for item by ID (family provider for indexed lookups)
final itemByIdProvider = Provider.family<ItemModel?, String>((ref, id) {
  final items = ref.watch(itemProvider).items;
  try {
    return items.firstWhere((item) => item.id == id);
  } catch (e) {
    return null;
  }
});

/// Provider for items by category ID (computed family provider)
final itemsByCategoryIdProvider = Provider.family<List<ItemModel>, String>((
  ref,
  categoryId,
) {
  final notifier = ref.watch(itemProvider.notifier);
  return notifier.getItemWithCategory(categoryId);
});

/// Provider for filtered items by name (computed provider)
final filteredItemsByNameProvider = Provider<List<ItemModel>>((ref) {
  final notifier = ref.watch(itemProvider.notifier);
  return notifier.getItemModelsByName();
});

/// Provider for filtered items by category and name (computed family provider)
final filteredItemsByCategoryProvider =
    Provider.family<List<ItemModel>, String>((ref, categoryId) {
      final notifier = ref.watch(itemProvider.notifier);
      return notifier.getFilteredItemList(categoryId);
    });

/// Provider for items from Hive cache (synchronous)
final itemsFromHiveProvider = Provider<List<ItemModel>>((ref) {
  final notifier = ref.watch(itemProvider.notifier);
  return notifier.getListItemFromHive();
});

/// Provider for item count (computed provider)
final itemCountProvider = Provider<int>((ref) {
  final items = ref.watch(itemProvider).items;
  return items.length;
});

/// Provider for items by IDs (computed family provider)
final itemsByIdsProvider = Provider.family<List<ItemModel>, List<String>>((
  ref,
  ids,
) {
  final notifier = ref.watch(itemProvider.notifier);
  return notifier.getItemModelsByIds(ids);
});

/// Provider for variant options by item ID (computed family provider)
final variantOptionsByItemIdProvider =
    Provider.family<List<VariantOptionModel>, String>((ref, itemId) {
      final notifier = ref.watch(itemProvider.notifier);
      return notifier.getListVariantOptionByItemId(itemId);
    });

/// Provider for item representations (computed provider)
final itemRepresentationsProvider = Provider<List<ItemRepresentationModel>>((
  ref,
) {
  final state = ref.watch(itemProvider);
  return state.itemRepresentations;
});

/// Provider for items with barcode (computed provider)
final itemsWithBarcodeProvider = Provider<List<ItemModel>>((ref) {
  final items = ref.watch(itemProvider).items;
  return items
      .where((item) => item.barcode != null && item.barcode!.isNotEmpty)
      .toList();
});

/// Provider for items by search query (computed family provider)
final itemsBySearchQueryProvider = Provider.family<List<ItemModel>, String>((
  ref,
  query,
) {
  if (query.trim().isEmpty) {
    return ref.watch(itemProvider).items;
  }

  final items = ref.watch(itemProvider).items;
  final lowerQuery = query.toLowerCase();

  return items.where((item) {
    return (item.name?.toLowerCase().contains(lowerQuery) ?? false) ||
        (item.barcode?.toLowerCase().contains(lowerQuery) ?? false);
  }).toList();
});

/// Provider for checking if item exists by ID (computed family provider)
final itemExistsByIdProvider = Provider.family<bool, String>((ref, id) {
  final items = ref.watch(itemProvider).items;
  return items.any((item) => item.id == id);
});

/// Provider for current item name (from state)
final currentItemNameProvider = Provider<String>((ref) {
  return ref.watch(itemProvider).itemName;
});

/// Provider for current search item name (from state)
final currentSearchItemNameProvider = Provider<String>((ref) {
  return ref.watch(itemProvider).searchItemName;
});

/// Provider for dialogue navigation state
final dialogueNavigationProvider = Provider<String>((ref) {
  return ref.watch(itemProvider).dialogueNavigation;
});

/// Provider for temp variant option model
final tempVariantOptionModelProvider = Provider<VariantOptionModel?>((ref) {
  return ref.watch(itemProvider).tempVariantOptionModel;
});

/// Provider for list variant options
final listVariantOptionsProvider = Provider<List<VariantOptionModel>>((ref) {
  return ref.watch(itemProvider).listVariantOptions;
});
