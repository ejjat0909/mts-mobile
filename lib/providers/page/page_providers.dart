import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/page/page_model.dart';
import 'package:mts/domain/repositories/local/page_repository.dart';
import 'package:mts/providers/page/page_state.dart';
import 'package:flutter/material.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/page/page_list_response_model.dart';
import 'package:mts/domain/repositories/remote/page_repository.dart';
import 'package:mts/providers/page_item/page_item_providers.dart';

/// StateNotifier for Page domain
///
/// Migrated from: page_facade_impl.dart
class PageNotifier extends StateNotifier<PageState> {
  final LocalPageRepository _localRepository;
  final PageRepository _remoteRepository;
  final IWebService _webService;
  final Ref _ref;

  PageNotifier({
    required LocalPageRepository localRepository,
    required PageRepository remoteRepository,
    required IWebService webService,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _ref = ref,
       super(const PageState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<PageModel> list, {
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
  Future<List<PageModel>> getListPage() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListPage();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Get first page from local storage
  Future<PageModel> getFirstPage() async {
    try {
      return await _localRepository.getFirstPage();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return PageModel();
    }
  }

  /// Get list of pages from Hive (synchronous)
  List<PageModel> getListPageFromHive() {
    try {
      return _localRepository.getListPageFromHive();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<PageModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        final idsToDelete = list.map((e) => e.id).toSet();
        final updatedItems =
            state.items.where((e) => !idsToDelete.contains(e.id)).toList();
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

  /// Delete a single item by ID
  Future<int> delete(String id, {bool isInsertToPending = true}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.delete(
        id,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        final updatedItems = state.items.where((e) => e.id != id).toList();
        state = state.copyWith(items: updatedItems);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Find an item by its ID
  Future<PageModel?> getPageModelById(String itemId) async {
    try {
      final items = await _localRepository.getListPage();

      try {
        final item = items.firstWhere((item) => item.id == itemId);
        return item;
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
    List<PageModel> newData, {
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
    List<PageModel> list, {
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
        final existingItems = List<PageModel>.from(state.items);
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

  /// Insert or update a single item
  Future<int> insert(
    PageModel pageModel, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(
        pageModel,
        isInsertToPending,
      );

      if (result > 0) {
        final updatedItems = [...state.items, pageModel];
        state = state.copyWith(items: updatedItems);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Update an existing item
  Future<int> update(
    PageModel pageModel, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.update(
        pageModel,
        isInsertToPending,
      );

      if (result > 0) {
        final updatedItems =
            state.items.map((item) {
              return item.id == pageModel.id ? pageModel : item;
            }).toList();
        state = state.copyWith(items: updatedItems);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Refresh items from repository (explicit reload)
  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListPage();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> removePage(PageModel pageModel, BuildContext context) async {
    final pageItemNotifier = _ref.read(pageItemProvider.notifier);

    final listPages = state.items;

    // find index from local DB that same with pageModel

    int index = listPages.indexWhere((page) => page.id == pageModel.id);

    // cannot delete if have only 1 page
    if (listPages.length <= 1) {
      // Cannot delete if there's only one page
      return false;
    }

    // remove pageModel where id == pageModel.id
    // find index from local DB that same with pageModel

    if (index >= 0) {
      listPages.removeAt(index);
      // remove page model from local db
      await delete(pageModel.id!);

      // remove all pageItem from the local list
      await pageItemNotifier.removePageItemByPageId(pageModel.id!);

      //  prints('index: $index');
      // integer index to change page
      if (index > 0) {
        // when page is in the middle
        index = index - 1;
      }
      final newPageId = listPages[index].id!;
      pageItemNotifier.setCurrentPageId(newPageId);
      pageItemNotifier.setLastPageId(newPageId);

      return true;
    }
    return false;
  }

  Future<List<PageModel>> syncFromRemote() async {
    // OutletModel outletModel = ServiceLocator.get<OutletModel>();
    List<PageModel> allPages = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching pages page $currentPage');
      PageListResponseModel responseModel = await _webService.get(
        getPageList(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Process items from current page
        List<PageModel> pageModels = responseModel.data!;
        // filter by outletId
        // pageModels =
        //     pageModels.where((page) => page.outletId == outletModel.id).toList();

        // Add items from current page to the list
        allPages.addAll(pageModels);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination PAGES: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch pages page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints('Fetched a total of ${allPages.length} pages from all pages');
    return allPages;
  }

  Resource getPageList(String page) {
    return _remoteRepository.getPageList(page);
  }
}

/// Provider for sorted items (computed provider)
final sortedPagesProvider = Provider<List<PageModel>>((ref) {
  final items = ref.watch(pageProvider).items;
  final sorted = List<PageModel>.from(items);
  sorted.sort((a, b) {
    if (a.createdAt == null && b.createdAt == null) return 0;
    if (a.createdAt == null) return 1;
    if (b.createdAt == null) return -1;
    return b.createdAt!.compareTo(a.createdAt!);
  });
  return sorted;
});

/// Provider for page domain
final pageProvider = StateNotifierProvider<PageNotifier, PageState>((ref) {
  return PageNotifier(
    localRepository: ServiceLocator.get<LocalPageRepository>(),
    remoteRepository: ServiceLocator.get<PageRepository>(),
    webService: ServiceLocator.get<IWebService>(),
    ref: ref,
  );
});

/// Provider for page by ID (family provider for indexed lookups)
final pageByIdProvider = Provider.family<PageModel?, String>((ref, id) {
  final items = ref.watch(pageProvider).items;
  try {
    return items.firstWhere((item) => item.id == id);
  } catch (e) {
    return null;
  }
});
