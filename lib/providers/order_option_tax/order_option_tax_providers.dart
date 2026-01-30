import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/order_option_tax/order_option_tax_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/domain/repositories/local/order_option_tax_repository.dart';
import 'package:mts/providers/order_option_tax/order_option_tax_state.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/order_option_tax/order_option_tax_list_response_model.dart';
import 'package:mts/domain/repositories/remote/order_option_tax_repository.dart';

/// StateNotifier for OrderOptionTax domain (Pivot Table)
///
/// Migrated from: order_option_tax_facade_impl.dart
class OrderOptionTaxNotifier extends StateNotifier<OrderOptionTaxState> {
  final LocalOrderOptionTaxRepository _localRepository;
  final OrderOptionTaxRepository _remoteRepository;
  final IWebService _webService;

  OrderOptionTaxNotifier({
    required LocalOrderOptionTaxRepository localRepository,
    required OrderOptionTaxRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const OrderOptionTaxState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<OrderOptionTaxModel> list, {
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
  Future<List<OrderOptionTaxModel>> getListOrderOptionTax() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListOrderOptionTax();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<OrderOptionTaxModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        final idsToDelete =
            list.map((e) => '${e.orderOptionId}_${e.taxId}').toSet();
        final updatedItems =
            state.items
                .where(
                  (e) => !idsToDelete.contains('${e.orderOptionId}_${e.taxId}'),
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

  /// Delete a single item by ID
  Future<int> delete(String id, {bool isInsertToPending = true}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.delete(
        id,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        // For pivot tables, the id parameter should be a composite key like "orderOptionId_taxId"
        final parts = id.split('_');
        if (parts.length == 2) {
          final orderOptionId = parts[0];
          final taxId = parts[1];
          final updatedItems =
              state.items
                  .where(
                    (e) =>
                        !(e.orderOptionId == orderOptionId && e.taxId == taxId),
                  )
                  .toList();
          state = state.copyWith(items: updatedItems);
        }
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Find an item by composite key (orderOptionId_taxId)
  Future<OrderOptionTaxModel?> getOrderOptionTaxModelByCompositeKey(
    String compositeKey,
  ) async {
    try {
      final items = await _localRepository.getListOrderOptionTax();
      final parts = compositeKey.split('_');
      if (parts.length != 2) return null;

      final orderOptionId = parts[0];
      final taxId = parts[1];

      try {
        final item = items.firstWhere(
          (item) => item.orderOptionId == orderOptionId && item.taxId == taxId,
          orElse: () => OrderOptionTaxModel(),
        );
        return (item.orderOptionId != null && item.taxId != null) ? item : null;
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
    List<OrderOptionTaxModel> newData, {
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
    List<OrderOptionTaxModel> list, {
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
        // Merge upserted items with existing items (using composite key for pivot table)
        final existingItems = List<OrderOptionTaxModel>.from(state.items);
        for (final item in list) {
          final index = existingItems.indexWhere(
            (e) =>
                e.orderOptionId == item.orderOptionId && e.taxId == item.taxId,
          );
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

  /// Upsert a single pivot record (insert or update)
  Future<int> upsert(
    OrderOptionTaxModel orderOptionTaxModel, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsert(
        orderOptionTaxModel,
        isInsertToPending,
      );

      if (result > 0) {
        // For pivot tables, use composite key to find existing item
        final existingItems = List<OrderOptionTaxModel>.from(state.items);
        final index = existingItems.indexWhere(
          (e) =>
              e.orderOptionId == orderOptionTaxModel.orderOptionId &&
              e.taxId == orderOptionTaxModel.taxId,
        );

        if (index >= 0) {
          existingItems[index] = orderOptionTaxModel;
        } else {
          existingItems.add(orderOptionTaxModel);
        }
        state = state.copyWith(items: existingItems);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Delete a pivot record
  Future<int> deletePivot(
    OrderOptionTaxModel orderOptionTaxModel, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deletePivot(
        orderOptionTaxModel,
        isInsertToPending,
      );

      if (result > 0) {
        final updatedItems =
            state.items
                .where(
                  (e) =>
                      !(e.orderOptionId == orderOptionTaxModel.orderOptionId &&
                          e.taxId == orderOptionTaxModel.taxId),
                )
                .toList();
        state = state.copyWith(items: updatedItems);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Delete records by column name and value
  Future<int> deleteByColumnName(
    String columnName,
    dynamic value, {
    bool isInsertToPending = false,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteByColumnName(
        columnName,
        value,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        // Remove items based on column name and value
        final updatedItems =
            state.items.where((item) {
              switch (columnName.toLowerCase()) {
                case 'order_option_id':
                case 'orderoptionid':
                  return item.orderOptionId != value.toString();
                case 'tax_id':
                case 'taxid':
                  return item.taxId != value.toString();
                default:
                  return true;
              }
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
      final items = await _localRepository.getListOrderOptionTax();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Get order option tax list (synchronous getter from old notifier)
  List<OrderOptionTaxModel> getOrderOptionTaxList() {
    return state.items;
  }

  /// Set order option tax list (synchronous setter from old notifier)
  void setOrderOptionTaxList(List<OrderOptionTaxModel> list) {
    state = state.copyWith(items: list);
  }

  /// Add or update list of order option taxes (upsert bulk)
  void addOrUpdateList(List<OrderOptionTaxModel> list) {
    final currentItems = List<OrderOptionTaxModel>.from(state.items);

    for (OrderOptionTaxModel oot in list) {
      int index = currentItems.indexWhere(
        (element) =>
            element.orderOptionId == oot.orderOptionId &&
            element.taxId == oot.taxId,
      );

      if (index != -1) {
        // if found, replace existing item with the new one
        currentItems[index] = oot;
      } else {
        // not found
        currentItems.add(oot);
      }
    }

    state = state.copyWith(items: currentItems);
  }

  /// Remove a single order option tax by composite key
  void remove(String orderOptionId, String taxId) {
    final updatedItems =
        state.items
            .where(
              (orderOptionTax) =>
                  !(orderOptionTax.orderOptionId == orderOptionId &&
                      orderOptionTax.taxId == taxId),
            )
            .toList();

    state = state.copyWith(items: updatedItems);
  }

  /// Get tax models by order option ID (requires TaxNotifier from ServiceLocator)
  /// Note: This method is kept for compatibility but should ideally use Riverpod providers
  List<TaxModel> getTaxModelByOrderOptionId(String idOrderOption) {
    // 1. Get all tax-oo relations for this orderOptionId
    final filteredListOrderOptionTaxes =
        state.items.where((oot) => oot.orderOptionId == idOrderOption).toList();

    final uniqueTaxIds =
        filteredListOrderOptionTaxes
            .map((oot) => oot.taxId)
            .whereType<String>()
            .toSet();

    // Note: To get actual TaxModel objects, use the taxModelsByOrderOptionIdProvider instead
    // This method signature returns List<TaxModel> for compatibility but requires TaxNotifier
    // Consider using getTaxModelsByOrderOptionId() async method instead
    return [];
  }

  /// Get list of tax models from order option tax list (old notifier method)
  List<TaxModel> getListTaxModelFromOrderOptionTaxList(
    List<TaxModel> listReceiveTaxModel,
    OrderOptionModel orderOptionModel,
    TaxModel taxModel,
  ) {
    if (orderOptionModel.id == null) {
      return [];
    }
    final listOrderOptionTax = state.items;

    // Extract taxIds from orderOptionTax list
    final taxIds =
        listOrderOptionTax
            .where((oom) => oom.orderOptionId == orderOptionModel.id)
            .map((orderOptionTax) => orderOptionTax.taxId)
            .toList();

    final listTax = taxIds.where((e) => e == taxModel.id).toList();

    // Filter from the parameter listReceiveTaxModel
    return listReceiveTaxModel
        .where((tax) => listTax.contains(tax.id))
        .toList();
  }

  Future<List<OrderOptionTaxModel>> syncFromRemote() async {
    List<OrderOptionTaxModel> allOrderOptionTaxes = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching item taxes page $currentPage');
      OrderOptionTaxListResponseModel responseModel = await _webService.get(
        getOrderOptionTaxListPaginated(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Process item taxes from current page
        List<OrderOptionTaxModel> pageItemTaxes = responseModel.data!;

        // Add item taxes from current page to the list
        allOrderOptionTaxes.addAll(pageItemTaxes);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination ORDER OPTION TAX: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
      'Fetched a total of ${allOrderOptionTaxes.length} item taxes from all pages',
    );
    return allOrderOptionTaxes;
  }

  Resource getOrderOptionTaxListPaginated(String page) {
    return _remoteRepository.getOrderOptionTaxListPaginated(page);
  }

  Future<List<TaxModel>> getTaxModelsByOrderOptionId(String idItem) async {
    return await _localRepository.getTaxModelsByOrderOptionId(idItem);
  }
}

/// Provider for sorted items (computed provider) - sorted by orderOptionId and taxId
final sortedOrderOptionTaxsProvider = Provider<List<OrderOptionTaxModel>>((
  ref,
) {
  final items = ref.watch(orderOptionTaxProvider).items;
  final sorted = List<OrderOptionTaxModel>.from(items);
  sorted.sort((a, b) {
    final orderOptionCompare = (a.orderOptionId ?? '').compareTo(
      b.orderOptionId ?? '',
    );
    if (orderOptionCompare != 0) return orderOptionCompare;
    return (a.taxId ?? '').compareTo(b.taxId ?? '');
  });
  return sorted;
});

/// Provider for orderOptionTax domain
final orderOptionTaxProvider =
    StateNotifierProvider<OrderOptionTaxNotifier, OrderOptionTaxState>((ref) {
      return OrderOptionTaxNotifier(
        localRepository: ServiceLocator.get<LocalOrderOptionTaxRepository>(),
        remoteRepository: ServiceLocator.get<OrderOptionTaxRepository>(),
        webService: ServiceLocator.get<IWebService>(),
      );
    });

/// Provider for orderOptionTax by composite key (family provider for pivot table lookups)
final orderOptionTaxByCompositeKeyProvider =
    Provider.family<OrderOptionTaxModel?, String>((
      ref,
      compositeKey, // Format: "orderOptionId_taxId"
    ) {
      final items = ref.watch(orderOptionTaxProvider).items;
      final parts = compositeKey.split('_');
      if (parts.length != 2) return null;

      final orderOptionId = parts[0];
      final taxId = parts[1];

      try {
        return items.firstWhere(
          (item) => item.orderOptionId == orderOptionId && item.taxId == taxId,
        );
      } catch (e) {
        return null;
      }
    });

/// Provider for order option taxes by order option ID (family provider)
final orderOptionTaxesByOrderOptionIdProvider =
    Provider.family<List<OrderOptionTaxModel>, String>((ref, orderOptionId) {
      final items = ref.watch(orderOptionTaxProvider).items;
      return items
          .where((item) => item.orderOptionId == orderOptionId)
          .toList();
    });

/// Provider for order option taxes by tax ID (family provider)
final orderOptionTaxesByTaxIdProvider =
    Provider.family<List<OrderOptionTaxModel>, String>((ref, taxId) {
      final items = ref.watch(orderOptionTaxProvider).items;
      return items.where((item) => item.taxId == taxId).toList();
    });

/// Provider to check if a specific order option-tax relation exists (family provider)
final orderOptionTaxExistsProvider =
    Provider.family<bool, ({String orderOptionId, String taxId})>((
      ref,
      params,
    ) {
      final items = ref.watch(orderOptionTaxProvider).items;
      return items.any(
        (item) =>
            item.orderOptionId == params.orderOptionId &&
            item.taxId == params.taxId,
      );
    });

/// Provider for count of taxes per order option (family provider)
final taxCountPerOrderOptionProvider = Provider.family<int, String>((
  ref,
  orderOptionId,
) {
  final orderOptionTaxes = ref.watch(
    orderOptionTaxesByOrderOptionIdProvider(orderOptionId),
  );
  return orderOptionTaxes.length;
});

/// Provider for count of order options per tax (family provider)
final orderOptionCountPerTaxProvider = Provider.family<int, String>((
  ref,
  taxId,
) {
  final orderOptionTaxes = ref.watch(orderOptionTaxesByTaxIdProvider(taxId));
  return orderOptionTaxes.length;
});

/// Provider for TaxModel list by order option ID (async family provider)
/// This uses the repository method to get actual TaxModel objects
final taxModelsByOrderOptionIdProvider =
    FutureProvider.family<List<TaxModel>, String>((ref, orderOptionId) async {
      final notifier = ref.watch(orderOptionTaxProvider.notifier);
      return await notifier.getTaxModelsByOrderOptionId(orderOptionId);
    });

/// Provider for unique tax IDs by order option ID (family provider)
final taxIdsByOrderOptionIdProvider = Provider.family<List<String>, String>((
  ref,
  orderOptionId,
) {
  final orderOptionTaxes = ref.watch(
    orderOptionTaxesByOrderOptionIdProvider(orderOptionId),
  );
  return orderOptionTaxes.map((it) => it.taxId ?? '').toList();
});

/// Provider for unique order option IDs by tax ID (family provider)
final orderOptionIdsByTaxIdProvider = Provider.family<List<String>, String>((
  ref,
  taxId,
) {
  final orderOptionTaxes = ref.watch(orderOptionTaxesByTaxIdProvider(taxId));
  return orderOptionTaxes.map((it) => it.orderOptionId ?? '').toList();
});
