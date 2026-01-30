import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/utils/async_notifier_mutation_mixin.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/category/category_model.dart';
import 'package:mts/data/repositories/local/local_category_repository_impl.dart';
import 'package:mts/data/repositories/remote/category_repository_impl.dart';
import 'package:mts/domain/repositories/local/category_repository.dart';
import 'package:mts/domain/repositories/remote/category_repository.dart';
import 'package:mts/providers/category/category_state.dart';

/// AsyncNotifier for Category domain
class CategoryNotifier extends AsyncNotifier<CategoryState>
    with AsyncNotifierMutationMixin<CategoryState> {
  late final LocalCategoryRepository _localRepository;
  late final CategoryRepository _remoteRepository;

  @override
  Future<CategoryState> build() async {
    _localRepository = ref.read(categoryLocalRepoProvider);
    _remoteRepository = ref.read(categoryRemoteRepoProvider);

    final categories = await _localRepository.getListCategoryModel();
    return CategoryState(categories: categories);
  }

  /// Insert or update multiple categories
  Future<bool> upsertBulk(
    List<CategoryModel> list, {
    bool isInsertToPending = true,
  }) async {
    return mutate(
      () => _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      ),
      (current) {
        final map = {
          for (final c in current.categories.where((c) => c.id != null))
            c.id!: c,
        };
        for (final category in list) {
          if (category.id != null) {
            map[category.id!] = category;
          }
        }
        return current.copyWith(categories: map.values.toList());
      },
    );
  }

  /// Delete single category
  Future<bool> delete(String id, {bool isInsertToPending = true}) async {
    final result = await mutate(
      () => _localRepository.delete(id, isInsertToPending: isInsertToPending),
      (current) => current.copyWith(
        categories: current.categories.where((c) => c.id != id).toList(),
      ),
    );
    return result > 0;
  }

  /// Delete all categories
  Future<bool> deleteAll() async {
    return mutate(
      () => _localRepository.deleteAll(),
      (_) => const CategoryState(categories: []),
    );
  }

  /// Replace all local data
  Future<bool> replaceAllData(
    List<CategoryModel> newData, {
    bool isInsertToPending = false,
  }) async {
    return mutate(
      () => _localRepository.replaceAllData(
        newData,
        isInsertToPending: isInsertToPending,
      ),
      (_) => CategoryState(categories: newData),
    );
  }

  /// Sync from remote API (pagination)
  Future<List<CategoryModel>> syncFromRemote() async {
    prints('Starting sync for ${CategoryModel.modelName}...');

    final allCategories = await _remoteRepository.fetchAllPaginated();
    prints(
      'Fetched ${allCategories.length} ${CategoryModel.modelName} from remote',
    );

    if (allCategories.isEmpty) {
      prints('No ${CategoryModel.modelName} to sync');
      return [];
    }

    // Persist to local storage and update state atomically
    final saved = await mutate(
      () => _localRepository.upsertBulk(
        allCategories,
        isInsertToPending: false, // From server, not pending
      ),
      (current) {
        final map = {
          for (final c in current.categories.where((c) => c.id != null))
            c.id!: c,
        };
        for (final c in allCategories.where((c) => c.id != null)) {
          map[c.id!] = c;
        }
        return current.copyWith(categories: map.values.toList());
      },
    );

    if (!saved) {
      await LogUtils.error(
        'Failed to save synced ${CategoryModel.modelName} to local storage',
        null,
      );
      throw Exception('Failed to save synced categories to local storage');
    }

    prints(
      'Successfully synced ${allCategories.length} categories to local storage',
    );
    return allCategories;
  }

  /// Get a single category by ID (from state, no extra DB read)
  CategoryModel? getCategoryModelById(String id) {
    final current = state.value;
    if (current == null) return null;

    try {
      final category = current.categories.firstWhere((c) => c.id == id);
      return category.id != null ? category : null;
    } catch (_) {
      return null;
    }
  }
}

/// Main provider for CategoryNotifier
final categoryProvider = AsyncNotifierProvider<CategoryNotifier, CategoryState>(
  () => CategoryNotifier(),
);

/// Computed provider for sorted categories
final sortedCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final state = ref.watch(categoryProvider).value;
  if (state == null) return [];

  final sorted = [...state.categories];
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for category by ID (family)
final categoryByIdProvider = Provider.family<CategoryModel?, String>((ref, id) {
  final state = ref.watch(categoryProvider).value;
  if (state == null) return null;

  try {
    final category = state.categories.firstWhere((c) => c.id == id);
    return category.id != null ? category : null;
  } catch (_) {
    return null;
  }
});
