import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/domain/repositories/local/customer_repository.dart';
import 'package:mts/domain/repositories/remote/customer_repository.dart';
import 'package:mts/providers/customer/customer_state.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/customer/customer_list_response_model.dart';

/// StateNotifier for Customer domain
///
/// Migrated from: customer_facade_impl.dart
class CustomerNotifier extends StateNotifier<CustomerState> {
  final LocalCustomerRepository _localRepository;
  final CustomerRepository _remoteRepository;
  final IWebService _webService;

  CustomerNotifier({
    required LocalCustomerRepository localRepository,
    required CustomerRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const CustomerState());

  // ============================================================
  // CRUD Operations - Optimized for Riverpod
  // ============================================================

  /// Insert a single item into local storage
  Future<int> insert(
    CustomerModel model, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(
        model,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        final updatedItems = List<CustomerModel>.from(state.items)..add(model);
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
  Future<int> update(
    CustomerModel model, {
    bool isInsertToPending = true,
  }) async {
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
    List<CustomerModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        // Update state directly - Riverpod auto-notifies listeners
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
  Future<List<CustomerModel>> getListCustomerModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListCustomerModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<CustomerModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        // Update state directly - Riverpod auto-notifies listeners
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
        // Update state directly - Riverpod auto-notifies listeners
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
  Future<CustomerModel?> getCustomerModelById(String itemId) async {
    try {
      final items = await _localRepository.getListCustomerModel();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => CustomerModel(),
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
    List<CustomerModel> newData, {
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
    List<CustomerModel> list, {
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
        // Update state directly - merge upserted items with existing
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
    await getListCustomerModel();
  }

  // ============================================================
  // UI State Management Methods (from old CustomerNotifier)
  // ============================================================

  /// Get customer list (getter for compatibility)
  List<CustomerModel> get getCustomerList => state.items;

  /// Get current customer model
  CustomerModel? get getCurrentCustomerModel => state.currentCustomer;

  /// Get order customer model
  CustomerModel? get getOrderCustomerModel => state.orderCustomer;

  /// Get edit customer form bloc
  dynamic get getEditCustomerFormBloc => state.editCustomerFormBloc;

  /// Set current customer for the order
  void setOrderCustomerModel(CustomerModel? model) {
    state = state.copyWith(orderCustomer: model);
  }

  /// Set current customer in the customer dialogue
  void setCurrentCustomerModel(CustomerModel? model) {
    state = state.copyWith(currentCustomer: model);
  }

  /// Set edit customer form bloc
  void setEditCustomerFormBloc(dynamic formBloc) {
    state = state.copyWith(editCustomerFormBloc: formBloc);
  }

  /// Get customer by ID (synchronous version for compatibility)
  CustomerModel getCustomerById(String? idCustomer) {
    if (idCustomer == null) {
      return CustomerModel();
    }

    return state.items.firstWhere(
      (customer) => customer.id == idCustomer,
      orElse: () => CustomerModel(),
    );
  }

  Resource getCustomerListWithPagination(String page) {
    return _remoteRepository.getCustomerListWithPagination(page);
  }

  Future<List<CustomerModel>> syncFromRemote() async {
    List<CustomerModel> allCustomers = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching customers page $currentPage');
      CustomerListResponseModel responseModel = await _webService.get(
        getCustomerListWithPagination(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Process customers from current page
        List<CustomerModel> pageCustomers = responseModel.data!;

        // Add customers from current page to the list
        allCustomers.addAll(pageCustomers);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination CUSTOMER: current page=$currentPage, last page=$lastPage, total customers=${responseModel.paginator!.total}',
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
          'Failed to fetch customers page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allCustomers.length} customers from all pages',
    );
    return allCustomers;
  }

  List<CustomerModel> getListCustomerFromHive() {
    return _localRepository.getListCustomerFromHive();
  }
}

/// Provider for sorted items (computed provider)
final sortedCustomersProvider = Provider<List<CustomerModel>>((ref) {
  final items = ref.watch(customerProvider).items;
  final sorted = List<CustomerModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for customer domain
final customerProvider = StateNotifierProvider<CustomerNotifier, CustomerState>(
  (ref) {
    return CustomerNotifier(
      localRepository: ServiceLocator.get<LocalCustomerRepository>(),
      remoteRepository: ServiceLocator.get<CustomerRepository>(),
      webService: ServiceLocator.get<IWebService>(),
    );
  },
);

/// Provider for customer by ID (family provider for indexed lookups)
final customerByIdProvider = FutureProvider.family<CustomerModel?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(customerProvider.notifier);
  return notifier.getCustomerModelById(id);
});
