import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/outlet_payment_type/outlet_payment_type_model.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/domain/repositories/local/outlet_payment_type_repository.dart';
import 'package:mts/providers/outlet_payment_type/outlet_payment_type_state.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/outlet_payment_type/outlet_payment_type_list_response_model.dart';
import 'package:mts/domain/repositories/remote/outlet_payment_type_repository.dart';
import 'package:mts/providers/payment_type/payment_type_providers.dart';

/// StateNotifier for OutletPaymentType domain (pivot table)
///
/// Migrated from: outlet_payment_type_facade_impl.dart
class OutletPaymentTypeNotifier extends StateNotifier<OutletPaymentTypeState> {
  final LocalOutletPaymentTypeRepository _localRepository;
  final OutletPaymentTypeRepository _remoteRepository;
  final IWebService _webService;
  final Ref _ref;

  OutletPaymentTypeNotifier({
    required LocalOutletPaymentTypeRepository localRepository,
    required OutletPaymentTypeRepository remoteRepository,
    required IWebService webService,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _ref = ref,
       super(const OutletPaymentTypeState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<OutletPaymentTypeModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<OutletPaymentTypeModel>.from(state.items);
        for (final newItem in list) {
          final index = currentItems.indexWhere(
            (item) =>
                item.outletId == newItem.outletId &&
                item.paymentTypeId == newItem.paymentTypeId,
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
  Future<List<OutletPaymentTypeModel>> getListOutletPaymentTypeModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListOutletPaymentTypeModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<OutletPaymentTypeModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        final keysToRemove =
            list
                .map((item) => '${item.outletId}_${item.paymentTypeId}')
                .toSet();
        final updatedItems =
            state.items
                .where(
                  (item) =>
                      !keysToRemove.contains(
                        '${item.outletId}_${item.paymentTypeId}',
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

  /// Delete a pivot item
  Future<int> deletePivot(
    OutletPaymentTypeModel model, {
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
                          item.paymentTypeId == model.paymentTypeId),
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

  /// Find an item by composite key (outletId, paymentTypeId)
  OutletPaymentTypeModel? getOutletPaymentTypeModelByKey(
    String outletId,
    String paymentTypeId,
  ) {
    try {
      return state.items
          .where(
            (item) =>
                item.outletId == outletId &&
                item.paymentTypeId == paymentTypeId,
          )
          .firstOrNull;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Get payment types for an outlet
  Future<List<PaymentTypeModel>> getPaymentTypeModelsByOutletId(
    String outletId,
  ) async {
    try {
      return await _localRepository.getPaymentTypeModelsByOutletId(outletId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<OutletPaymentTypeModel> newData, {
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
    List<OutletPaymentTypeModel> list, {
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
        final currentItems = List<OutletPaymentTypeModel>.from(state.items);
        for (final newItem in list) {
          final index = currentItems.indexWhere(
            (item) =>
                item.outletId == newItem.outletId &&
                item.paymentTypeId == newItem.paymentTypeId,
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
      final items = await _localRepository.getListOutletPaymentTypeModel();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get outlet payment type list (old notifier getter)
  List<OutletPaymentTypeModel> get getOutletPaymentTypeList => state.items;

  /// Set list outlet payment type (old notifier method)
  void setListOutletPaymentType(List<OutletPaymentTypeModel> list) {
    state = state.copyWith(items: list);
  }

  /// Re-get list outlet payment type from DB (old notifier method)
  Future<void> reGetListOutletPaymentType() async {
    final listOutletPaymentFromDB =
        await _localRepository.getListOutletPaymentTypeModel();
    setListOutletPaymentType(listOutletPaymentFromDB);
  }

  /// Add or update list (old notifier method)
  void addOrUpdateList(List<OutletPaymentTypeModel> list) {
    final currentItems = List<OutletPaymentTypeModel>.from(state.items);

    for (OutletPaymentTypeModel outletPaymentType in list) {
      int index = currentItems.indexWhere(
        (element) =>
            element.outletId == outletPaymentType.outletId &&
            element.paymentTypeId == outletPaymentType.paymentTypeId,
      );

      if (index != -1) {
        currentItems[index] = outletPaymentType;
      } else {
        currentItems.add(outletPaymentType);
      }
    }

    state = state.copyWith(items: currentItems);
  }

  /// Add or update single (old notifier method)
  void addOrUpdate(OutletPaymentTypeModel outletPaymentType) {
    final currentItems = List<OutletPaymentTypeModel>.from(state.items);
    int index = currentItems.indexWhere(
      (opt) =>
          opt.outletId == outletPaymentType.outletId &&
          opt.paymentTypeId == outletPaymentType.paymentTypeId,
    );

    if (index != -1) {
      currentItems[index] = outletPaymentType;
    } else {
      currentItems.add(outletPaymentType);
    }

    state = state.copyWith(items: currentItems);
  }

  /// Remove outlet payment type (old notifier method)
  void remove(String outletId, String paymentTypeId) {
    final updatedItems =
        state.items
            .where(
              (outletPaymentType) =>
                  !(outletPaymentType.outletId == outletId &&
                      outletPaymentType.paymentTypeId == paymentTypeId),
            )
            .toList();
    state = state.copyWith(items: updatedItems);
  }

  /// Get list of payment types from outlet payment type list (old notifier method)
  List<PaymentTypeModel> getListPaymentTypeModelFromOutletPaymentTypeList(
    List<PaymentTypeModel> listReceivePaymentTypeModel,
  ) {
    final outletModel = ServiceLocator.get<OutletModel>();
    final listOutletPaymentType = getOutletPaymentTypeList;
    final paymentTypeIds =
        listOutletPaymentType
            .where((opt) => opt.outletId == outletModel.id)
            .map((opt) => opt.paymentTypeId)
            .toList();

    return listReceivePaymentTypeModel
        .where((paymentType) => paymentTypeIds.contains(paymentType.id))
        .toList();
  }

  /// Get payment type models for current outlet (old notifier method)
  List<PaymentTypeModel> getPaymentTypeModelsForCurrentOutlet() {
    final outletModel = ServiceLocator.get<OutletModel>();
    if (outletModel.id == null) return [];

    return getPaymentTypeModelsByOutletIdSync(outletModel.id!);
  }

  /// Get payment type models by outlet ID (synchronous version from old notifier)
  /// This accesses PaymentTypeNotifier from ServiceLocator for compatibility
  List<PaymentTypeModel> getPaymentTypeModelsByOutletIdSync(String outletId) {
    // 1. Get all payment-type-outlet relations for this outletId
    final filteredListOutletPaymentTypes =
        state.items.where((opt) => opt.outletId == outletId).toList();

    // 2. Extract unique payment type IDs
    final uniquePaymentTypeIds =
        filteredListOutletPaymentTypes
            .map((opt) => opt.paymentTypeId)
            .whereType<String>()
            .toSet();

    // 3. Get payment types from PaymentTypeNotifier
    try {
      final paymentTypeNotifier = _ref.read(paymentTypeProvider.notifier);
      final allPaymentTypes = paymentTypeNotifier.getPaymentTypeList;

      // 4. Filter payment types that are linked to this outlet
      return allPaymentTypes
          .where((paymentType) => uniquePaymentTypeIds.contains(paymentType.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear all (old notifier method)
  void clearAll() {
    state = state.copyWith(items: []);
  }

  /// Get outlet payment types by outlet ID (old notifier method)
  List<OutletPaymentTypeModel> getOutletPaymentTypesByOutletId(
    String outletId,
  ) {
    return state.items.where((opt) => opt.outletId == outletId).toList();
  }

  /// Check if payment type is linked to outlet (old notifier method)
  bool isPaymentTypeLinkedToOutlet(String outletId, String paymentTypeId) {
    return state.items.any(
      (opt) => opt.outletId == outletId && opt.paymentTypeId == paymentTypeId,
    );
  }

  Future<int> upsert(OutletPaymentTypeModel model) async {
    return await _localRepository.upsert(model, true);
  }

  Future<List<OutletPaymentTypeModel>> syncFromRemote() async {
    List<OutletPaymentTypeModel> allOutletPaymentTypes = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching outlet payment types page $currentPage');
      OutletPaymentTypeListResponseModel responseModel = await _webService.get(
        getOutletPaymentTypeListPaginated(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Process outlet payment types from current page
        List<OutletPaymentTypeModel> pageOutletPaymentTypes =
            responseModel.data!;

        // Add outlet payment types from current page to the list
        allOutletPaymentTypes.addAll(pageOutletPaymentTypes);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination OUTLET PAYMENT TYPE: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
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
          'Failed to fetch outlet payment types page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allOutletPaymentTypes.length} outlet payment types from all pages',
    );
    return allOutletPaymentTypes;
  }

  Resource getOutletPaymentTypeListPaginated(String page) {
    return _remoteRepository.getOutletPaymentTypeListPaginated(page);
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

/// Provider for outletPaymentType domain
final outletPaymentTypeProvider =
    StateNotifierProvider<OutletPaymentTypeNotifier, OutletPaymentTypeState>((
      ref,
    ) {
      return OutletPaymentTypeNotifier(
        localRepository: ServiceLocator.get<LocalOutletPaymentTypeRepository>(),
        remoteRepository: ServiceLocator.get<OutletPaymentTypeRepository>(),
        webService: ServiceLocator.get<IWebService>(),
        ref: ref,
      );
    });

/// Provider for sorted items - sorted by outletId then paymentTypeId (no name field)
final sortedOutletPaymentTypesProvider = Provider<List<OutletPaymentTypeModel>>(
  (ref) {
    final items = ref.watch(outletPaymentTypeProvider).items;
    final sorted = List<OutletPaymentTypeModel>.from(items);
    sorted.sort((a, b) {
      final outletCompare = (a.outletId ?? '').compareTo(b.outletId ?? '');
      if (outletCompare != 0) return outletCompare;
      return (a.paymentTypeId ?? '').compareTo(b.paymentTypeId ?? '');
    });
    return sorted;
  },
);

/// Provider for outletPaymentType by composite key (family provider)
final outletPaymentTypeByKeyProvider = Provider.family<
  OutletPaymentTypeModel?,
  ({String outletId, String paymentTypeId})
>((ref, key) {
  final notifier = ref.watch(outletPaymentTypeProvider.notifier);
  return notifier.getOutletPaymentTypeModelByKey(
    key.outletId,
    key.paymentTypeId,
  );
});

/// Provider for payment types by outlet ID
final paymentTypesByOutletIdProvider =
    FutureProvider.family<List<PaymentTypeModel>, String>((
      ref,
      outletId,
    ) async {
      final notifier = ref.watch(outletPaymentTypeProvider.notifier);
      return notifier.getPaymentTypeModelsByOutletId(outletId);
    });

/// Provider for outlet payment types by outlet ID (family provider)
final outletPaymentTypesByOutletIdProvider =
    Provider.family<List<OutletPaymentTypeModel>, String>((ref, outletId) {
      final items = ref.watch(outletPaymentTypeProvider).items;
      return items.where((opt) => opt.outletId == outletId).toList();
    });

/// Provider for outlet payment types by payment type ID (family provider)
final outletPaymentTypesByPaymentTypeIdProvider =
    Provider.family<List<OutletPaymentTypeModel>, String>((ref, paymentTypeId) {
      final items = ref.watch(outletPaymentTypeProvider).items;
      return items.where((opt) => opt.paymentTypeId == paymentTypeId).toList();
    });

/// Provider to check if payment type is linked to outlet (family provider)
final isPaymentTypeLinkedToOutletProvider =
    Provider.family<bool, ({String outletId, String paymentTypeId})>((
      ref,
      params,
    ) {
      final notifier = ref.watch(outletPaymentTypeProvider.notifier);
      return notifier.isPaymentTypeLinkedToOutlet(
        params.outletId,
        params.paymentTypeId,
      );
    });

/// Provider for count of payment types per outlet (family provider)
final paymentTypeCountPerOutletProvider = Provider.family<int, String>((
  ref,
  outletId,
) {
  final outletPaymentTypes = ref.watch(
    outletPaymentTypesByOutletIdProvider(outletId),
  );
  return outletPaymentTypes.length;
});

/// Provider for count of outlets per payment type (family provider)
final outletCountPerPaymentTypeProvider = Provider.family<int, String>((
  ref,
  paymentTypeId,
) {
  final outletPaymentTypes = ref.watch(
    outletPaymentTypesByPaymentTypeIdProvider(paymentTypeId),
  );
  return outletPaymentTypes.length;
});

/// Provider for unique payment type IDs by outlet ID (family provider)
final paymentTypeIdsByOutletIdProvider = Provider.family<List<String>, String>((
  ref,
  outletId,
) {
  final outletPaymentTypes = ref.watch(
    outletPaymentTypesByOutletIdProvider(outletId),
  );
  return outletPaymentTypes.map((opt) => opt.paymentTypeId ?? '').toList();
});

/// Provider for unique outlet IDs by payment type ID (family provider)
final outletIdsByPaymentTypeIdProvider = Provider.family<List<String>, String>((
  ref,
  paymentTypeId,
) {
  final outletPaymentTypes = ref.watch(
    outletPaymentTypesByPaymentTypeIdProvider(paymentTypeId),
  );
  return outletPaymentTypes.map((opt) => opt.outletId ?? '').toList();
});

/// Provider for payment types for current outlet
final paymentTypesForCurrentOutletProvider =
    FutureProvider<List<PaymentTypeModel>>((ref) async {
      final outletModel = ServiceLocator.get<OutletModel>();
      if (outletModel.id == null) return [];

      final notifier = ref.watch(outletPaymentTypeProvider.notifier);
      return await notifier.getPaymentTypeModelsByOutletId(outletModel.id!);
    });
