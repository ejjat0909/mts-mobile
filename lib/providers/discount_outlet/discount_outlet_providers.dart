import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/discount/discount_model.dart';
import 'package:mts/data/models/discount_outlet/discount_outlet_list_response_model.dart';
import 'package:mts/data/models/discount_outlet/discount_outlet_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/domain/repositories/local/discount_outlet_repository.dart';
import 'package:mts/domain/repositories/remote/discount_outlet_repository.dart';
import 'package:mts/providers/discount/discount_providers.dart';
import 'package:mts/providers/discount_outlet/discount_outlet_state.dart';

/// StateNotifier for DiscountOutlet domain
///
/// Migrated from: discount_outlet_facade_impl.dart
class DiscountOutletNotifier extends StateNotifier<DiscountOutletState> {
  final LocalDiscountOutletRepository _localRepository;
  final DiscountOutletRepository _remoteRepository;
  final IWebService _webService;
  final Ref _ref;

  DiscountOutletNotifier({
    required LocalDiscountOutletRepository localRepository,
    required DiscountOutletRepository remoteRepository,
    required IWebService webService,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _ref = ref,
       super(const DiscountOutletState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<DiscountOutletModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<DiscountOutletModel>.from(state.items);
        for (final newItem in list) {
          final index = currentItems.indexWhere(
            (item) =>
                item.discountId == newItem.discountId &&
                item.outletId == newItem.outletId,
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
  Future<List<DiscountOutletModel>> getListDiscountOutlet() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListDiscountOutlet();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<DiscountOutletModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        final keysToRemove =
            list.map((item) => '${item.discountId}_${item.outletId}').toSet();
        final updatedItems =
            state.items
                .where(
                  (item) =>
                      !keysToRemove.contains(
                        '${item.discountId}_${item.outletId}',
                      ),
                )
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

  /// Delete a pivot record
  Future<int> deletePivot(
    DiscountOutletModel discountOutletModel, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deletePivot(
        discountOutletModel,
        isInsertToPending,
      );

      if (result > 0) {
        final updatedItems =
            state.items
                .where(
                  (item) =>
                      !(item.discountId == discountOutletModel.discountId &&
                          item.outletId == discountOutletModel.outletId),
                )
                .toList();
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

  /// Find an item by its composite key (discountId + outletId)
  Future<DiscountOutletModel?> getDiscountOutletByKey(
    String discountId,
    String outletId,
  ) async {
    try {
      // First check current state
      final cachedItem =
          state.items
              .where(
                (item) =>
                    item.discountId == discountId && item.outletId == outletId,
              )
              .firstOrNull;
      if (cachedItem != null) return cachedItem;

      // Fall back to repository
      final items = await _localRepository.getListDiscountOutlet();
      return items
          .where(
            (item) =>
                item.discountId == discountId && item.outletId == outletId,
          )
          .firstOrNull;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<DiscountOutletModel> newData, {
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
    List<DiscountOutletModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<DiscountOutletModel>.from(state.items);
        for (final newItem in list) {
          final index = currentItems.indexWhere(
            (item) =>
                item.discountId == newItem.discountId &&
                item.outletId == newItem.outletId,
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
      final items = await _localRepository.getListDiscountOutlet();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<List<DiscountModel>> getValidDiscountModelsByOutletId(
    String outletId,
  ) async {
    // Get all discount outlets for this outlet
    final allDiscountOutlets = await _localRepository.getListDiscountOutlet();
    final discountOutletsForOutlet =
        allDiscountOutlets
            .where((discountOutlet) => discountOutlet.outletId == outletId)
            .toList();

    // Get all discounts
    final discountNotifier = _ref.read(discountProvider.notifier);
    final allDiscounts = await discountNotifier.getListDiscountModel();
    final now = DateTime.now();

    // Filter discounts based on outlet relation and validity
    return allDiscounts.where((discount) {
      // Check if discount is linked to the outlet
      final isLinked = discountOutletsForOutlet.any(
        (discountOutlet) => discountOutlet.discountId == discount.id,
      );

      // Check if discount is valid (within date range)
      final isValidFrom =
          discount.validFrom == null ||
          discount.validFrom!.isBefore(now) ||
          discount.validFrom!.isAtSameMomentAs(now);
      final isValidTo =
          discount.validTo == null ||
          discount.validTo!.isAfter(now) ||
          discount.validTo!.isAtSameMomentAs(now);

      return isLinked && isValidFrom && isValidTo;
    }).toList();
  }

  Resource getRemoteDiscountOutletList(String page) {
    return _remoteRepository.getDiscountOutletList(page);
  }

  Future<List<DiscountOutletModel>> syncFromRemote() async {
    List<DiscountOutletModel> allDiscountOutlets = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching discount outlets page $currentPage');
      DiscountOutletListResponseModel responseModel = await _webService.get(
        getRemoteDiscountOutletList(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Add items from current page to the list
        allDiscountOutlets.addAll(responseModel.data!);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination DISCOUNT OUTLET: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch discount outlets page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allDiscountOutlets.length} discount outlets from all pages',
    );
    return allDiscountOutlets;
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

  /// Get the current discount outlet list from state (synchronous)
  List<DiscountOutletModel> getDiscountOutletList() {
    return state.items;
  }

  /// Set the entire list of discount outlets in state
  void setListDiscountOutlet(List<DiscountOutletModel> list) {
    state = state.copyWith(items: list);
  }

  /// Add or update a list of discount outlets in state
  void addOrUpdateList(List<DiscountOutletModel> list) {
    final currentItems = List<DiscountOutletModel>.from(state.items);

    for (final discountOutlet in list) {
      final index = currentItems.indexWhere(
        (element) =>
            element.outletId == discountOutlet.outletId &&
            element.discountId == discountOutlet.discountId,
      );

      if (index != -1) {
        // If found, replace existing item with the new one
        currentItems[index] = discountOutlet;
      } else {
        // Not found, add new item
        currentItems.add(discountOutlet);
      }
    }

    state = state.copyWith(items: currentItems);
  }

  /// Add or update a single discount outlet in state
  void addOrUpdate(DiscountOutletModel discountOutlet) {
    final currentItems = List<DiscountOutletModel>.from(state.items);

    final index = currentItems.indexWhere(
      (d) =>
          d.outletId == discountOutlet.outletId &&
          d.discountId == discountOutlet.discountId,
    );

    if (index != -1) {
      // If found, replace existing item with the new one
      currentItems[index] = discountOutlet;
    } else {
      // Not found, add new item
      currentItems.add(discountOutlet);
    }

    state = state.copyWith(items: currentItems);
  }

  /// Remove a discount outlet from state by outletId and discountId
  void remove(String outletId, String discountId) {
    final updatedItems =
        state.items
            .where(
              (discountOutlet) =>
                  !(discountOutlet.outletId == outletId &&
                      discountOutlet.discountId == discountId),
            )
            .toList();

    state = state.copyWith(items: updatedItems);
  }

  /// Returns a list of valid discount models for the current outlet from ServiceLocator
  ///
  /// [listReceiveDiscountModel] List of discount models to filter
  ///
  /// Returns a list of [DiscountModel] objects that are valid for the current outlet
  /// and within their valid date range
  List<DiscountModel> getValidDiscountModelsByOutletIdSync(
    List<DiscountModel> listReceiveDiscountModel,
  ) {
    final outletModel = ServiceLocator.get<OutletModel>();
    final outletId = outletModel.id;

    final now = DateTime.now();
    final listDiscountOutlet = state.items;

    // Get all discount IDs for this outlet
    final discountIds =
        listDiscountOutlet
            .where((dom) => dom.outletId == outletId)
            .map((dom) => dom.discountId)
            .toList();

    // Filter discounts based on ID and valid date range
    return listReceiveDiscountModel.where((discount) {
      final isLinked = discountIds.contains(discount.id);
      final isValidFrom =
          discount.validFrom == null ||
          discount.validFrom!.isBefore(now) ||
          discount.validFrom!.isAtSameMomentAs(now);
      final isValidTo =
          discount.validTo == null ||
          discount.validTo!.isAfter(now) ||
          discount.validTo!.isAtSameMomentAs(now);
      return isLinked && isValidFrom && isValidTo;
    }).toList();
  }
}

/// Provider for discountOutlet domain
final discountOutletProvider =
    StateNotifierProvider<DiscountOutletNotifier, DiscountOutletState>((ref) {
      return DiscountOutletNotifier(
        localRepository: ServiceLocator.get<LocalDiscountOutletRepository>(),
        remoteRepository: ServiceLocator.get<DiscountOutletRepository>(),
        webService: ServiceLocator.get<IWebService>(),
        ref: ref,
      );
    });

/// Provider for sorted items (computed provider - sorted by discountId then outletId)
final sortedDiscountOutletsProvider = Provider<List<DiscountOutletModel>>((
  ref,
) {
  final items = ref.watch(discountOutletProvider).items;
  final sorted = List<DiscountOutletModel>.from(items);
  sorted.sort((a, b) {
    final discountCompare = (a.discountId ?? '').compareTo(b.discountId ?? '');
    if (discountCompare != 0) return discountCompare;
    return (a.outletId ?? '').compareTo(b.outletId ?? '');
  });
  return sorted;
});

/// Provider for discountOutlet by composite key (family provider)
final discountOutletByKeyProvider = FutureProvider.family<
  DiscountOutletModel?,
  ({String discountId, String outletId})
>((ref, key) async {
  final notifier = ref.watch(discountOutletProvider.notifier);
  return notifier.getDiscountOutletByKey(key.discountId, key.outletId);
});

/// Provider for discount outlets by outlet ID (computed provider)
final discountOutletsByOutletIdProvider =
    Provider.family<List<DiscountOutletModel>, String>((ref, outletId) {
      final items = ref.watch(discountOutletProvider).items;
      return items.where((item) => item.outletId == outletId).toList();
    });

/// Provider for discount outlets by discount ID (computed provider)
final discountOutletsByDiscountIdProvider =
    Provider.family<List<DiscountOutletModel>, String>((ref, discountId) {
      final items = ref.watch(discountOutletProvider).items;
      return items.where((item) => item.discountId == discountId).toList();
    });

/// Provider for checking if a discount outlet relation exists (computed provider)
final discountOutletExistsProvider =
    Provider.family<bool, ({String discountId, String outletId})>((ref, key) {
      final items = ref.watch(discountOutletProvider).items;
      return items.any(
        (item) =>
            item.discountId == key.discountId && item.outletId == key.outletId,
      );
    });

/// Provider for valid discounts by outlet ID (async family provider)
final validDiscountsByOutletIdProvider =
    FutureProvider.family<List<DiscountModel>, String>((ref, outletId) async {
      final notifier = ref.watch(discountOutletProvider.notifier);
      return notifier.getValidDiscountModelsByOutletId(outletId);
    });

/// Provider for discount count per outlet (computed provider)
final discountCountPerOutletProvider = Provider.family<int, String>((
  ref,
  outletId,
) {
  final items = ref.watch(discountOutletsByOutletIdProvider(outletId));
  return items.length;
});
