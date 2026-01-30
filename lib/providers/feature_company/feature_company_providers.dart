import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/enums/feature_enum.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/feature/feature_company_list_response_model.dart';
import 'package:mts/data/models/feature/feature_company_model.dart';
import 'package:mts/domain/repositories/local/feature_company_repository.dart';
import 'package:mts/domain/repositories/remote/feature_company_repository.dart';
import 'package:mts/providers/feature_company/feature_company_state.dart';

/// StateNotifier for FeatureCompany domain (pivot table: featureId + companyId)
///
/// Migrated from: feature_company_notifier.dart (ChangeNotifier)
class FeatureCompanyNotifier extends StateNotifier<FeatureCompanyState> {
  final LocalFeatureCompanyRepository _localRepository;
  final IWebService _webService;
  final RemoteFeatureCompanyRepository _remoteRepository;

  FeatureCompanyNotifier({
    required LocalFeatureCompanyRepository localRepository,
    required IWebService webService,
    required RemoteFeatureCompanyRepository remoteRepository,
  }) : _localRepository = localRepository,
       _webService = webService,
       _remoteRepository = remoteRepository,
       super(const FeatureCompanyState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<FeatureCompanyModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        // Upsert logic for pivot table (composite key: featureId + companyId)
        final currentItems = List<FeatureCompanyModel>.from(state.items);
        for (final newItem in list) {
          currentItems.removeWhere(
            (item) =>
                item.featureId == newItem.featureId &&
                item.companyId == newItem.companyId,
          );
          currentItems.add(newItem);
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
  Future<List<FeatureCompanyModel>> getListFeatureCompanies() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListFeatureCompanies();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<FeatureCompanyModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list);

      if (result) {
        final updatedItems =
            state.items.where((item) {
              return !list.any(
                (toDelete) =>
                    toDelete.featureId == item.featureId &&
                    toDelete.companyId == item.companyId,
              );
            }).toList();
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

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<FeatureCompanyModel> newData, {
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

  /// Upsert bulk items to Hive box
  Future<bool> upsertBulk(
    List<FeatureCompanyModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        // Upsert logic for pivot table
        final currentItems = List<FeatureCompanyModel>.from(state.items);
        for (final newItem in list) {
          currentItems.removeWhere(
            (item) =>
                item.featureId == newItem.featureId &&
                item.companyId == newItem.companyId,
          );
          currentItems.add(newItem);
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

  /// Add or update a list of feature companies (direct state update)
  void addOrUpdateList(List<FeatureCompanyModel> list) {
    final currentItems = List<FeatureCompanyModel>.from(state.items);
    for (final newItem in list) {
      currentItems.removeWhere(
        (item) =>
            item.featureId == newItem.featureId &&
            item.companyId == newItem.companyId,
      );
      currentItems.add(newItem);
    }
    state = state.copyWith(items: currentItems);
  }

  /// Add or update a single feature company (direct state update)
  void addOrUpdate(FeatureCompanyModel featureCompany) {
    final currentItems = List<FeatureCompanyModel>.from(state.items);
    currentItems.removeWhere(
      (item) =>
          item.featureId == featureCompany.featureId &&
          item.companyId == featureCompany.companyId,
    );
    currentItems.add(featureCompany);
    state = state.copyWith(items: currentItems);
  }

  /// Remove a feature company by composite key (direct state update)
  void remove(String featureId, String companyId) {
    final updatedItems =
        state.items
            .where(
              (item) =>
                  !(item.featureId == featureId && item.companyId == companyId),
            )
            .toList();
    state = state.copyWith(items: updatedItems);
  }

  /// Check if a feature is active for the current company
  bool isFeatureActive(String idFeature) {
    return state.items.any(
      (item) =>
          item.featureId == idFeature &&
          item.isActive != null &&
          item.isActive!,
    );
  }

  /// Check if Time Clock feature is active
  bool isTimeClockActive() {
    return isFeatureActive(FeatureEnum.TIME_CLOCK);
  }

  /// Check if Open Orders feature is active
  bool isOpenOrdersActive() {
    return isFeatureActive(FeatureEnum.OPEN_ORDERS);
  }

  /// Check if Department Printers feature is active
  bool isDepartmentPrintersActive() {
    return isFeatureActive(FeatureEnum.DEPARTMENT_PRINTERS);
  }

  /// Check if Order Option feature is active
  bool isOrderOptionActive() {
    return isFeatureActive(FeatureEnum.ORDER_OPTIONS);
  }

  /// Check if Table Layout feature is active
  bool isTableLayoutActive() {
    return isFeatureActive(FeatureEnum.TABLE_LAYOUT);
  }

  /// Refresh state from repository
  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListFeatureCompanies();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ========================================
  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================
  // Note: addOrUpdateList, addOrUpdate, remove already exist above

  /// Get list of feature companies (old notifier getter)
  /// NOTE: Conflicts with async method getListFeatureCompanies() from facade pattern.
  /// Old notifier pattern: getter returns cached state
  /// New provider pattern: async method loads from DB
  /// For UI migration: Use state.items directly or watch the provider
  // List<FeatureCompanyModel> get getListFeatureCompanies => state.items;

  /// Set feature companies (old notifier method)
  void setFeatureCompanies(List<FeatureCompanyModel> featureCompanies) {
    state = state.copyWith(items: featureCompanies);
  }

  /// Initialize - load from DB (old notifier method)
  Future<void> initialize() async {
    final localFeatureCompany =
        ServiceLocator.get<LocalFeatureCompanyRepository>();

    // get feature company list
    List<FeatureCompanyModel> listFeatureCompanies =
        await localFeatureCompany.getListFeatureCompanies();

    setFeatureCompanies(listFeatureCompanies);
  }

  /// Get sorted list of feature companies (old notifier method)
  List<FeatureCompanyModel> getSortedListFeatureCompanies() {
    final sorted = List<FeatureCompanyModel>.from(state.items);
    sorted.sort(
      (a, b) => '${a.featureId}_${a.companyId}'.toLowerCase().compareTo(
        '${b.featureId}_${b.companyId}'.toLowerCase(),
      ),
    );
    return sorted;
  }

  Future<List<FeatureCompanyModel>> syncFromRemote() async {
    try {
      final FeatureCompanyListResponseModel response = await _webService.get(
        _remoteRepository.getFeatureCompanyList(),
      );

      if (response.isSuccess && response.data != null) {
        return response.data!;
      }
      return [];
    } catch (e) {
      prints('ERROR FETCHING FEATURE COMPANIES FROM API: $e');
      return [];
    }
  }
}

/// Provider for featureCompany domain
final featureCompanyProvider =
    StateNotifierProvider<FeatureCompanyNotifier, FeatureCompanyState>((ref) {
      return FeatureCompanyNotifier(
        localRepository: ServiceLocator.get<LocalFeatureCompanyRepository>(),
        webService: ServiceLocator.get<IWebService>(),
        remoteRepository: ServiceLocator.get<RemoteFeatureCompanyRepository>(),
      );
    });

/// Sorted list provider (sorted by featureId, then companyId)
final sortedFeatureCompaniesProvider = Provider<List<FeatureCompanyModel>>((
  ref,
) {
  final items = ref.watch(featureCompanyProvider).items;
  final sorted = List<FeatureCompanyModel>.from(items);
  sorted.sort((a, b) {
    final featureIdCompare = (a.featureId ?? '').compareTo(b.featureId ?? '');
    if (featureIdCompare != 0) return featureIdCompare;
    return (a.companyId ?? '').compareTo(b.companyId ?? '');
  });
  return sorted;
});

/// Family provider to get feature company by composite key
final featureCompanyByKeyProvider = Provider.family<
  FeatureCompanyModel?,
  ({String featureId, String companyId})
>((ref, key) {
  final items = ref.watch(featureCompanyProvider).items;
  try {
    return items.firstWhere(
      (item) =>
          item.featureId == key.featureId && item.companyId == key.companyId,
    );
  } catch (_) {
    return null;
  }
});

/// Provider to check if a specific feature is active
final isFeatureActiveProvider = Provider.family<bool, String>((ref, featureId) {
  final notifier = ref.watch(featureCompanyProvider.notifier);
  return notifier.isFeatureActive(featureId);
});

/// Provider to check if Time Clock feature is active
final isTimeClockActiveProvider = Provider<bool>((ref) {
  final notifier = ref.watch(featureCompanyProvider.notifier);
  return notifier.isTimeClockActive();
});

/// Provider to check if Open Orders feature is active
final isOpenOrdersActiveProvider = Provider<bool>((ref) {
  final notifier = ref.watch(featureCompanyProvider.notifier);
  return notifier.isOpenOrdersActive();
});

/// Provider to check if Department Printers feature is active
final isDepartmentPrintersActiveProvider = Provider<bool>((ref) {
  final notifier = ref.watch(featureCompanyProvider.notifier);
  return notifier.isDepartmentPrintersActive();
});

/// Provider to check if Order Option feature is active
final isOrderOptionActiveProvider = Provider<bool>((ref) {
  final notifier = ref.watch(featureCompanyProvider.notifier);
  return notifier.isOrderOptionActive();
});

/// Provider to check if Table Layout feature is active
final isTableLayoutActiveProvider = Provider<bool>((ref) {
  final notifier = ref.watch(featureCompanyProvider.notifier);
  return notifier.isTableLayoutActive();
});

/// Provider for feature companies by company ID (computed family provider)
final featureCompaniesByCompanyIdProvider =
    Provider.family<List<FeatureCompanyModel>, String>((ref, companyId) {
      final items = ref.watch(featureCompanyProvider).items;
      return items.where((item) => item.companyId == companyId).toList();
    });

/// Provider for feature companies by feature ID (computed family provider)
final featureCompaniesByFeatureIdProvider =
    Provider.family<List<FeatureCompanyModel>, String>((ref, featureId) {
      final items = ref.watch(featureCompanyProvider).items;
      return items.where((item) => item.featureId == featureId).toList();
    });

/// Provider for active feature companies only (computed provider)
final activeFeatureCompaniesProvider = Provider<List<FeatureCompanyModel>>((
  ref,
) {
  final items = ref.watch(featureCompanyProvider).items;
  return items.where((item) => item.isActive == true).toList();
});

/// Provider for inactive feature companies only (computed provider)
final inactiveFeatureCompaniesProvider = Provider<List<FeatureCompanyModel>>((
  ref,
) {
  final items = ref.watch(featureCompanyProvider).items;
  return items.where((item) => item.isActive != true).toList();
});

/// Provider for feature company count (computed provider)
final featureCompanyCountProvider = Provider<int>((ref) {
  final items = ref.watch(featureCompanyProvider).items;
  return items.length;
});

/// Provider for active feature count (computed provider)
final activeFeatureCountProvider = Provider<int>((ref) {
  final activeItems = ref.watch(activeFeatureCompaniesProvider);
  return activeItems.length;
});

/// Provider to check if feature exists (computed family provider)
final featureCompanyExistsProvider =
    Provider.family<bool, ({String featureId, String companyId})>((ref, key) {
      final items = ref.watch(featureCompanyProvider).items;
      return items.any(
        (item) =>
            item.featureId == key.featureId && item.companyId == key.companyId,
      );
    });
