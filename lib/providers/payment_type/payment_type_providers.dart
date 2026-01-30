import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/domain/repositories/local/payment_type_repository.dart';
import 'package:mts/providers/payment_type/payment_type_state.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/payment_type/payment_type_list_response_model.dart';
import 'package:mts/domain/repositories/remote/payment_type_repository.dart';

/// StateNotifier for PaymentType domain
///
/// Migrated from: payment_type_facade_impl.dart
class PaymentTypeNotifier extends StateNotifier<PaymentTypeState> {
  final LocalPaymentTypeRepository _localRepository;
  final PaymentTypeRepository _remoteRepository;
  final IWebService _webService;

  PaymentTypeNotifier({
    required LocalPaymentTypeRepository localRepository,
    required PaymentTypeRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const PaymentTypeState());

  // ============================================================
  // CRUD Operations - Optimized for Riverpod
  // ============================================================

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<PaymentTypeModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
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
  Future<List<PaymentTypeModel>> getListPaymentType() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListPaymentType();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<PaymentTypeModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
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
  Future<PaymentTypeModel?> getPaymentTypeById(String itemId) async {
    try {
      final items = await _localRepository.getListPaymentType();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => PaymentTypeModel(),
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
    List<PaymentTypeModel> newData, {
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
    List<PaymentTypeModel> list, {
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
    await getListPaymentType();
  }

  // ============================================================
  // UI State Management Methods (from old PaymentTypeNotifier)
  // ============================================================

  /// Get payment type list (getter for compatibility)
  List<PaymentTypeModel> get getPaymentTypeList => state.items;

  /// Refresh payment types and initialize payment cache
  void refreshPaymentTypes() {
    state.items.firstWhere(
      (payment) => payment.name?.toLowerCase() == 'cash',
      orElse:
          () => state.items.isNotEmpty ? state.items.first : PaymentTypeModel(),
    );
    // Note: PaymentDetails.initializePaymentCache call should be done in UI layer
    // This method is kept for API compatibility but logic moved to presentation layer
  }

  Future<List<PaymentTypeModel>> syncFromRemote() async {
    List<PaymentTypeModel> allPaymentTypes = [];
    int currentPage = 1;
    int? lastPage;

    do {
      prints('Fetching payment types page $currentPage');
      PaymentTypeListResponseModel responseModel = await _webService.get(
        getPaymentTypeWithPagination(currentPage.toString()),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        List<PaymentTypeModel> pagePaymentTypes = responseModel.data!;

        allPaymentTypes.addAll(pagePaymentTypes);

        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination PAYMENT_TYPE: current page=$currentPage, last page=$lastPage, total payment types=${responseModel.paginator!.total}',
          );
        } else {
          break;
        }

        currentPage++;
      } else {
        prints(
          'Failed to fetch payment types page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allPaymentTypes.length} payment types from all pages',
    );
    return allPaymentTypes;
  }

  Resource getPaymentTypeWithPagination(String page) {
    return _remoteRepository.getPaymentTypeWithPagination(page);
  }

  List<PaymentTypeModel> getListPaymentTypeFromHive() {
    return _localRepository.getListPaymentTypeFromHive();
  }
}

/// Provider for sorted items (computed provider)
final sortedPaymentTypesProvider = Provider<List<PaymentTypeModel>>((ref) {
  final items = ref.watch(paymentTypeProvider).items;
  final sorted = List<PaymentTypeModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for paymentType domain
final paymentTypeProvider =
    StateNotifierProvider<PaymentTypeNotifier, PaymentTypeState>((ref) {
      return PaymentTypeNotifier(
        localRepository: ServiceLocator.get<LocalPaymentTypeRepository>(),
        remoteRepository: ServiceLocator.get<PaymentTypeRepository>(),
        webService: ServiceLocator.get<IWebService>(),
      );
    });

/// Provider for paymentType by ID (family provider for indexed lookups)
final paymentTypeByIdProvider =
    FutureProvider.family<PaymentTypeModel?, String>((ref, id) async {
      final notifier = ref.watch(paymentTypeProvider.notifier);
      return notifier.getPaymentTypeById(id);
    });

/// Provider for synchronous payment type by ID (from current state)
final paymentTypeByIdFromStateProvider =
    Provider.family<PaymentTypeModel?, String>((ref, id) {
      final items = ref.watch(paymentTypeProvider).items;
      try {
        return items.firstWhere((item) => item.id == id);
      } catch (e) {
        return null;
      }
    });

/// Provider for payment types by search query (family provider)
final paymentTypesBySearchProvider =
    Provider.family<List<PaymentTypeModel>, String>((ref, query) {
      final items = ref.watch(paymentTypeProvider).items;
      if (query.isEmpty) return items;

      final lowerQuery = query.toLowerCase();
      return items.where((paymentType) {
        final name = (paymentType.name ?? '').toLowerCase();
        return name.contains(lowerQuery);
      }).toList();
    });

/// Provider for payment type by name (family provider)
final paymentTypeByNameProvider = Provider.family<PaymentTypeModel?, String>((
  ref,
  name,
) {
  final items = ref.watch(paymentTypeProvider).items;
  try {
    return items.firstWhere(
      (payment) => payment.name?.toLowerCase() == name.toLowerCase(),
    );
  } catch (e) {
    return null;
  }
});

/// Provider to check if a payment type exists by ID
final paymentTypeExistsProvider = Provider.family<bool, String>((ref, id) {
  final items = ref.watch(paymentTypeProvider).items;
  return items.any((item) => item.id == id);
});

/// Provider for total payment type count
final paymentTypeCountProvider = Provider<int>((ref) {
  final items = ref.watch(paymentTypeProvider).items;
  return items.length;
});

/// Provider for cash payment type
final cashPaymentTypeProvider = Provider<PaymentTypeModel?>((ref) {
  final items = ref.watch(paymentTypeProvider).items;
  try {
    return items.firstWhere((payment) => payment.name?.toLowerCase() == 'cash');
  } catch (e) {
    return items.isNotEmpty ? items.first : null;
  }
});
