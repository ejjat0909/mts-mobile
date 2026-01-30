import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/category_discount/category_discount_model.dart';
import 'package:mts/domain/repositories/local/category_discount_repository.dart';
import 'package:mts/providers/category_discount/category_discount_state.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/category_discount/category_discount_list_response_model.dart';
import 'package:mts/domain/repositories/remote/category_discount_repository.dart';

/// StateNotifier for CategoryDiscount domain
///
/// Migrated from: category_discount_facade_impl.dart
class CategoryDiscountNotifier extends StateNotifier<CategoryDiscountState> {
  final LocalCategoryDiscountRepository _localRepository;
  final CategoryDiscountRepository _remoteRepository;
  final IWebService _webService;

  CategoryDiscountNotifier({
    required LocalCategoryDiscountRepository localRepository,
    required CategoryDiscountRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const CategoryDiscountState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<CategoryDiscountModel> list, {
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
  Future<List<CategoryDiscountModel>> getListCategoryDiscount() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListCategoryDiscount();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<CategoryDiscountModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        // Use composite key for pivot table
        final keysToDelete =
            list.map((e) => '${e.categoryId}_${e.discountId}').toSet();
        final updatedItems =
            state.items
                .where(
                  (e) =>
                      !keysToDelete.contains('${e.categoryId}_${e.discountId}'),
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

  /// Delete category discounts by category ID
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

  /// Find category discounts by category ID
  Future<List<CategoryDiscountModel>> getDiscountsByCategoryId(
    String categoryId,
  ) async {
    try {
      final items = await _localRepository.getListCategoryDiscount();
      return items.where((item) => item.categoryId == categoryId).toList();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get DiscountModel list for a category
  Future<List<dynamic>> getDiscountModelsByCategoryId(String categoryId) async {
    try {
      return await _localRepository.getDiscountModelsByCategoryId(categoryId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<CategoryDiscountModel> newData, {
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
    List<CategoryDiscountModel> list, {
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
      final items = await _localRepository.getListCategoryDiscount();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add or update a single item in state (for sync handlers)
  void addOrUpdate(CategoryDiscountModel categoryDiscount) {
    final index = state.items.indexWhere(
      (d) =>
          d.categoryId == categoryDiscount.categoryId &&
          d.discountId == categoryDiscount.discountId,
    );

    final updatedItems = List<CategoryDiscountModel>.from(state.items);
    if (index != -1) {
      updatedItems[index] = categoryDiscount;
    } else {
      updatedItems.add(categoryDiscount);
    }
    state = state.copyWith(items: updatedItems);
  }

  /// Remove an item by composite key (for sync handlers)
  void remove(String categoryId, String discountId) {
    final updatedItems =
        state.items
            .where(
              (item) =>
                  !(item.categoryId == categoryId &&
                      item.discountId == discountId),
            )
            .toList();
    state = state.copyWith(items: updatedItems);
  }

  Future<int> upsert(
    CategoryDiscountModel categoryDiscountModel, {
    required bool isInsertToPending,
  }) async {
    return await _localRepository.upsert(
      categoryDiscountModel,
      isInsertToPending,
    );
  }

  Future<int> deletePivot(
    CategoryDiscountModel categoryDiscountModel, {
    required bool isInsertToPending,
  }) async {
    return await _localRepository.deletePivot(
      categoryDiscountModel,
      isInsertToPending,
    );
  }

  Future<List<CategoryDiscountModel>> syncFromRemote() async {
    List<CategoryDiscountModel> allCategoryDiscounts = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching category discounts page $currentPage');
      CategoryDiscountListResponseModel responseModel = await _webService.get(
        getCategoryDiscountListPaginated(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Process category discounts from current page
        List<CategoryDiscountModel> pageCategoryDiscounts = responseModel.data!;

        // Add category discounts from current page to the list
        allCategoryDiscounts.addAll(pageCategoryDiscounts);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination CATEGORY DISCOUNT: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch category discounts page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allCategoryDiscounts.length} category discounts from all pages',
    );
    return allCategoryDiscounts;
  }

  Resource getCategoryDiscountListPaginated(String page) {
    return _remoteRepository.getCategoryDiscountListPaginated(page);
  }

  //
  // Future<bool> upsertBulk(
  //   List<CategoryDiscountModel> list, {
  //   bool isInsertToPending = true,
  // }) async {
  //   return await _localRepository.upsertBulk(
  //     list,
  //     isInsertToPending: isInsertToPending,
  //   );
  // }

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
final sortedCategoryDiscountsProvider = Provider<List<CategoryDiscountModel>>((
  ref,
) {
  final items = ref.watch(categoryDiscountProvider).items;
  final sorted = List<CategoryDiscountModel>.from(items);
  sorted.sort((a, b) => (a.categoryId ?? '').compareTo(b.categoryId ?? ''));
  return sorted;
});

/// Provider for categoryDiscount domain
final categoryDiscountProvider =
    StateNotifierProvider<CategoryDiscountNotifier, CategoryDiscountState>((
      ref,
    ) {
      return CategoryDiscountNotifier(
        localRepository: ServiceLocator.get<LocalCategoryDiscountRepository>(),
        remoteRepository: ServiceLocator.get<CategoryDiscountRepository>(),
        webService: ServiceLocator.get<IWebService>(),
      );
    });

/// Provider for category discounts by category ID (family provider)
final categoryDiscountsByCategoryIdProvider =
    Provider.family<List<CategoryDiscountModel>, String>((ref, categoryId) {
      final items = ref.watch(categoryDiscountProvider).items;
      return items.where((item) => item.categoryId == categoryId).toList();
    });
