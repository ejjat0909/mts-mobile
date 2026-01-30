import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/item_tax/item_tax_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/domain/repositories/local/item_tax_repository.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/item_tax/item_tax_state.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/item_tax/item_tax_list_response_model.dart';
import 'package:mts/domain/repositories/remote/item_tax_repository.dart';
import 'package:mts/providers/tax/tax_providers.dart';

/// StateNotifier for ItemTax domain
///
/// Migrated from: item_tax_facade_impl.dart
class ItemTaxNotifier extends StateNotifier<ItemTaxState> {
  final LocalItemTaxRepository _localRepository;
  final ItemTaxRepository _remoteRepository;
  final IWebService _webService;
  final Ref _ref;

  ItemTaxNotifier({
    required LocalItemTaxRepository localRepository,
    required ItemTaxRepository remoteRepository,
    required IWebService webService,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _ref = ref,
       super(const ItemTaxState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<ItemTaxModel> list, {
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
  Future<List<ItemTaxModel>> getListItemTax() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListItemTax();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<ItemTaxModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        // Use composite key for pivot table
        final keysToDelete = list.map((e) => '${e.itemId}_${e.taxId}').toSet();
        final updatedItems =
            state.items
                .where((e) => !keysToDelete.contains('${e.itemId}_${e.taxId}'))
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

  /// Delete item taxes by item ID
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

  /// Find item taxes by item ID
  Future<List<ItemTaxModel>> getTaxesByItemId(String itemId) async {
    try {
      final items = await _localRepository.getListItemTax();
      return items.where((item) => item.itemId == itemId).toList();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get TaxModel list for an item
  Future<List<dynamic>> getTaxModelsByItemId(String itemId) async {
    try {
      return await _localRepository.getTaxModelsByItemId(itemId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<ItemTaxModel> newData, {
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
    List<ItemTaxModel> list, {
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
      final items = await _localRepository.getListItemTax();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Get itemTaxList (synchronous getter)
  List<ItemTaxModel> getItemTaxList() {
    return state.items;
  }

  /// Set entire item tax list (synchronous setter)
  void setListItemTax(List<ItemTaxModel> list) {
    state = state.copyWith(items: list);
  }

  /// Add or update multiple item taxes (upsert bulk)
  Future<void> addOrUpdateList(
    List<ItemTaxModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final existingMap = {
          for (var e in state.items) '${e.itemId}_${e.taxId}': e,
        };
        for (var newItem in list) {
          existingMap['${newItem.itemId}_${newItem.taxId}'] = newItem;
        }
        state = state.copyWith(items: existingMap.values.toList());
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add or update single item tax (upsert)
  Future<void> addOrUpdate(
    ItemTaxModel itemTax, {
    bool isInsertToPending = true,
  }) async {
    await addOrUpdateList([itemTax], isInsertToPending: isInsertToPending);
  }

  /// Remove single item tax
  Future<void> remove(
    ItemTaxModel itemTax, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk([
        itemTax,
      ], isInsertToPending: isInsertToPending);

      if (result) {
        final compositeKey = '${itemTax.itemId}_${itemTax.taxId}';
        final updatedItems =
            state.items
                .where((e) => '${e.itemId}_${e.taxId}' != compositeKey)
                .toList();
        state = state.copyWith(items: updatedItems);
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Get list of tax models from item tax list (old notifier method)
  List<TaxModel> getListTaxModelFromItemTaxList(
    List<TaxModel> listReceiveTaxModel,
    ItemModel itemModel,
    TaxModel taxModel,
  ) {
    final listItemTax = state.items;
    final taxIds =
        listItemTax
            .where((it) => it.itemId == itemModel.id)
            .map((it) => it.taxId)
            .toList();
    final listTax = taxIds.where((e) => e == taxModel.id).toList();
    return listReceiveTaxModel.where((e) => listTax.contains(e.id)).toList();
  }

  Future<List<ItemTaxModel>> getListitemTax() async {
    return await _localRepository.getListItemTax();
  }

  Future<List<ItemTaxModel>> syncFromRemote() async {
    List<ItemTaxModel> allItemTaxes = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching item taxes page $currentPage');
      ItemTaxListResponseModel responseModel = await _webService.get(
        getItemTaxListPaginated(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Process item taxes from current page
        List<ItemTaxModel> pageItemTaxes = responseModel.data!;

        // Add item taxes from current page to the list
        allItemTaxes.addAll(pageItemTaxes);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination ITEM TAX: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch item taxes page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allItemTaxes.length} item taxes from all pages',
    );
    return allItemTaxes;
  }

  Resource getItemTaxListPaginated(String page) {
    return _remoteRepository.getItemTaxListPaginated(page);
  }

  Future<List<ItemTaxModel>> generateSeedItemModifiers() async {
    List<ItemTaxModel> itemTaxes = [];
    final itemNotifier = _ref.read(itemProvider.notifier);
    final listItems = await itemNotifier.getListItemModel();

    final taxFacade = _ref.read(taxProvider.notifier);
    final listTaxes = await taxFacade.getListTaxModel();
    for (ItemModel itemModel in listItems) {
      for (TaxModel tax in listTaxes) {
        itemTaxes.add(
          ItemTaxModel(
            itemId: itemModel.id.toString(),
            taxId: tax.id.toString(),
          ),
        );
      }
    }

    return itemTaxes;
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
}

/// Provider for sorted items (computed provider)
final sortedItemTaxsProvider = Provider<List<ItemTaxModel>>((ref) {
  final items = ref.watch(itemTaxProvider).items;
  final sorted = List<ItemTaxModel>.from(items);
  sorted.sort((a, b) => (a.itemId ?? '').compareTo(b.itemId ?? ''));
  return sorted;
});

/// Provider for itemTax domain
final itemTaxProvider = StateNotifierProvider<ItemTaxNotifier, ItemTaxState>((
  ref,
) {
  return ItemTaxNotifier(
    localRepository: ServiceLocator.get<LocalItemTaxRepository>(),
    remoteRepository: ServiceLocator.get<ItemTaxRepository>(),
    webService: ServiceLocator.get<IWebService>(),
    ref: ref,
  );
});

/// Provider for item taxes by item ID (family provider)
final itemTaxesByItemIdProvider = Provider.family<List<ItemTaxModel>, String>((
  ref,
  itemId,
) {
  final items = ref.watch(itemTaxProvider).items;
  return items.where((item) => item.itemId == itemId).toList();
});

/// Provider for item taxes by tax ID (family provider)
final itemTaxesByTaxIdProvider = Provider.family<List<ItemTaxModel>, String>((
  ref,
  taxId,
) {
  final items = ref.watch(itemTaxProvider).items;
  return items.where((item) => item.taxId == taxId).toList();
});

/// Provider to check if a specific item-tax relation exists (family provider)
final itemTaxExistsProvider =
    Provider.family<bool, ({String itemId, String taxId})>((ref, params) {
      final items = ref.watch(itemTaxProvider).items;
      return items.any(
        (item) => item.itemId == params.itemId && item.taxId == params.taxId,
      );
    });

/// Provider for count of taxes per item (family provider)
final taxCountPerItemProvider = Provider.family<int, String>((ref, itemId) {
  final itemTaxes = ref.watch(itemTaxesByItemIdProvider(itemId));
  return itemTaxes.length;
});

/// Provider for count of items per tax (family provider)
final itemCountPerTaxProvider = Provider.family<int, String>((ref, taxId) {
  final itemTaxes = ref.watch(itemTaxesByTaxIdProvider(taxId));
  return itemTaxes.length;
});

/// Provider for TaxModel list by item ID (async family provider)
/// This uses the repository method to get actual TaxModel objects
final taxModelsByItemIdProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  itemId,
) async {
  final notifier = ref.watch(itemTaxProvider.notifier);
  return await notifier.getTaxModelsByItemId(itemId);
});

/// Provider for unique tax IDs by item ID (family provider)
final taxIdsByItemIdProvider = Provider.family<List<String>, String>((
  ref,
  itemId,
) {
  final itemTaxes = ref.watch(itemTaxesByItemIdProvider(itemId));
  return itemTaxes.map((it) => it.taxId ?? '').toList();
});

/// Provider for unique item IDs by tax ID (family provider)
final itemIdsByTaxIdProvider = Provider.family<List<String>, String>((
  ref,
  taxId,
) {
  final itemTaxes = ref.watch(itemTaxesByTaxIdProvider(taxId));
  return itemTaxes.map((it) => it.itemId ?? '').toList();
});
