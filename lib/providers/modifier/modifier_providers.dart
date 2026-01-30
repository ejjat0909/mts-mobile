import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/modifier/modifier_model.dart';
import 'package:mts/domain/repositories/local/modifier_repository.dart';
import 'package:mts/providers/modifier/modifier_state.dart';
import 'dart:convert';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/modifier/modifier_list_response_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/domain/repositories/local/item_modifier_repository.dart';
import 'package:mts/domain/repositories/local/modifier_option_repository.dart';
import 'package:mts/domain/repositories/remote/modifier_repository.dart';

/// StateNotifier for Modifier domain
///
/// Migrated from: modifier_facade_impl.dart
class ModifierNotifier extends StateNotifier<ModifierState> {
  final LocalModifierRepository _localRepository;
  final ModifierRepository _remoteRepository;
  final LocalItemModifierRepository _localItemModifierrepository;
  final IWebService _webService;
  final LocalModifierOptionRepository _localModifierOptionRepository;

  ModifierNotifier({
    required LocalModifierRepository localRepository,
    required ModifierRepository remoteRepository,
    required LocalModifierOptionRepository localModifierOptionRepository,
    required LocalItemModifierRepository localItemModifierRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _localModifierOptionRepository = localModifierOptionRepository,
       _remoteRepository = remoteRepository,
       _localItemModifierrepository = localItemModifierRepository,
       _webService = webService,
       super(const ModifierState());

  // ============================================================
  // CRUD Operations - Optimized for Riverpod
  // ============================================================

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<ModifierModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        state = state.copyWith(
          items: [...state.items, ...list],
          isLoading: false,
        );
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
  Future<List<ModifierModel>> getListModifierModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListModifierModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<ModifierModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        final idsToRemove = list.map((e) => e.id).toSet();
        final remainingItems =
            state.items
                .where((item) => !idsToRemove.contains(item.id))
                .toList();
        state = state.copyWith(items: remainingItems, isLoading: false);
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
        final remainingItems =
            state.items.where((item) => item.id != id).toList();
        state = state.copyWith(items: remainingItems, isLoading: false);
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
  Future<ModifierModel?> getModifierModelById(String itemId) async {
    try {
      final items = await _localRepository.getListModifierModel();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => ModifierModel(),
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
    List<ModifierModel> newData, {
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
    List<ModifierModel> list, {
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
        final upsertedIds = list.map((e) => e.id).toSet();
        final existingItems =
            state.items
                .where((item) => !upsertedIds.contains(item.id))
                .toList();
        state = state.copyWith(
          items: [...existingItems, ...list],
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Force reload from database (use sparingly)
  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListModifierModel();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Get list of modifiers (synchronous getter from old notifier)
  List<ModifierModel> getListModifiers() {
    return _localRepository.getListModifierFromHive();
  }

  Future<List<ModifierModel>> getListModifierModelByItemId(
    String itemId,
  ) async {
    // Query the local database for the modifier IDs associated with the given itemId
    final modifierIds = await _localItemModifierrepository
        .getModifierIdsByItemId(itemId);

    if (modifierIds.isNotEmpty) {
      // Query the local database for the ModifierModel objects corresponding to the modifier IDs
      final listModifiers = await _localRepository.getModifiersByIds(
        modifierIds,
      );

      return listModifiers;
    }

    return [];
  }

  Future<List<ModifierModel>> syncFromRemote() async {
    List<ModifierModel> allModifiers = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching modifiers page $currentPage');
      ModifierListResponseModel responseModel = await _webService.get(
        getModifierListWithPagination(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Process modifiers from current page
        List<ModifierModel> pageModifiers = responseModel.data!;

        // Add modifiers from current page to the list
        allModifiers.addAll(pageModifiers);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination MODIFIER: current page=$currentPage, last page=$lastPage, total modifiers=${responseModel.paginator!.total}',
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
          'Failed to fetch modifiers page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allModifiers.length} modifiers from all pages',
    );
    return allModifiers;
  }

  Resource getModifierListWithPagination(String page) {
    return _remoteRepository.getModifierListWithPagination(page);
  }

  List<ModifierModel> ensureUniqueModifierList(
    List<ModifierModel> listModifiers,
  ) {
    Set<String> seenIds = {}; // Set to track unique ids
    List<ModifierModel> uniqueList = [];

    for (ModifierModel modifier in listModifiers) {
      if (!seenIds.contains(modifier.id)) {
        seenIds.add(modifier.id!); // Add the id to the set
        uniqueList.add(modifier); // Add the discount to the unique list
      }
    }

    return uniqueList;
  }

  Future<ModifierModel> getModifierById(String idModifier) async {
    return await _localRepository.getModifierById(idModifier);
  }

  Future<List<ModifierModel>> getModifierListFromListModifierOptionIds(
    List<String> listModifierOptionIds,
  ) async {
    return await _localRepository.getModifierListFromListModifierOptionIds(
      listModifierOptionIds,
    );
  }

  Future<String> convertListModifierToJson(
    SaleItemModel saleItem,
    List<SaleModifierModel> saleModifierModels,
    List<SaleModifierOptionModel> saleModifierOptionModels,
  ) async {
    /// Use the provided SaleModifierModels and SaleModifierOptionModels

    /// Get SaleModifier IDs associated with the given SaleItem
    List<String> saleModifierIds =
        saleModifierModels
            .where((element) => element.saleItemId == saleItem.id)
            .map((e) => e.id!)
            .toList();

    /// Get ModifierOption IDs using the SaleModifier IDs
    List<String> modifierOptionIds =
        saleModifierOptionModels
            .where(
              (element) => saleModifierIds.contains(element.saleModifierId),
            )
            .map((e) => e.modifierOptionId!)
            .toList();

    /// Fetch ModifierOptionModels based on their IDs
    List<ModifierOptionModel> listModifierOptionModels =
        await _localModifierOptionRepository.getModifierOptionModelFromListIds(
          modifierOptionIds,
        );

    /// Group ModifierOptionModels by Modifier ID
    Map<String, List<ModifierOptionModel>> groupedOptions = {};
    for (ModifierOptionModel option in listModifierOptionModels) {
      groupedOptions.putIfAbsent(option.modifierId!, () => []).add(option);
    }

    /// Create ModifierModel list and combine options
    List<ModifierModel> listModifierModel = [];
    for (String modifierId in groupedOptions.keys) {
      ModifierModel modifierModel = await getModifierById(modifierId);

      // Attach all corresponding options to this modifier
      modifierModel.modifierOptions = groupedOptions[modifierId];
      listModifierModel.add(modifierModel);
    }

    /// Convert the ModifierModel list to JSON
    List<Map<String, dynamic>> jsonList =
        listModifierModel
            .map((modifierModel) => modifierModel.toJsonForReceiptItem())
            .toList();

    return jsonEncode(jsonList);
  }

  List<ModifierModel> getListModifierFromHive() {
    return _localRepository.getListModifierFromHive();
  }
}

/// Provider for sorted items (computed provider)
final sortedModifiersProvider = Provider<List<ModifierModel>>((ref) {
  final items = ref.watch(modifierProvider).items;
  final sorted = List<ModifierModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for modifier domain
final modifierProvider = StateNotifierProvider<ModifierNotifier, ModifierState>(
  (ref) {
    return ModifierNotifier(
      localRepository: ServiceLocator.get<LocalModifierRepository>(),
      localModifierOptionRepository:
          ServiceLocator.get<LocalModifierOptionRepository>(),
      remoteRepository: ServiceLocator.get<ModifierRepository>(),
      localItemModifierRepository:
          ServiceLocator.get<LocalItemModifierRepository>(),
      webService: ServiceLocator.get<IWebService>(),
    );
  },
);

/// Provider for modifier by ID (family provider for indexed lookups)
final modifierByIdProvider = FutureProvider.family<ModifierModel?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(modifierProvider.notifier);
  return notifier.getModifierModelById(id);
});

/// Provider for synchronous modifier by ID (from current state)
final modifierByIdFromStateProvider = Provider.family<ModifierModel?, String>((
  ref,
  id,
) {
  final items = ref.watch(modifierProvider).items;
  try {
    return items.firstWhere((item) => item.id == id);
  } catch (e) {
    return null;
  }
});

/// Provider for modifiers by search query (family provider)
final modifiersBySearchProvider = Provider.family<List<ModifierModel>, String>((
  ref,
  query,
) {
  final items = ref.watch(modifierProvider).items;
  if (query.isEmpty) return items;

  final lowerQuery = query.toLowerCase();
  return items.where((modifier) {
    final name = (modifier.name ?? '').toLowerCase();
    return name.contains(lowerQuery);
  }).toList();
});

/// Provider for modifiers by item ID (family provider)
final modifiersByItemIdProvider =
    FutureProvider.family<List<ModifierModel>, String>((ref, itemId) async {
      final notifier = ref.watch(modifierProvider.notifier);
      return await notifier.getListModifierModelByItemId(itemId);
    });

/// Provider to check if a modifier exists by ID
final modifierExistsProvider = Provider.family<bool, String>((ref, id) {
  final items = ref.watch(modifierProvider).items;
  return items.any((item) => item.id == id);
});

/// Provider for total modifier count
final modifierCountProvider = Provider<int>((ref) {
  final items = ref.watch(modifierProvider).items;
  return items.length;
});
