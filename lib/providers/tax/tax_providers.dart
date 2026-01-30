import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/domain/repositories/local/tax_repository.dart';
import 'package:mts/providers/tax/tax_state.dart';
import 'dart:convert';
import 'package:mts/core/enum/tax_option_enum.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/tax/tax_list_response_model.dart';
import 'package:mts/domain/repositories/remote/tax_repository.dart';
import 'package:mts/providers/category_tax/category_tax_providers.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';
import 'package:mts/providers/item_tax/item_tax_providers.dart';
import 'package:mts/providers/order_option_tax/order_option_tax_providers.dart';
import 'package:mts/providers/outlet_tax/outlet_tax_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';

/// StateNotifier for Tax domain
///
/// Migrated from: tax_facade_impl.dart
class TaxNotifier extends StateNotifier<TaxState> {
  final LocalTaxRepository _localRepository;
  final TaxRepository _remoteRepository;
  final IWebService _webService;
  final Ref _ref;

  TaxNotifier({
    required LocalTaxRepository localRepository,
    required TaxRepository remoteRepository,
    required IWebService webService,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _ref = ref,
       super(const TaxState());

  // ============================================================
  // CRUD Operations - Optimized for Riverpod
  // ============================================================

  /// Insert a single item into local storage
  Future<int> insert(TaxModel model, {bool isInsertToPending = true}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(
        model,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        final updatedItems = List<TaxModel>.from(state.items)..add(model);
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
  Future<int> update(TaxModel model, {bool isInsertToPending = true}) async {
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
    List<TaxModel> list, {
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
  Future<List<TaxModel>> getListTaxModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListTaxModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<TaxModel> list) async {
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
  Future<TaxModel?> getTaxModelById(String itemId) async {
    try {
      final items = await _localRepository.getListTaxModel();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => TaxModel(),
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
    List<TaxModel> newData, {
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
    List<TaxModel> list, {
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
    await getListTaxModel();
  }

  // ============================================================
  // UI State Management Methods (from old TaxNotifier)
  // ============================================================

  /// Get tax list (getter for compatibility)
  List<TaxModel> get getTaxList => state.items;

  /// Set the entire tax list
  void setTaxList(List<TaxModel> list) {
    state = state.copyWith(items: list);
  }

  /// Add or update multiple taxes in the list
  void addOrUpdateList(List<TaxModel> list) {
    final currentItems = List<TaxModel>.from(state.items);

    for (TaxModel tax in list) {
      int index = currentItems.indexWhere((element) => element.id == tax.id);

      if (index != -1) {
        // if found, replace existing item with the new one
        currentItems[index] = tax;
      } else {
        // not found
        currentItems.add(tax);
      }
    }

    state = state.copyWith(items: currentItems);
  }

  /// Add or update a single tax
  void addOrUpdate(TaxModel tax) {
    final currentItems = List<TaxModel>.from(state.items);
    int index = currentItems.indexWhere((t) => t.id == tax.id);

    if (index != -1) {
      // if found, replace existing item with the new one
      currentItems[index] = tax;
    } else {
      // not found
      currentItems.add(tax);
    }

    state = state.copyWith(items: currentItems);
  }

  /// Remove a tax by ID
  void remove(String taxId) {
    final currentItems = List<TaxModel>.from(state.items);
    currentItems.removeWhere((tax) => tax.id == taxId);
    state = state.copyWith(items: currentItems);
  }

  double getRateById(String id) {
    final listTax = state.items;

    if (listTax.isEmpty) {
      return 0.0;
    }

    TaxModel? taxModel = listTax.firstWhere(
      (tax) => tax.id == id,
      orElse: () => TaxModel(),
    );

    if (taxModel.id != null) {
      return taxModel.rate!; // dekat back office wajib letak rate ex: 3%
    } else {
      return 0.0;
    }
  }

  Future<List<double>> getRatesByTaxIds(List<String> idTaxes) async {
    return await _localRepository.getRatesByTaxIds(idTaxes);
  }

  Future<List<TaxModel>> syncFromRemote() async {
    List<TaxModel> allTaxes = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching taxes page $currentPage');
      TaxListResponseModel responseModel = await _webService.get(
        getRemoteTaxList(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Add taxes from current page to the list
        allTaxes.addAll(responseModel.data!);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination TAX: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch taxes page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints('Fetched a total of ${allTaxes.length} taxes from all pages');
    return allTaxes;
  }

  Resource getRemoteTaxList(String page) {
    return _remoteRepository.getTaxList(page);
  }

  List<TaxModel> ensureUniqueTaxList(List<TaxModel> listTax) {
    Set<String> seenIds = {}; // Set to track unique ids
    List<TaxModel> uniqueList = [];

    for (TaxModel tax in listTax) {
      if (!seenIds.contains(tax.id)) {
        seenIds.add(tax.id!); // Add the id to the set
        uniqueList.add(tax); // Add the tax to the unique list
      }
      // If the id is already in the set, it will not be added again
    }

    return uniqueList;
  }

  Future<List<TaxModel>> getTaxModelsByItemId(String idItem) async {
    return await _localRepository.getTaxModelsByItemId(idItem);
  }

  List<TaxModel> getAllTaxModelsForThatItem(
    ItemModel itemModel,
    List<TaxModel> taxModels,
  ) {
    final saleItemsState = _ref.read(saleItemProvider);
    final featureCompanyNotifier = _ref.read(featureCompanyProvider.notifier);
    final isOrderOptionActive = featureCompanyNotifier.isOrderOptionActive();

    // Use Riverpod providers for all tax notifiers
    final orderOptionTaxNotifier = _ref.read(orderOptionTaxProvider.notifier);
    final outletTaxNotifier = _ref.read(outletTaxProvider.notifier);
    final categoryTaxNotifier = _ref.read(categoryTaxProvider.notifier);
    final itemTaxNotifier = _ref.read(itemTaxProvider.notifier);

    final OrderOptionModel? orderOptionModel = saleItemsState.orderOptionModel;

    // Get tax list from Riverpod provider instead of ChangeNotifier
    List<TaxModel> listOriginTaxModel = _ref.read(taxProvider).items;
    List<TaxModel> listTaxFromOutletTax = [];
    List<TaxModel> listTaxFromOrderOptionTax = [];
    List<TaxModel> listTaxFromItemTax = [];
    List<TaxModel> listTaxFromCategoryTax = [];
    bool taxApplied = false;

    // 1. check based on outlet
    // 2. check based on tax option
    // 3. check based on order option
    listTaxFromOutletTax = outletTaxNotifier.getListTaxModelFromOutletTaxList(
      listOriginTaxModel,
    );

    prints('OUTLET TAXES ${listTaxFromOutletTax.length}');
    for (TaxModel tax in listTaxFromOutletTax) {
      if (tax.option == TaxOptionEnum.ToSelectedItems) {
        listTaxFromItemTax = itemTaxNotifier.getListTaxModelFromItemTaxList(
          listTaxFromOutletTax,
          itemModel,
          tax,
        );

        taxApplied = listTaxFromItemTax.isNotEmpty;
        prints('ITEM TAXES $taxApplied');
      }
      if (tax.option == TaxOptionEnum.ToSelectedCategories) {
        listTaxFromCategoryTax = categoryTaxNotifier
            .getListTaxModelFromCategoryTaxList(
              listTaxFromOutletTax,
              itemModel,
              tax,
            );

        taxApplied = listTaxFromCategoryTax.isNotEmpty;
        prints('CATEGORY TAXES $taxApplied');
      }

      taxApplied = switch (tax.option) {
        TaxOptionEnum.ToAllItems => true,
        _ => taxApplied, // keeps current value for other cases
      };
      if (tax.isOrderOptionChecked != null && tax.isOrderOptionChecked!) {
        // list from order option

        if (isOrderOptionActive) {
          listTaxFromOrderOptionTax = orderOptionTaxNotifier
              .getListTaxModelFromOrderOptionTaxList(
                listTaxFromOutletTax,
                orderOptionModel ?? OrderOptionModel(id: '', name: ''),
                tax,
              );

          taxApplied = listTaxFromOrderOptionTax.isNotEmpty;
        } else {
          // auto false because order option is disabled
          taxApplied = false;
        }
      }

      taxApplied = switch (tax.option) {
        TaxOptionEnum.DontApply => false,

        _ => taxApplied, // keeps current value for other cases
      };

      prints('APPLIED TAXES ${tax.name}: $taxApplied');
      if (taxApplied) {
        taxModels.add(tax);
      }
    }

    prints('TAX MODELSSS ');
    prints(taxModels.map((e) => e.rate).toList());

    return taxModels;
  }

  List<TaxModel> decodeTaxList(String jsonString) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => TaxModel.fromJson(json)).toList();
    } catch (e) {
      prints('Error decoding tax list: $e');
      return [];
    }
  }
}

/// Provider for sorted items (computed provider)
final sortedTaxsProvider = Provider<List<TaxModel>>((ref) {
  final items = ref.watch(taxProvider).items;
  final sorted = List<TaxModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for tax domain
final taxProvider = StateNotifierProvider<TaxNotifier, TaxState>((ref) {
  return TaxNotifier(
    localRepository: ServiceLocator.get<LocalTaxRepository>(),
    remoteRepository: ServiceLocator.get<TaxRepository>(),
    webService: ServiceLocator.get<IWebService>(),
    ref: ref,
  );
});

/// Provider for tax by ID (family provider for indexed lookups)
final taxByIdProvider = FutureProvider.family<TaxModel?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(taxProvider.notifier);
  return notifier.getTaxModelById(id);
});
