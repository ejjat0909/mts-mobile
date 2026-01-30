import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/outlet_tax/outlet_tax_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/domain/repositories/local/outlet_tax_repository.dart';
import 'package:mts/providers/outlet_tax/outlet_tax_state.dart';
import 'package:mts/providers/tax/tax_providers.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/outlet_tax/outlet_tax_list_response_model.dart';
import 'package:mts/domain/repositories/remote/outlet_tax_repository.dart';

/// StateNotifier for OutletTax domain (pivot table)
///
/// Migrated from: outlet_tax_facade_impl.dart
class OutletTaxNotifier extends StateNotifier<OutletTaxState> {
  final LocalOutletTaxRepository _localRepository;
  final OutletTaxRepository _remoteRepository;
  final IWebService _webService;
  final Ref _ref;

  OutletTaxNotifier({
    required LocalOutletTaxRepository localRepository,
    required OutletTaxRepository remoteRepository,
    required IWebService webService,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _ref = ref,
       super(const OutletTaxState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<OutletTaxModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<OutletTaxModel>.from(state.items);
        for (final newItem in list) {
          final index = currentItems.indexWhere(
            (item) =>
                item.outletId == newItem.outletId &&
                item.taxId == newItem.taxId,
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
  Future<List<OutletTaxModel>> getListOutletTaxModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListOutletTaxModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<OutletTaxModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        final keysToRemove =
            list.map((item) => '${item.outletId}_${item.taxId}').toSet();
        final updatedItems =
            state.items
                .where(
                  (item) =>
                      !keysToRemove.contains('${item.outletId}_${item.taxId}'),
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

  /// Delete a pivot item
  Future<int> deletePivot(
    OutletTaxModel model, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deletePivot(
        model,
        isInsertToPending,
      );

      if (result > 0) {
        final updatedItems =
            state.items
                .where(
                  (item) =>
                      !(item.outletId == model.outletId &&
                          item.taxId == model.taxId),
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

  /// Find an item by composite key (outletId, taxId)
  OutletTaxModel? getOutletTaxModelByKey(String outletId, String taxId) {
    try {
      return state.items
          .where((item) => item.outletId == outletId && item.taxId == taxId)
          .firstOrNull;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Get taxes for an outlet
  Future<List<TaxModel>> getTaxModelsByOutletId(String outletId) async {
    try {
      return await _localRepository.getTaxModelsByOutletId(outletId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<OutletTaxModel> newData, {
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
    List<OutletTaxModel> list, {
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
        final currentItems = List<OutletTaxModel>.from(state.items);
        for (final newItem in list) {
          final index = currentItems.indexWhere(
            (item) =>
                item.outletId == newItem.outletId &&
                item.taxId == newItem.taxId,
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
      final items = await _localRepository.getListOutletTaxModel();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get outlet tax list (old notifier getter)
  List<OutletTaxModel> get getOutletTaxList => state.items;

  /// Set list outlet tax (old notifier method)
  void setListOutletTax(List<OutletTaxModel> list) {
    state = state.copyWith(items: list);
  }

  /// Add or update list of outlet taxes (old notifier method)
  void addOrUpdateList(List<OutletTaxModel> list) {
    final currentItems = List<OutletTaxModel>.from(state.items);

    for (OutletTaxModel outletTax in list) {
      int index = currentItems.indexWhere(
        (element) =>
            element.outletId == outletTax.outletId &&
            element.taxId == outletTax.taxId,
      );

      if (index != -1) {
        currentItems[index] = outletTax;
      } else {
        currentItems.add(outletTax);
      }
    }

    state = state.copyWith(items: currentItems);
  }

  /// Add or update single outlet tax (old notifier method)
  void addOrUpdate(OutletTaxModel outletTax) {
    final currentItems = List<OutletTaxModel>.from(state.items);
    int index = currentItems.indexWhere(
      (t) => t.outletId == outletTax.outletId && t.taxId == outletTax.taxId,
    );

    if (index != -1) {
      currentItems[index] = outletTax;
    } else {
      currentItems.add(outletTax);
    }

    state = state.copyWith(items: currentItems);
  }

  /// Remove outlet tax (old notifier method)
  void remove(String outletId, String taxId) {
    final updatedItems =
        state.items
            .where(
              (outletTax) =>
                  !(outletTax.outletId == outletId && outletTax.taxId == taxId),
            )
            .toList();
    state = state.copyWith(items: updatedItems);
  }

  /// Get list of tax models from outlet tax list (old notifier method)
  List<TaxModel> getListTaxModelFromOutletTaxList(
    List<TaxModel> listReceiveTaxModel,
  ) {
    final outletModel = ServiceLocator.get<OutletModel>();
    final listOutletTax = getOutletTaxList;
    final taxIds =
        listOutletTax
            .where((ot) => ot.outletId == outletModel.id)
            .map((ot) => ot.taxId)
            .toList();

    return listReceiveTaxModel.where((tax) => taxIds.contains(tax.id)).toList();
  }

  /// Get tax models by outlet ID (synchronous version from old notifier)
  /// Uses tax provider via ref instead of ServiceLocator
  List<TaxModel> getTaxModelsByOutletIdSync(String outletId) {
    // 1. Get all tax-outlet relations for this outletId
    final filteredListOutletTaxes =
        state.items.where((ot) => ot.outletId == outletId).toList();

    // 2. Extract unique tax IDs
    final uniqueTaxIds =
        filteredListOutletTaxes
            .map((ot) => ot.taxId)
            .whereType<String>()
            .toSet();

    // 3. Get taxes from tax provider using ref
    final taxState = _ref.read(taxProvider);
    final listTax = taxState.items;

    // 4. Filter taxes based on ID
    return listTax.where((tax) {
      final isLinked = uniqueTaxIds.contains(tax.id);
      return isLinked;
    }).toList();
  }

  Future<int> insert(OutletTaxModel model) async {
    return await _localRepository.upsert(model, true);
  }

  Future<int> update(OutletTaxModel outletTaxModel) async {
    return await _localRepository.upsert(outletTaxModel, true);
  }

  Future<int> delete(String id) async {
    // The LocalOutletTaxRepository uses deletePivot which requires an OutletTaxModel
    // Since we only have an ID string, we need to parse it to get outletId and taxId
    // Assuming the ID is in the format "outletId_taxId"
    List<String> parts = id.split('_');
    if (parts.length != 2) {
      prints('Invalid ID format for outlet tax deletion: $id');
      return 0;
    }

    OutletTaxModel model = OutletTaxModel(outletId: parts[0], taxId: parts[1]);

    return await _localRepository.deletePivot(model, true);
  }

  Future<List<OutletTaxModel>> syncFromRemote() async {
    List<OutletTaxModel> allOutletTaxes = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching outlet taxes page $currentPage');
      OutletTaxListResponseModel responseModel = await _webService.get(
        getOutletTaxListPaginated(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Process outlet taxes from current page
        List<OutletTaxModel> pageOutletTaxes = responseModel.data!;

        // Add outlet taxes from current page to the list
        allOutletTaxes.addAll(pageOutletTaxes);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination OUTLET TAX: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch outlet taxes page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allOutletTaxes.length} outlet taxes from all pages',
    );
    return allOutletTaxes;
  }

  Resource getOutletTaxListPaginated(String page) {
    return _remoteRepository.getOutletTaxListPaginated(page);
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

/// Provider for outletTax domain
final outletTaxProvider =
    StateNotifierProvider<OutletTaxNotifier, OutletTaxState>((ref) {
      return OutletTaxNotifier(
        localRepository: ServiceLocator.get<LocalOutletTaxRepository>(),
        remoteRepository: ServiceLocator.get<OutletTaxRepository>(),
        webService: ServiceLocator.get<IWebService>(),
        ref: ref,
      );
    });

/// Provider for sorted items - sorted by outletId then taxId (no name field)
final sortedOutletTaxsProvider = Provider<List<OutletTaxModel>>((ref) {
  final items = ref.watch(outletTaxProvider).items;
  final sorted = List<OutletTaxModel>.from(items);
  sorted.sort((a, b) {
    final outletCompare = (a.outletId ?? '').compareTo(b.outletId ?? '');
    if (outletCompare != 0) return outletCompare;
    return (a.taxId ?? '').compareTo(b.taxId ?? '');
  });
  return sorted;
});

/// Provider for outletTax by composite key (family provider)
final outletTaxByKeyProvider =
    Provider.family<OutletTaxModel?, ({String outletId, String taxId})>((
      ref,
      key,
    ) {
      final notifier = ref.watch(outletTaxProvider.notifier);
      return notifier.getOutletTaxModelByKey(key.outletId, key.taxId);
    });

/// Provider for taxes by outlet ID
final taxesByOutletIdProvider = FutureProvider.family<List<TaxModel>, String>((
  ref,
  outletId,
) async {
  final notifier = ref.watch(outletTaxProvider.notifier);
  return notifier.getTaxModelsByOutletId(outletId);
});

/// Provider for synchronous taxes by outlet ID
final taxesByOutletIdSyncProvider = Provider.family<List<TaxModel>, String>((
  ref,
  outletId,
) {
  final notifier = ref.watch(outletTaxProvider.notifier);
  return notifier.getTaxModelsByOutletIdSync(outletId);
});

/// Provider for outlet taxes by outlet ID (family provider)
final outletTaxesByOutletIdProvider =
    Provider.family<List<OutletTaxModel>, String>((ref, outletId) {
      final items = ref.watch(outletTaxProvider).items;
      return items.where((ot) => ot.outletId == outletId).toList();
    });

/// Provider for outlet taxes by tax ID (family provider)
final outletTaxesByTaxIdProvider =
    Provider.family<List<OutletTaxModel>, String>((ref, taxId) {
      final items = ref.watch(outletTaxProvider).items;
      return items.where((ot) => ot.taxId == taxId).toList();
    });

/// Provider to check if tax is linked to outlet (family provider)
final isTaxLinkedToOutletProvider =
    Provider.family<bool, ({String outletId, String taxId})>((ref, params) {
      final items = ref.watch(outletTaxProvider).items;
      return items.any(
        (ot) => ot.outletId == params.outletId && ot.taxId == params.taxId,
      );
    });

/// Provider for count of taxes per outlet (family provider)
final taxCountPerOutletProvider = Provider.family<int, String>((ref, outletId) {
  final outletTaxes = ref.watch(outletTaxesByOutletIdProvider(outletId));
  return outletTaxes.length;
});

/// Provider for count of outlets per tax (family provider)
final outletCountPerTaxProvider = Provider.family<int, String>((ref, taxId) {
  final outletTaxes = ref.watch(outletTaxesByTaxIdProvider(taxId));
  return outletTaxes.length;
});

/// Provider for unique tax IDs by outlet ID (family provider)
final taxIdsByOutletIdProvider = Provider.family<List<String>, String>((
  ref,
  outletId,
) {
  final outletTaxes = ref.watch(outletTaxesByOutletIdProvider(outletId));
  return outletTaxes.map((ot) => ot.taxId ?? '').toList();
});

/// Provider for unique outlet IDs by tax ID (family provider)
final outletIdsByTaxIdProvider = Provider.family<List<String>, String>((
  ref,
  taxId,
) {
  final outletTaxes = ref.watch(outletTaxesByTaxIdProvider(taxId));
  return outletTaxes.map((ot) => ot.outletId ?? '').toList();
});

/// Provider for taxes for current outlet
final taxesForCurrentOutletProvider = FutureProvider<List<TaxModel>>((
  ref,
) async {
  final outletModel = ServiceLocator.get<OutletModel>();
  if (outletModel.id == null) return [];

  final notifier = ref.watch(outletTaxProvider.notifier);
  return await notifier.getTaxModelsByOutletId(outletModel.id!);
});

/// Provider for synchronous taxes for current outlet
final taxesForCurrentOutletSyncProvider = Provider<List<TaxModel>>((ref) {
  final outletModel = ServiceLocator.get<OutletModel>();
  if (outletModel.id == null) return [];

  final notifier = ref.watch(outletTaxProvider.notifier);
  return notifier.getTaxModelsByOutletIdSync(outletModel.id!);
});
