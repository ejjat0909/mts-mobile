import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/domain/repositories/local/order_option_repository.dart';
import 'package:mts/providers/order_option/order_option_state.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/order_option/order_option_list_response_model.dart';
import 'package:mts/domain/repositories/remote/order_option_repository.dart';

/// StateNotifier for OrderOption domain
///
/// Migrated from: order_option_facade_impl.dart
class OrderOptionNotifier extends StateNotifier<OrderOptionState> {
  final LocalOrderOptionRepository _localRepository;
  final OrderOptionRepository _remoteRepository;
  final IWebService _webService;
  final Ref _ref;

  OrderOptionNotifier({
    required LocalOrderOptionRepository localRepository,
    required OrderOptionRepository remoteRepository,
    required IWebService webService,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _ref = ref,
       super(const OrderOptionState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<OrderOptionModel> list, {
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
  Future<List<OrderOptionModel>> getListOrderOptionModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListOrderOptionModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<OrderOptionModel> list) async {
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
  Future<OrderOptionModel?> getOrderOptionModelById(String itemId) async {
    try {
      final items = await _localRepository.getListOrderOptionModel();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => OrderOptionModel(),
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
    List<OrderOptionModel> newData, {
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
    List<OrderOptionModel> list, {
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
        final existingItems = List<OrderOptionModel>.from(state.items);
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
    OrderOptionModel orderOptionModel, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(
        orderOptionModel,
        isInsertToPending,
      );

      if (result > 0) {
        final updatedItems = [...state.items, orderOptionModel];
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
    OrderOptionModel orderOptionModel, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.update(
        orderOptionModel,
        isInsertToPending,
      );

      if (result > 0) {
        final updatedItems =
            state.items.map((item) {
              return item.id == orderOptionModel.id ? orderOptionModel : item;
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

  /// Get order option name by ID
  Future<String?> getOrderOptionNameById(String id) async {
    try {
      return await _localRepository.getOrderOptionNameById(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Refresh items from repository (explicit reload)
  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListOrderOptionModel();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Get list of order options (synchronous getter from old notifier)
  List<OrderOptionModel> getListOrderOption() {
    return _localRepository.getListOrderOptionFromHive();
  }

  OrderOptionModel? getOrderOptionModel() {
    return state.items.isNotEmpty ? state.items.first : null;
  }

  Future<List<OrderOptionModel>> syncFromRemote() async {
    List<OrderOptionModel> allOrderOptions = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching order options page $currentPage');
      OrderOptionListResponseModel responseModel = await _webService.get(
        getOrderOptionWithPagination(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Process order options from current page
        List<OrderOptionModel> pageOrderOptions = responseModel.data!;

        // Add order options from current page to the list
        allOrderOptions.addAll(pageOrderOptions);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination ORDER OPTION: current page=$currentPage, last page=$lastPage, total order options=${responseModel.paginator!.total}',
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
          'Failed to fetch order options page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allOrderOptions.length} order options from all pages',
    );
    return allOrderOptions;
  }

  Resource getOrderOptionWithPagination(String page) {
    return _remoteRepository.getOrderOptionWithPagination(page);
  }

  List<OrderOptionModel> getListOrderOptionFromHive() {
    return _localRepository.getListOrderOptionFromHive();
  }
}

/// Provider for sorted items (computed provider)
final sortedOrderOptionsProvider = Provider<List<OrderOptionModel>>((ref) {
  final items = ref.watch(orderOptionProvider).items;
  final sorted = List<OrderOptionModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for orderOption domain
final orderOptionProvider =
    StateNotifierProvider<OrderOptionNotifier, OrderOptionState>((ref) {
      return OrderOptionNotifier(
        localRepository: ServiceLocator.get<LocalOrderOptionRepository>(),
        remoteRepository: ServiceLocator.get<OrderOptionRepository>(),
        webService: ServiceLocator.get<IWebService>(),
        ref: ref,
      );
    });

/// Provider for orderOption by ID (family provider for indexed lookups)
final orderOptionByIdProvider = Provider.family<OrderOptionModel?, String>((
  ref,
  id,
) {
  final items = ref.watch(orderOptionProvider).items;
  try {
    return items.firstWhere((item) => item.id == id);
  } catch (e) {
    return null;
  }
});

/// Provider for async order option by ID
final orderOptionByIdAsyncProvider =
    FutureProvider.family<OrderOptionModel?, String>((ref, id) async {
      final notifier = ref.watch(orderOptionProvider.notifier);
      return await notifier.getOrderOptionModelById(id);
    });

/// Provider for order options by search query (family provider)
final orderOptionsBySearchProvider =
    Provider.family<List<OrderOptionModel>, String>((ref, query) {
      final items = ref.watch(orderOptionProvider).items;
      if (query.isEmpty) return items;

      final lowerQuery = query.toLowerCase();
      return items.where((option) {
        final name = (option.name ?? '').toLowerCase();
        return name.contains(lowerQuery);
      }).toList();
    });

/// Provider to check if an order option exists by ID
final orderOptionExistsProvider = Provider.family<bool, String>((ref, id) {
  final items = ref.watch(orderOptionProvider).items;
  return items.any((item) => item.id == id);
});

/// Provider for total order option count
final orderOptionCountProvider = Provider<int>((ref) {
  final items = ref.watch(orderOptionProvider).items;
  return items.length;
});

/// Provider for order option name by ID (family provider)
final orderOptionNameByIdProvider = FutureProvider.family<String?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(orderOptionProvider.notifier);
  return await notifier.getOrderOptionNameById(id);
});

/// Provider for first order option (convenience provider)
final firstOrderOptionProvider = Provider<OrderOptionModel?>((ref) {
  final notifier = ref.watch(orderOptionProvider.notifier);
  return notifier.getOrderOptionModel();
});
