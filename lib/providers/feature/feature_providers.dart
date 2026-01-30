import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/feature/feature_list_response_model.dart';
import 'package:mts/data/models/feature/feature_model.dart';
import 'package:mts/domain/repositories/local/feature_repository.dart';
import 'package:mts/domain/repositories/remote/feature_repository.dart';
import 'package:mts/providers/feature/feature_state.dart';

/// StateNotifier for Feature domain
///
/// Migrated from: feature_facade_impl.dart
class FeatureNotifier extends StateNotifier<FeatureState> {
  final LocalFeatureRepository _localRepository;
  final RemoteFeatureRepository _remoteRepository;
  final IWebService _webService;

  FeatureNotifier({
    required LocalFeatureRepository localRepository,
    required RemoteFeatureRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const FeatureState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<FeatureModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final currentItems = List<FeatureModel>.from(state.items);
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
  Future<List<FeatureModel>> getListFeatureModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListFeatures();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<FeatureModel> list) async {
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
  Future<FeatureModel?> getFeatureModelById(String itemId) async {
    try {
      // First check current state
      final cachedItem =
          state.items.where((item) => item.id == itemId).firstOrNull;
      if (cachedItem != null) return cachedItem;

      // Fall back to checking all items from repository
      final items = await _localRepository.getListFeatures();
      return items.where((item) => item.id == itemId).firstOrNull;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<FeatureModel> newData, {
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
    List<FeatureModel> list, {
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
        final currentItems = List<FeatureModel>.from(state.items);
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

  /// Refresh state from repository
  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListFeatures();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Set features list (old notifier method)
  void setFeatures(List<FeatureModel> list) {
    state = state.copyWith(items: list);
  }

  /// Get sorted list of features (old notifier method)
  List<FeatureModel> getSortedListFeatures() {
    final sorted = List<FeatureModel>.from(state.items);
    sorted.sort(
      (a, b) =>
          (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
    );
    return sorted;
  }

  /// Add or update list of features (old notifier method)
  void addOrUpdateList(List<FeatureModel> list) {
    final currentItems = List<FeatureModel>.from(state.items);

    for (final newItem in list) {
      final index = currentItems.indexWhere((item) => item.id == newItem.id);
      if (index >= 0) {
        currentItems[index] = newItem;
      } else {
        currentItems.add(newItem);
      }
    }

    state = state.copyWith(items: currentItems);
  }

  /// Add or update single feature (old notifier method)
  void addOrUpdate(FeatureModel featureModel) {
    final currentItems = List<FeatureModel>.from(state.items);
    final index = currentItems.indexWhere((item) => item.id == featureModel.id);

    if (index >= 0) {
      currentItems[index] = featureModel;
    } else {
      currentItems.add(featureModel);
    }

    state = state.copyWith(items: currentItems);
  }

  /// Remove feature from list (old notifier method)
  void remove(FeatureModel featureModel) {
    final updatedItems =
        state.items.where((item) => item.id != featureModel.id).toList();
    state = state.copyWith(items: updatedItems);
  }

  /// Get list of features (old notifier getter)
  List<FeatureModel> get getListFeatures => state.items;

  Future<List<FeatureModel>> syncFromRemote() async {
    try {
      final FeatureListResponseModel response = await _webService.get(
        _remoteRepository.getFeatureList(),
      );
      if (response.isSuccess && response.data != null) {
        return response.data!;
      }
      return [];
    } catch (e) {
      prints('ERROR FETCHING FEATURES FROM API: $e');
      return [];
    }
  }
}

/// Provider for feature domain
final featureProvider = StateNotifierProvider<FeatureNotifier, FeatureState>((
  ref,
) {
  return FeatureNotifier(
    localRepository: ServiceLocator.get<LocalFeatureRepository>(),
    remoteRepository: ServiceLocator.get<RemoteFeatureRepository>(),
    webService: ServiceLocator.get<IWebService>(),
  );
});

/// Provider for sorted items (computed provider)
final sortedFeaturesProvider = Provider<List<FeatureModel>>((ref) {
  final items = ref.watch(featureProvider).items;
  final sorted = List<FeatureModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for feature by ID (family provider for indexed lookups)
final featureByIdProvider = FutureProvider.family<FeatureModel?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(featureProvider.notifier);
  return notifier.getFeatureModelById(id);
});

/// Provider for feature by ID synchronously (computed family provider)
final featureByIdSyncProvider = Provider.family<FeatureModel?, String>((
  ref,
  id,
) {
  final items = ref.watch(featureProvider).items;
  try {
    return items.firstWhere((item) => item.id == id);
  } catch (_) {
    return null;
  }
});

/// Provider for feature by name (computed family provider)
final featureByNameProvider = Provider.family<FeatureModel?, String>((
  ref,
  name,
) {
  final items = ref.watch(featureProvider).items;
  try {
    return items.firstWhere(
      (item) => item.name?.toLowerCase() == name.toLowerCase(),
    );
  } catch (_) {
    return null;
  }
});

/// Provider for feature count (computed provider)
final featureCountProvider = Provider<int>((ref) {
  final items = ref.watch(featureProvider).items;
  return items.length;
});

/// Provider to check if feature exists by ID (computed family provider)
final featureExistsByIdProvider = Provider.family<bool, String>((ref, id) {
  final items = ref.watch(featureProvider).items;
  return items.any((item) => item.id == id);
});

/// Provider to check if feature exists by name (computed family provider)
final featureExistsByNameProvider = Provider.family<bool, String>((ref, name) {
  final items = ref.watch(featureProvider).items;
  return items.any((item) => item.name?.toLowerCase() == name.toLowerCase());
});

/// Provider for features by search query (computed family provider)
final featuresBySearchProvider = Provider.family<List<FeatureModel>, String>((
  ref,
  query,
) {
  if (query.isEmpty) return ref.watch(featureProvider).items;

  final items = ref.watch(featureProvider).items;
  final lowerQuery = query.toLowerCase();

  return items
      .where(
        (feature) =>
            feature.name?.toLowerCase().contains(lowerQuery) == true ||
            feature.description?.toLowerCase().contains(lowerQuery) == true,
      )
      .toList();
});
