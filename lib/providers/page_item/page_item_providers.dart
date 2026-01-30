import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/enum/polymorphic_enum.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/page/page_model.dart';
import 'package:mts/data/models/page_item/page_item_model.dart';
import 'package:mts/data/repositories/local/local_page_item_repository_impl.dart';
import 'package:mts/domain/repositories/local/page_item_repository.dart';
import 'package:mts/providers/page/page_providers.dart';
import 'package:mts/providers/page_item/page_item_state.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/page_item/page_item_list_response_model.dart';
import 'package:mts/domain/repositories/local/page_repository.dart';
import 'package:mts/domain/repositories/remote/page_item_repository.dart';

/// StateNotifier for PageItem domain
///
/// Migrated from: page_item_facade_impl.dart
class PageItemNotifier extends StateNotifier<PageItemState> {
  final LocalPageItemRepository _localRepository;
  final LocalPageRepository _localPageRepository;
  final PageItemRepository _remoteRepository;
  final IWebService _webService;
  final Ref _ref;

  PageItemNotifier({
    required LocalPageItemRepository localRepository,
    required PageItemRepository remoteRepository,
    required LocalPageRepository localPageRepository,
    required IWebService webService,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _localPageRepository = localPageRepository,
       _webService = webService,
       _ref = ref,
       super(const PageItemState());

  // ============================================================
  // CRUD Operations - Optimized for Riverpod
  // ============================================================

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<PageItemModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<PageItemModel>.from(state.items);
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
  Future<List<PageItemModel>> getListPageItemModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListPageItemModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<PageItemModel> list) async {
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
  Future<PageItemModel?> getPageItemModelById(String itemId) async {
    try {
      final items = await _localRepository.getListPageItemModel();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => PageItemModel(),
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
    List<PageItemModel> newData, {
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
    List<PageItemModel> list, {
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
        final existingItems = List<PageItemModel>.from(state.items);
        for (final item in list) {
          final index = existingItems.indexWhere((e) => e.id == item.id);
          if (index >= 0) {
            existingItems[index] = item;
          } else {
            existingItems.add(item);
          }
        }
        state = state.copyWith(items: existingItems, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get type (old notifier getter)
  String get getType => state.type;

  /// Get list of page items from state (old notifier getter)
  List<PageItemModel> get getListPageItem => state.items;

  /// Get list of pages from PageFacade (old notifier getter)
  List<PageModel> get getListPage {
    final pageNotifier = _ref.read(pageProvider.notifier);
    return pageNotifier.getListPageFromHive();
  }

  /// Get last page ID (old notifier getter)
  String? get getLastPageId => state.lastPageId;

  /// Get current page ID (old notifier getter)
  String? get getCurrentPageId => state.currentPageId;

  /// Set page item type and create new page item
  Future<void> setPageItemType({
    required String type,
    required String? pageId,
    required String pageItemableId,
    required int sort,
  }) async {
    final pageItemNotifier = _ref.read(pageItemProvider.notifier);
    final autoIncrement = IdUtils.generateUUID().toString();
    final now = DateTime.now();

    prints("getListPageItem.map((e) => e.toString()).join('\\n')");
    prints(getListPageItem.map((e) => e.toString()).join('\n'));

    final newPageItem = PageItemModel(
      id: autoIncrement,
      pageId: pageId,
      pageItemableType: type,
      pageItemableId: pageItemableId,
      sort: sort,
      createdAt: now,
      updatedAt: now,
    );

    await deleteItemsWithSameSortAndPageId(sort, pageId);

    // add to local db, will be use when user logout
    await pageItemNotifier.upsertBulk([newPageItem]);

    // Update state
    final currentItems = List<PageItemModel>.from(state.items);
    currentItems.add(newPageItem);
    state = state.copyWith(items: currentItems);
  }

  /// Remove duplicates by sort and page ID
  List<PageItemModel> removeDuplicatesBySortAndPageId(
    List<PageItemModel> list,
  ) {
    Map<String, PageItemModel> uniqueItems = {};

    for (PageItemModel pageItem in list) {
      // skip item with null sort or page id
      if (pageItem.sort == null || pageItem.pageId == null) {
        String key = pageItem.id ?? IdUtils.generateUUID();
        uniqueItems[key] = pageItem;
        continue;
      }

      // create a key tht combine sort and page id
      String key = '${pageItem.sort}_${pageItem.pageId}';

      // if this key doesnt exist or current page item is more recently updated
      if (!uniqueItems.containsKey(key) ||
          (pageItem.updatedAt?.isAfter(
                uniqueItems[key]!.updatedAt ?? DateTime.now(),
              ) ??
              false)) {
        uniqueItems[key] = pageItem;
      }
    }
    return uniqueItems.values.toList();
  }

  /// Delete items with same sort and page ID
  Future<void> deleteItemsWithSameSortAndPageId(
    int? sortValue,
    String? pageIdValue,
  ) async {
    if (sortValue == null || pageIdValue == null) {
      return Future.value();
    }

    final pageItemNotifier = _ref.read(pageItemProvider.notifier);
    final listCurrItem =
        getListPageItem
            .where(
              (element) =>
                  element.sort == sortValue && element.pageId == pageIdValue,
            )
            .toList();

    prints("listCurrItem.map((e) => e.toString()).join('\\n')");
    prints(listCurrItem.map((e) => e.toString()).join('\n'));

    for (PageItemModel pageItem in listCurrItem) {
      await pageItemNotifier.delete(pageItem.id!, isInsertToPending: true);
    }

    // Update state by removing deleted items
    final idsToRemove = listCurrItem.map((item) => item.id).toSet();
    final updatedItems =
        state.items.where((item) => !idsToRemove.contains(item.id)).toList();
    state = state.copyWith(items: updatedItems);
  }

  /// Update page model in database and state
  Future<void> updatePageModel(PageModel updatedPageModel) async {
    final pageNotifier = _ref.read(pageProvider.notifier);
    final listPage = getListPage;

    int index = listPage.indexWhere((page) => page.id == updatedPageModel.id);

    if (index != -1) {
      // Update the model in the database
      await pageNotifier.update(updatedPageModel);
      // Note: listPage is from facade, so it's already updated
    }
  }

  /// Remove page and all associated page items
  Future<void> removePage(PageModel pageModel) async {
    final pageNotifier = _ref.read(pageProvider.notifier);
    final list = getListPage;

    int index = list.indexWhere((page) => page.id == pageModel.id);

    // cannot delete if only one page
    if (list.length <= 1) {
      return;
    }

    if (index >= 0) {
      // Determine next page to select BEFORE deletion
      int nextIndex = index;
      if (index > 0) {
        // If deleted item was not first, select previous item
        nextIndex = index - 1;
      }
      // If deleted item was first (index == 0), keep index at 0 (next item will shift into position)

      await Future.wait([
        pageNotifier.delete(pageModel.id!), // Delete from DB
        removePageItemByPageId(pageModel.id!),
      ]);

      // Get fresh list after DB deletion
      final updatedList = getListPage;

      if (updatedList.isNotEmpty &&
          nextIndex >= 0 &&
          nextIndex < updatedList.length) {
        final newPageId = updatedList[nextIndex].id!;
        setCurrentPageId(newPageId);
        setLastPageId(newPageId);
      }
    }
  }

  /// Remove PageItemModel using where conditions
  Future<void> removePageItem({required PageItemModel pageItemModel}) async {
    final pageItemNotifier = _ref.read(pageItemProvider.notifier);

    Map<String, dynamic> conditions = {
      LocalPageItemRepositoryImpl.pageItemableType:
          pageItemModel.pageItemableType,
      LocalPageItemRepositoryImpl.pageItemableId: pageItemModel.pageItemableId,
      LocalPageItemRepositoryImpl.sort: pageItemModel.sort,
      LocalPageItemRepositoryImpl.pageId: pageItemModel.pageId,
    };

    // Call the delete function
    await pageItemNotifier.deleteDbWithConditions(
      LocalPageItemRepositoryImpl.tableName,
      conditions,
    );

    // Update state by removing matching items
    final updatedItems =
        state.items.where((item) {
          return !(item.pageItemableType == pageItemModel.pageItemableType &&
              item.pageItemableId == pageItemModel.pageItemableId &&
              item.sort == pageItemModel.sort &&
              item.pageId == pageItemModel.pageId);
        }).toList();
    state = state.copyWith(items: updatedItems);
  }

  /// Get page items by page ID
  List<PageItemModel> getPageItemsByPageId(String? pageId) {
    return getListPageItem.where((item) => item.pageId == pageId).toList();
  }

  /// Get page item model by sort index and current page ID
  PageItemModel getPageItemModelBySort(int index) {
    PageItemModel? pageItemsList = getListPageItem.firstWhere((pageItem) {
      return pageItem.sort == index && pageItem.pageId == getCurrentPageId;
    }, orElse: () => PageItemModel());

    return pageItemsList.id != null ? pageItemsList : PageItemModel();
  }

  /// Set current page ID
  void setCurrentPageId(String? newPageId) {
    state = state.copyWith(currentPageId: newPageId);
  }

  /// Set last page ID (to handle when press back from search item)
  void setLastPageId(String newLastPageId) {
    state = state.copyWith(lastPageId: newLastPageId);
  }

  /// Remove all page items by page ID
  Future<void> removePageItemByPageId(String pageId) async {
    final pageItemNotifier = _ref.read(pageItemProvider.notifier);
    final conditions = {LocalPageItemRepositoryImpl.pageId: pageId};

    // get all page item with conditions to use for insert in deleted datas
    List<PageItemModel> listPI = await pageItemNotifier
        .getListPageItemsWithConditions(conditions);

    for (PageItemModel pi in listPI) {
      if (PolymorphicEnum.values.contains(pi.pageItemableType!)) {
        // String? modelName =
        //     pi.pageItemableType == PolymorphicEnum.item
        //         ? ItemModel.modelName
        //         : (pi.pageItemableType == PolymorphicEnum.category
        //             ? CategoryModel.modelName
        //             : null);
      }
    }

    // remove all pageItem from the local db
    await pageItemNotifier.deleteDbWithConditions(
      LocalPageItemRepositoryImpl.tableName,
      conditions,
    );

    // Update state by removing items with matching pageId
    final updatedItems =
        state.items.where((item) => item.pageId != pageId).toList();
    state = state.copyWith(items: updatedItems);
  }

  Future<int> insert(PageItemModel pageItemModel) async {
    return await _localRepository.insert(pageItemModel, true);
  }

  Future<int> update(PageItemModel pageItemModel) async {
    return await _localRepository.update(pageItemModel, true);
  }

  Future<int> deleteDbWithConditions(
    String tableName,
    Map<String, dynamic> conditions, {
    bool isInsertToPending = true,
  }) async {
    return await _localRepository.deleteDbWithConditions(
      tableName,
      conditions,
      isInsertToPending,
    );
  }

  Future<List<PageItemModel>> getListPageItemsWithConditions(
    Map<String, dynamic> conditions,
  ) async {
    return await _localRepository.getListPageItemsWithConditions(conditions);
  }

  Future<List<PageItemModel>> syncFromRemote() async {
    List<PageItemModel> allPageItems = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching page items page $currentPage');
      PageItemListResponseModel responseModel = await _webService.get(
        getPageItemList(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Process items from current page
        List<PageItemModel> pageItems = responseModel.data!;
        for (PageItemModel pageItem in pageItems) {
          if (pageItem.pageItemableType != null) {
            // from api will get like this App\Models\Item
            // then we need to convert to this App/Models/Item
            pageItem.pageItemableType = pageItem.pageItemableType!.replaceAll(
              '\\',
              '/',
            );
          }
        }

        // Add items from current page to the list
        allPageItems.addAll(pageItems);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination PAGE ITEM: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch page items page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allPageItems.length} page items from all pages',
    );
    return allPageItems;
  }

  Resource getPageItemList(String page) {
    return _remoteRepository.getPageItemList(page);
  }

  List<PageItemModel> getListPageItemFromHive() {
    return _localRepository.getListPageItemFromHive();
  }

  Future<void> deleteCorruptPageItems() async {
    List<String> listPageIdsFromPageItems =
        await _localRepository.getAllPageIds();

    List<PageModel> listPageModel = await _localPageRepository.getListPage();
    List<String> pageIdsFromPages = listPageModel.map((p) => p.id!).toList();

    List<String> listPageIds =
        listPageIdsFromPageItems
            .where((id) => !pageIdsFromPages.contains(id))
            .toList();

    for (String pageId in listPageIds) {
      await _localRepository.deletePageItemsByPageId(pageId);
    }
  }
}

/// Provider for sorted items (computed provider)
final sortedPageItemsProvider = Provider<List<PageItemModel>>((ref) {
  final items = ref.watch(pageItemProvider).items;
  final sorted = List<PageItemModel>.from(items);
  sorted.sort((a, b) => (a.sort ?? 0).compareTo(b.sort ?? 0));
  return sorted;
});

/// Provider for pageItem domain
final pageItemProvider = StateNotifierProvider<PageItemNotifier, PageItemState>(
  (ref) {
    return PageItemNotifier(
      localRepository: ServiceLocator.get<LocalPageItemRepository>(),
      remoteRepository: ServiceLocator.get<PageItemRepository>(),
      localPageRepository: ServiceLocator.get<LocalPageRepository>(),
      webService: ServiceLocator.get<IWebService>(),
      ref: ref,
    );
  },
);

/// Provider for pageItem by ID (family provider for indexed lookups)
final pageItemByIdProvider = FutureProvider.family<PageItemModel?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(pageItemProvider.notifier);
  return notifier.getPageItemModelById(id);
});

/// Provider for synchronous page item by ID (from current state)
final pageItemByIdFromStateProvider = Provider.family<PageItemModel?, String>((
  ref,
  id,
) {
  final items = ref.watch(pageItemProvider).items;
  try {
    return items.firstWhere((item) => item.id == id);
  } catch (e) {
    return null;
  }
});

/// Provider for page items by page ID (family provider)
final pageItemsByPageIdProvider = Provider.family<List<PageItemModel>, String>((
  ref,
  pageId,
) {
  final notifier = ref.watch(pageItemProvider.notifier);
  return notifier.getPageItemsByPageId(pageId);
});

/// Provider for page item by sort index and current page ID (family provider)
final pageItemBySortProvider = Provider.family<PageItemModel, int>((ref, sort) {
  final notifier = ref.watch(pageItemProvider.notifier);
  return notifier.getPageItemModelBySort(sort);
});

/// Provider for page items by itemable type (family provider)
final pageItemsByItemableTypeProvider =
    Provider.family<List<PageItemModel>, String>((ref, type) {
      final items = ref.watch(pageItemProvider).items;
      return items.where((item) => item.pageItemableType == type).toList();
    });

/// Provider for page items by itemable ID (family provider)
final pageItemsByItemableIdProvider =
    Provider.family<List<PageItemModel>, String>((ref, itemableId) {
      final items = ref.watch(pageItemProvider).items;
      return items.where((item) => item.pageItemableId == itemableId).toList();
    });

/// Provider for page items by type and page ID (family provider)
final pageItemsByTypeAndPageIdProvider = Provider.family<
  List<PageItemModel>,
  ({String type, String pageId})
>((ref, params) {
  final items = ref.watch(pageItemProvider).items;
  return items
      .where(
        (item) =>
            item.pageItemableType == params.type &&
            item.pageId == params.pageId,
      )
      .toList();
});

/// Provider to check if a page item exists by ID
final pageItemExistsProvider = Provider.family<bool, String>((ref, id) {
  final items = ref.watch(pageItemProvider).items;
  return items.any((item) => item.id == id);
});

/// Provider for total page item count
final pageItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(pageItemProvider).items;
  return items.length;
});

/// Provider for count of page items per page (family provider)
final pageItemCountPerPageProvider = Provider.family<int, String>((
  ref,
  pageId,
) {
  final pageItems = ref.watch(pageItemsByPageIdProvider(pageId));
  return pageItems.length;
});

/// Provider for current page ID
final currentPageIdProvider = Provider<String?>((ref) {
  final notifier = ref.watch(pageItemProvider.notifier);
  return notifier.getCurrentPageId;
});

/// Provider for last page ID
final lastPageIdProvider = Provider<String?>((ref) {
  final notifier = ref.watch(pageItemProvider.notifier);
  return notifier.getLastPageId;
});

/// Provider for page items sorted by sort field
final pageItemsSortedBySortProvider = Provider<List<PageItemModel>>((ref) {
  final items = ref.watch(pageItemProvider).items;
  final sorted = List<PageItemModel>.from(items);
  sorted.sort((a, b) => (a.sort ?? 0).compareTo(b.sort ?? 0));
  return sorted;
});

/// Provider for page items by page ID sorted by sort field (family provider)
final pageItemsByPageIdSortedProvider =
    Provider.family<List<PageItemModel>, String>((ref, pageId) {
      final pageItems = ref.watch(pageItemsByPageIdProvider(pageId));
      final sorted = List<PageItemModel>.from(pageItems);
      sorted.sort((a, b) => (a.sort ?? 0).compareTo(b.sort ?? 0));
      return sorted;
    });
