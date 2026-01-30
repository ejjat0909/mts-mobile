import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/category_tax/category_tax_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/domain/repositories/local/category_tax_repository.dart';
import 'package:mts/providers/category_tax/category_tax_state.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/category_tax/category_tax_list_response_model.dart';
import 'package:mts/domain/repositories/remote/category_tax_repository.dart';

/// StateNotifier for CategoryTax domain
///
/// Migrated from: category_tax_facade_impl.dart
class CategoryTaxNotifier extends StateNotifier<CategoryTaxState> {
  final LocalCategoryTaxRepository _localRepository;
  final CategoryTaxRepository _remoteRepository;
  final IWebService _webService;

  CategoryTaxNotifier({
    required LocalCategoryTaxRepository localRepository,
    required CategoryTaxRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const CategoryTaxState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<CategoryTaxModel> list, {
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
  Future<List<CategoryTaxModel>> getListCategoryTax() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListCategoryTax();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<CategoryTaxModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        // Use composite key for pivot table
        final keysToDelete =
            list.map((e) => '${e.categoryId}_${e.taxId}').toSet();
        final updatedItems =
            state.items
                .where(
                  (e) => !keysToDelete.contains('${e.categoryId}_${e.taxId}'),
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

  /// Delete category taxes by category ID
  Future<int> deleteByCategoryId(
    String categoryId, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteByColumnName(
        'category_id',
        categoryId,
        isInsertToPending,
      );

      if (result > 0) {
        final updatedItems =
            state.items.where((e) => e.categoryId != categoryId).toList();
        state = state.copyWith(items: updatedItems);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Find category taxes by category ID
  Future<List<CategoryTaxModel>> getTaxesByCategoryId(String categoryId) async {
    try {
      final items = await _localRepository.getListCategoryTax();
      return items.where((item) => item.categoryId == categoryId).toList();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get TaxModel list for a category
  Future<List<dynamic>> getTaxModelsByCategoryId(String categoryId) async {
    try {
      return await _localRepository.getTaxModelsByCategoryId(categoryId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<CategoryTaxModel> newData, {
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
    List<CategoryTaxModel> list, {
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
      final items = await _localRepository.getListCategoryTax();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add or update a single item in state (for sync handlers)
  void addOrUpdate(CategoryTaxModel categoryTax) {
    final index = state.items.indexWhere(
      (ct) =>
          ct.categoryId == categoryTax.categoryId &&
          ct.taxId == categoryTax.taxId,
    );

    final updatedItems = List<CategoryTaxModel>.from(state.items);
    if (index != -1) {
      updatedItems[index] = categoryTax;
    } else {
      updatedItems.add(categoryTax);
    }
    state = state.copyWith(items: updatedItems);
  }

  /// Remove an item by composite key (for sync handlers)
  void remove(String categoryId, String taxId) {
    final updatedItems =
        state.items
            .where(
              (item) => !(item.categoryId == categoryId && item.taxId == taxId),
            )
            .toList();
    state = state.copyWith(items: updatedItems);
  }

  /// Get list of tax models from category tax list (old notifier method)
  List<TaxModel> getListTaxModelFromCategoryTaxList(
    List<TaxModel> listReceiveTaxModel,
    ItemModel itemModel,
    TaxModel taxModel,
  ) {
    final categoryId = itemModel.categoryId;
    if (categoryId == null) {
      return [];
    }
    final listCategoryTax = state.items;
    final taxIds =
        listCategoryTax
            .where((ct) => ct.categoryId == categoryId)
            .map((ct) => ct.taxId)
            .toList();
    final listTaxIds = taxIds.where((e) => e == taxModel.id).toList();
    return listReceiveTaxModel
        .where((tax) => listTaxIds.contains(tax.id))
        .toList();
  }

  Future<int> insert(CategoryTaxModel model) async {
    return await _localRepository.upsert(model, true);
  }

  Future<int> update(CategoryTaxModel categoryTaxModel) async {
    return await _localRepository.upsert(categoryTaxModel, true);
  }

  Future<int> delete(String id) async {
    // The LocalCategoryTaxRepository uses deletePivot which requires a CategoryTaxModel
    // Since we only have an ID string, we need to parse it to get categoryId and taxId
    // Assuming the ID is in the format "categoryId_taxId"
    List<String> parts = id.split('_');
    if (parts.length != 2) {
      prints('Invalid ID format for category tax deletion: $id');
      return 0;
    }

    CategoryTaxModel model = CategoryTaxModel(
      categoryId: parts[0],
      taxId: parts[1],
    );

    return await _localRepository.deletePivot(model, true);
  }

  Future<List<CategoryTaxModel>> getListCategoryTaxModel() async {
    return await _localRepository.getListCategoryTax();
  }

  Future<List<CategoryTaxModel>> syncFromRemote() async {
    List<CategoryTaxModel> allCategoryTaxes = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching category taxes page $currentPage');
      CategoryTaxListResponseModel responseModel = await _webService.get(
        getCategoryTaxListPaginated(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Process category taxes from current page
        List<CategoryTaxModel> pageCategoryTaxes = responseModel.data!;

        // Add category taxes from current page to the list
        allCategoryTaxes.addAll(pageCategoryTaxes);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination CATEGORY TAX: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch category taxes page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allCategoryTaxes.length} category taxes from all pages',
    );
    return allCategoryTaxes;
  }

  Resource getCategoryTaxListPaginated(String page) {
    return _remoteRepository.getCategoryTaxListPaginated(page);
  }

  Future<int> deleteByColumnName(
    String columnName,
    dynamic value, {
    required bool isInsertToPending,
  }) async {
    return await _localRepository.deleteByColumnName(
      columnName,
      value,
      isInsertToPending,
    );
  }
}

/// Provider for sorted items (computed provider)
final sortedCategoryTaxsProvider = Provider<List<CategoryTaxModel>>((ref) {
  final items = ref.watch(categoryTaxProvider).items;
  final sorted = List<CategoryTaxModel>.from(items);
  sorted.sort((a, b) => (a.categoryId ?? '').compareTo(b.categoryId ?? ''));
  return sorted;
});

/// Provider for categoryTax domain
final categoryTaxProvider =
    StateNotifierProvider<CategoryTaxNotifier, CategoryTaxState>((ref) {
      return CategoryTaxNotifier(
        localRepository: ServiceLocator.get<LocalCategoryTaxRepository>(),
        remoteRepository: ServiceLocator.get<CategoryTaxRepository>(),
        webService: ServiceLocator.get<IWebService>(),
      );
    });

/// Provider for category taxes by category ID (family provider)
final categoryTaxesByCategoryIdProvider =
    Provider.family<List<CategoryTaxModel>, String>((ref, categoryId) {
      final items = ref.watch(categoryTaxProvider).items;
      return items.where((item) => item.categoryId == categoryId).toList();
    });
