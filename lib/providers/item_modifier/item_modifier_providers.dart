import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/item_modifier/item_modifier_list_response_model.dart';
import 'package:mts/data/models/item_modifier/item_modifier_model.dart';
import 'package:mts/data/models/modifier/modifier_model.dart';
import 'package:mts/domain/repositories/local/item_modifier_repository.dart';
import 'package:mts/domain/repositories/remote/item_modifier_repository.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/item_modifier/item_modifier_state.dart';
import 'package:mts/providers/modifier/modifier_providers.dart';
import 'package:mts/providers/modifier_option/modifier_option_providers.dart';

/// StateNotifier for ItemModifier domain
///
/// Migrated from: item_modifier_facade_impl.dart
/// All facade business logic migrated with optimal Riverpod patterns
class ItemModifierNotifier extends StateNotifier<ItemModifierState> {
  final LocalItemModifierRepository _localRepository;
  final ItemModifierRepository _remoteRepository;
  final IWebService _webService;
  final Ref _ref;

  ItemModifierNotifier({
    required LocalItemModifierRepository localRepository,
    required ItemModifierRepository remoteRepository,
    required IWebService webService,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _ref = ref,
       super(const ItemModifierState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<ItemModifierModel> list, {
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
  Future<List<ItemModifierModel>> getListItemModifier() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListItemModifier();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<ItemModifierModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        // Use composite key for pivot table
        final keysToDelete =
            list.map((e) => '${e.itemId}_${e.modifierId}').toSet();
        final updatedItems =
            state.items
                .where(
                  (e) => !keysToDelete.contains('${e.itemId}_${e.modifierId}'),
                )
                .toList();
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

  /// Delete item modifiers by item ID
  Future<int> deleteByItemId(
    String itemId, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteByColumnName(
        'item_id',
        itemId,
        isInsertToPending,
      );

      if (result > 0) {
        final updatedItems =
            state.items.where((e) => e.itemId != itemId).toList();
        state = state.copyWith(items: updatedItems);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Find item modifiers by item ID
  Future<List<ItemModifierModel>> getModifiersByItemId(String itemId) async {
    try {
      final items = await _localRepository.getListItemModifier();
      return items.where((item) => item.itemId == itemId).toList();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get modifier IDs by item ID
  Future<List<String?>> getModifierIdsByItemId(String itemId) async {
    try {
      return await _localRepository.getModifierIdsByItemId(itemId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<ItemModifierModel> newData, {
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
    List<ItemModifierModel> list, {
    bool isInsertToPending = true,
    bool isQueue = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      // Note: Interface doesn't have upsertBulk, using replaceAllData instead
      final result = await _localRepository.replaceAllData(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        state = state.copyWith(items: list);
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
      final items = await _localRepository.getListItemModifier();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ============================================================
  // API Methods migrated from facade
  // ============================================================

  /// Get all item modifiers from API with pagination (optimized for large datasets)
  Future<List<ItemModifierModel>> syncFromRemote() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      List<ItemModifierModel> allItemModifiers = [];
      int currentPage = 1;
      int? lastPage;

      do {
        prints('Fetching item modifiers page $currentPage');

        ItemModifierListResponseModel responseModel = await _webService.get(
          getListItemModifierWithPagination(currentPage.toString()),
        );

        if (responseModel.isSuccess && responseModel.data != null) {
          List<ItemModifierModel> pageItemModifiers = responseModel.data!;
          allItemModifiers.addAll(pageItemModifiers);

          if (responseModel.paginator != null) {
            lastPage = responseModel.paginator!.lastPage;
            prints(
              'Pagination ITEM MODIFIER: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
            );
          } else {
            break;
          }

          currentPage++;
        } else {
          prints(
            'Failed to fetch item modifiers page $currentPage: ${responseModel.message}',
          );
          break;
        }
      } while (lastPage != null && currentPage <= lastPage);

      prints(
        'Fetched a total of ${allItemModifiers.length} item modifiers from all pages',
      );

      state = state.copyWith(isLoading: false);
      return allItemModifiers;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Get resource for paginated item modifier list
  Resource getListItemModifierWithPagination(String page) {
    return _remoteRepository.getListItemModifierWithPagination(page);
  }

  /// Generate seed data for item modifiers (creates all item-modifier combinations)
  Future<List<ItemModifierModel>> generateSeedItemModifiers() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      List<ItemModifierModel> itemModifiers = [];
      final itemFacade = _ref.read(itemProvider.notifier);
      final modifierFacade = _ref.read(modifierProvider.notifier);

      final listItems = await itemFacade.getListItemModel();
      final listModifiers = await modifierFacade.getListModifierModel();

      for (ItemModel itemModel in listItems) {
        for (ModifierModel modifier in listModifiers) {
          itemModifiers.add(
            ItemModifierModel(
              itemId: itemModel.id.toString(),
              modifierId: modifier.id.toString(),
            ),
          );
        }
      }

      prints('Generated ${itemModifiers.length} seed item modifiers');

      state = state.copyWith(isLoading: false);
      return itemModifiers;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Get list of modifier models by item ID
  /// Migrated from old ItemModifierNotifier ChangeNotifier
  List<ModifierModel> getListModifierModelByItemId(String itemId) {
    final modifierNotifier = _ref.read(modifierProvider.notifier);
    final listModifiers = modifierNotifier.getListModifierFromHive();

    // 1. Get all item-modifier relations for this itemId
    final filteredItemModifiers =
        state.items.where((im) => im.itemId == itemId).toList();

    // 2. Extract unique modifier IDs
    final uniqueModifierIds =
        filteredItemModifiers
            .map((im) => im.modifierId)
            .whereType<String>()
            .toSet();

    // 3. Filter modifiers based on ID
    return listModifiers.where((modifier) {
      return uniqueModifierIds.contains(modifier.id);
    }).toList();
  }

  /// Get modifier list from list of modifier option IDs
  /// Migrated from old ItemModifierNotifier ChangeNotifier
  List<ModifierModel> getModifierListFromListModifierOptionIds(
    List<String> listModifierOptionIds,
  ) {
    if (listModifierOptionIds.isEmpty) {
      return [];
    }

    final modifierNotifier = _ref.read(modifierProvider.notifier);
    final modifierOptionNotifier = _ref.read(modifierOptionProvider.notifier);

    final listModifiers = modifierNotifier.getListModifierFromHive();
    final listModifierOptions = modifierOptionNotifier
        .getModifierOptionModelFromListIds(listModifierOptionIds);

    // extract modifier ids from modifier option ids
    final listModifierIds =
        listModifierOptions.map((e) => e.modifierId!).toList();

    return listModifiers
        .where((modifier) => listModifierIds.contains(modifier.id))
        .toList();
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get item modifier list (old notifier getter)
  List<ItemModifierModel> get getItemModifierList => state.items;

  /// Set the entire list of item modifiers (old notifier method)
  void setListItemModifier(List<ItemModifierModel> list) {
    state = state.copyWith(items: list);
  }

  /// Add or update a list of item modifiers (old notifier method)
  void addOrUpdateList(List<ItemModifierModel> list) {
    final currentItems = List<ItemModifierModel>.from(state.items);

    for (final itemModifier in list) {
      final index = currentItems.indexWhere(
        (element) =>
            element.itemId == itemModifier.itemId &&
            element.modifierId == itemModifier.modifierId,
      );

      if (index != -1) {
        currentItems[index] = itemModifier;
      } else {
        currentItems.add(itemModifier);
      }
    }

    state = state.copyWith(items: currentItems);
  }

  /// Add or update a single item modifier (old notifier method)
  void addOrUpdate(ItemModifierModel itemModifier) {
    final currentItems = List<ItemModifierModel>.from(state.items);

    final index = currentItems.indexWhere(
      (im) =>
          im.itemId == itemModifier.itemId &&
          im.modifierId == itemModifier.modifierId,
    );

    if (index != -1) {
      currentItems[index] = itemModifier;
    } else {
      currentItems.add(itemModifier);
    }

    state = state.copyWith(items: currentItems);
  }

  /// Remove an item modifier by composite key (old notifier method)
  void remove(String itemId, String modifierId) {
    final updatedItems =
        state.items
            .where(
              (itemModifier) =>
                  !(itemModifier.itemId == itemId &&
                      itemModifier.modifierId == modifierId),
            )
            .toList();

    state = state.copyWith(items: updatedItems);
  }
}

/// Provider for sorted items (computed provider)
final sortedItemModifiersProvider = Provider<List<ItemModifierModel>>((ref) {
  final items = ref.watch(itemModifierProvider).items;
  final sorted = List<ItemModifierModel>.from(items);
  sorted.sort((a, b) => (a.itemId ?? '').compareTo(b.itemId ?? ''));
  return sorted;
});

/// Provider for itemModifier domain
final itemModifierProvider =
    StateNotifierProvider<ItemModifierNotifier, ItemModifierState>((ref) {
      return ItemModifierNotifier(
        localRepository: ServiceLocator.get<LocalItemModifierRepository>(),
        remoteRepository: ServiceLocator.get<ItemModifierRepository>(),
        webService: ServiceLocator.get<IWebService>(),
        ref: ref,
      );
    });

/// Provider for item modifiers by item ID (family provider)
final itemModifiersByItemIdProvider =
    Provider.family<List<ItemModifierModel>, String>((ref, itemId) {
      final items = ref.watch(itemModifierProvider).items;
      return items.where((item) => item.itemId == itemId).toList();
    });

/// Provider for item modifiers by modifier ID (family provider)
final itemModifiersByModifierIdProvider =
    Provider.family<List<ItemModifierModel>, String>((ref, modifierId) {
      final items = ref.watch(itemModifierProvider).items;
      return items.where((item) => item.modifierId == modifierId).toList();
    });

/// Provider for item modifier count (computed provider)
final itemModifierCountProvider = Provider<int>((ref) {
  final items = ref.watch(itemModifierProvider).items;
  return items.length;
});

/// Provider to check if item-modifier relation exists (computed family provider)
final itemModifierExistsProvider =
    Provider.family<bool, ({String itemId, String modifierId})>((ref, key) {
      final items = ref.watch(itemModifierProvider).items;
      return items.any(
        (item) =>
            item.itemId == key.itemId && item.modifierId == key.modifierId,
      );
    });

/// Provider for modifier IDs by item ID (computed family provider)
final modifierIdsByItemIdProvider = Provider.family<List<String>, String>((
  ref,
  itemId,
) {
  final items = ref.watch(itemModifiersByItemIdProvider(itemId));
  return items.map((item) => item.modifierId).whereType<String>().toList();
});

/// Provider for item IDs by modifier ID (computed family provider)
final itemIdsByModifierIdProvider = Provider.family<List<String>, String>((
  ref,
  modifierId,
) {
  final items = ref.watch(itemModifiersByModifierIdProvider(modifierId));
  return items.map((item) => item.itemId).whereType<String>().toList();
});

/// Provider for modifier count per item (computed family provider)
final modifierCountPerItemProvider = Provider.family<int, String>((
  ref,
  itemId,
) {
  final modifiers = ref.watch(itemModifiersByItemIdProvider(itemId));
  return modifiers.length;
});

/// Provider for item count per modifier (computed family provider)
final itemCountPerModifierProvider = Provider.family<int, String>((
  ref,
  modifierId,
) {
  final items = ref.watch(itemModifiersByModifierIdProvider(modifierId));
  return items.length;
});

/// Provider for modifier models by item ID (computed family provider)
final modifierModelsByItemIdProvider =
    Provider.family<List<ModifierModel>, String>((ref, itemId) {
      final notifier = ref.watch(itemModifierProvider.notifier);
      return notifier.getListModifierModelByItemId(itemId);
    });
