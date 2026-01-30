import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/domain/repositories/local/modifier_option_repository.dart';
import 'package:mts/providers/modifier/modifier_providers.dart';
import 'package:mts/providers/modifier_option/modifier_option_state.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/modifier/modifier_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_list_response_model.dart';
import 'package:mts/domain/repositories/remote/modifier_option_repository.dart';

/// StateNotifier for ModifierOption domain
///
/// Migrated from: modifier_option_facade_impl.dart
class ModifierOptionNotifier extends StateNotifier<ModifierOptionState> {
  final LocalModifierOptionRepository _localRepository;
  final ModifierOptionRepository _remoteRepository;
  final IWebService _webService;
  final Ref _ref;

  ModifierOptionNotifier({
    required LocalModifierOptionRepository localRepository,
    required ModifierOptionRepository remoteRepository,
    required IWebService webService,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _ref = ref,
       super(const ModifierOptionState());

  /// Insert a single item into local storage
  Future<int> insert(
    ModifierOptionModel model, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(
        model,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        final updatedItems = List<ModifierOptionModel>.from(state.items)
          ..add(model);
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

  /// Update a single item in local storage
  Future<int> update(
    ModifierOptionModel model, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.update(
        model,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        final updatedItems =
            state.items.map((item) {
              return item.id == model.id ? model : item;
            }).toList();
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

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<ModifierOptionModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<ModifierOptionModel>.from(state.items);
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
  Future<List<ModifierOptionModel>> getListModifierOptionModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListModifierOptionModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<ModifierOptionModel> list) async {
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
  Future<ModifierOptionModel?> getModifierOptionModelById(String itemId) async {
    try {
      // First check current state
      final cachedItem =
          state.items.where((item) => item.id == itemId).firstOrNull;
      if (cachedItem != null) return cachedItem;

      // Fall back to repository
      final items = await _localRepository.getListModifierOptionModel();
      return items.where((item) => item.id == itemId).firstOrNull;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<ModifierOptionModel> newData, {
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
    List<ModifierOptionModel> list, {
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
        final currentItems = List<ModifierOptionModel>.from(state.items);
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
      final items = await _localRepository.getListModifierOptionModel();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ============================================================
  // UI State Management Methods (from old ModifierOptionNotifier)
  // ============================================================

  /// Get modifier option list (getter for compatibility)
  List<ModifierOptionModel> get getModifierOptionList => state.items;

  /// Initialize for second screen (compatibility method)
  void initializeForSecondScreen(
    List<ModifierOptionModel> list, {
    bool reInitializeCache = false,
  }) {
    // Note: MenuItem.reInitializeCache logic should be in presentation layer
    // This method kept for API compatibility
  }

  /// Get modifier option names from list of IDs
  String getModifierOptionNameFromListIds(List<String> modifierOptionIds) {
    final matchedNames = <String>[];

    for (String id in modifierOptionIds) {
      for (ModifierOptionModel modifierOption in state.items) {
        if (modifierOption.id == id) {
          matchedNames.add(modifierOption.name!);
          break;
        }
      }
    }

    return matchedNames.join(matchedNames.length == 1 ? '' : ', ');
  }

  /// Get modifier option names from list of IDs (for transfer)
  String getModifierOptionNameFromListIdsForTransfer(
    List<String> modifierOptionIds,
    List<ModifierOptionModel> listMO,
  ) {
    final matchedNames = <String>[];

    for (String id in modifierOptionIds) {
      for (ModifierOptionModel modifierOption in listMO) {
        if (modifierOption.id == id) {
          matchedNames.add(modifierOption.name!);
          break;
        }
      }
    }

    return matchedNames.join(matchedNames.length == 1 ? '' : ', ');
  }

  /// Get list of modifier IDs from modifier option IDs
  Future<List<String>> getListModifierIdsByModifierOptionIds(
    List<String> modOptIds,
  ) async {
    try {
      return await _localRepository.getListModifierIdsByModifierOptionIds(
        modOptIds,
      );
    } catch (e) {
      return [];
    }
  }

  /// Get modifier option models from list of IDs
  List<ModifierOptionModel> getModifierOptionModelFromListIds(
    List<String> listModifierOptionIds,
  ) {
    return state.items
        .where(
          (modifierOption) => listModifierOptionIds.contains(modifierOption.id),
        )
        .toList();
  }

  Future<List<ModifierOptionModel>> generateSeedModifierOption() async {
    final modifierNotifier = _ref.read(modifierProvider.notifier);
    List<ModifierOptionModel> modifierOptions = [];
    final listModifier = await modifierNotifier.getListModifierModel();

    List<String> names = [
      'Nak Cheese',
      'Nak Bawang',
      'Nak Ayam Lebih',
      'Kurang Cheese',
    ];

    for (ModifierModel modifierModel in listModifier) {
      for (String modifierName in names) {
        modifierOptions.add(
          ModifierOptionModel(
            price: 20.30,
            id: IdUtils.generateUUID(),
            name: modifierName,
            modifierId: modifierModel.id,
          ),
        );
      }
    }

    return modifierOptions;
  }

  Future<List<ModifierOptionModel>> getListModifierOptionByModifierId(
    String idModifier,
  ) async {
    return await _localRepository.getListModifierOptionsByModifierId(
      idModifier,
    );
  }

  Future<List<ModifierOptionModel>> extractModifierOptionsFromModifierList(
    List<dynamic> listModifiers,
  ) async {
    List<ModifierOptionModel> listModifierOption = [];
    for (ModifierModel modifier in listModifiers) {
      // Use the loadModifierOptions helper method to ensure options are loaded
      List<ModifierOptionModel> options = await modifier.loadModifierOptions();
      if (options.isNotEmpty) {
        listModifierOption.addAll(options);
      }
    }

    return listModifierOption;
  }

  Future<Map<String, List<ModifierOptionModel>>> loadModifierOptionsMap(
    List<dynamic> modifiers,
  ) async {
    Map<String, List<ModifierOptionModel>> groupedModifiers = {};

    for (ModifierModel modifier in modifiers) {
      if (modifier.id != null) {
        // Get options for this modifier
        List<ModifierOptionModel> options =
            await getListModifierOptionByModifierId(modifier.id!);

        // Add to the map
        groupedModifiers.putIfAbsent(modifier.id!, () => []);
        groupedModifiers[modifier.id!]!.addAll(options);
      }
    }

    return groupedModifiers;
  }

  List<ModifierOptionModel> getListModifierOptionFromHive() {
    return _localRepository.getListModifierOptionFromHive();
  }

  Future<List<ModifierOptionModel>> syncFromRemote() async {
    List<ModifierOptionModel> allModifierOptions = [];
    int currentPage = 1;
    int? lastPage;

    do {
      prints('Fetching modifier options page $currentPage');
      ModifierOptionListResponseModel responseModel = await _webService.get(
        _remoteRepository.getModifierOptionListWithPagination(
          currentPage.toString(),
        ),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        List<ModifierOptionModel> pageModifierOptions = responseModel.data!;

        allModifierOptions.addAll(pageModifierOptions);

        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination MODIFIER_OPTION: current page=$currentPage, last page=$lastPage, total modifier options=${responseModel.paginator!.total}',
          );
        } else {
          break;
        }

        currentPage++;
      } else {
        prints(
          'Failed to fetch modifier options page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allModifierOptions.length} modifier options from all pages',
    );
    return allModifierOptions;
  }
}

/// Provider for modifierOption domain
final modifierOptionProvider =
    StateNotifierProvider<ModifierOptionNotifier, ModifierOptionState>((ref) {
      return ModifierOptionNotifier(
        localRepository: ServiceLocator.get<LocalModifierOptionRepository>(),
        remoteRepository: ServiceLocator.get<ModifierOptionRepository>(),
        webService: ServiceLocator.get<IWebService>(),
        ref: ref,
      );
    });

/// Provider for sorted items (computed provider)
final sortedModifierOptionsProvider = Provider<List<ModifierOptionModel>>((
  ref,
) {
  final items = ref.watch(modifierOptionProvider).items;
  final sorted = List<ModifierOptionModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for modifierOption by ID (family provider for indexed lookups)
final modifierOptionByIdProvider =
    FutureProvider.family<ModifierOptionModel?, String>((ref, id) async {
      final notifier = ref.watch(modifierOptionProvider.notifier);
      return notifier.getModifierOptionModelById(id);
    });

/// Provider for synchronous modifier option by ID (from current state)
final modifierOptionByIdFromStateProvider =
    Provider.family<ModifierOptionModel?, String>((ref, id) {
      final items = ref.watch(modifierOptionProvider).items;
      try {
        return items.firstWhere((item) => item.id == id);
      } catch (e) {
        return null;
      }
    });

/// Provider for modifier options by modifier ID (family provider)
final modifierOptionsByModifierIdProvider =
    Provider.family<List<ModifierOptionModel>, String>((ref, modifierId) {
      final items = ref.watch(modifierOptionProvider).items;
      return items.where((option) => option.modifierId == modifierId).toList();
    });

/// Provider for async modifier options by modifier ID (family provider)
final modifierOptionsByModifierIdAsyncProvider =
    FutureProvider.family<List<ModifierOptionModel>, String>((
      ref,
      modifierId,
    ) async {
      final notifier = ref.watch(modifierOptionProvider.notifier);
      return await notifier.getListModifierOptionByModifierId(modifierId);
    });

/// Provider for modifier options by search query (family provider)
final modifierOptionsBySearchProvider =
    Provider.family<List<ModifierOptionModel>, String>((ref, query) {
      final items = ref.watch(modifierOptionProvider).items;
      if (query.isEmpty) return items;

      final lowerQuery = query.toLowerCase();
      return items.where((option) {
        final name = (option.name ?? '').toLowerCase();
        return name.contains(lowerQuery);
      }).toList();
    });

/// Provider for modifier options from list of IDs (family provider)
final modifierOptionsByIdsProvider =
    Provider.family<List<ModifierOptionModel>, List<String>>((ref, ids) {
      final notifier = ref.watch(modifierOptionProvider.notifier);
      return notifier.getModifierOptionModelFromListIds(ids);
    });

/// Provider to check if a modifier option exists by ID
final modifierOptionExistsProvider = Provider.family<bool, String>((ref, id) {
  final items = ref.watch(modifierOptionProvider).items;
  return items.any((item) => item.id == id);
});

/// Provider for total modifier option count
final modifierOptionCountProvider = Provider<int>((ref) {
  final items = ref.watch(modifierOptionProvider).items;
  return items.length;
});

/// Provider for count of options per modifier (family provider)
final optionCountPerModifierProvider = Provider.family<int, String>((
  ref,
  modifierId,
) {
  final options = ref.watch(modifierOptionsByModifierIdProvider(modifierId));
  return options.length;
});

/// Provider for modifier option names from list of IDs (family provider)
final modifierOptionNamesProvider = Provider.family<String, List<String>>((
  ref,
  ids,
) {
  final notifier = ref.watch(modifierOptionProvider.notifier);
  return notifier.getModifierOptionNameFromListIds(ids);
});
