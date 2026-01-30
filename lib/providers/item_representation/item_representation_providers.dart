import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/data/models/item_representation/item_representation_model.dart';
import 'package:mts/data/repositories/local/local_item_representation_repository_impl.dart';
import 'package:mts/domain/repositories/local/item_representation_repository.dart';
import 'package:mts/domain/repositories/remote/item_representation_repository.dart';
import 'package:mts/providers/item_representation/item_representation_state.dart';

/// AsyncNotifier for ItemRepresentation domain
class ItemRepresentationNotifier
    extends AsyncNotifier<ItemRepresentationState> {
  late final LocalItemRepresentationRepository _localRepository;
  late final ItemRepresentationRepository _remoteRepository;
  late final IWebService _webService;

  @override
  Future<ItemRepresentationState> build() async {
    _localRepository = ref.read(itemRepresentationLocalRepoProvider);
    _remoteRepository = ServiceLocator.get<ItemRepresentationRepository>();
    _webService = ServiceLocator.get<IWebService>();

    final items = await _localRepository.getListItemRepresentationModel();
    await _localRepository.upsertBulk(items, isInsertToPending: false);
    return ItemRepresentationState(items: items);
  }

  /// Load items from local DB
  Future<void> loadFromLocal() async {
    state = const AsyncValue.loading();
    try {
      final items = await _localRepository.getListItemRepresentationModel();
      await _localRepository.upsertBulk(items, isInsertToPending: false);
      state = AsyncValue.data(ItemRepresentationState(items: items));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Insert a single item
  Future<int> insert(ItemRepresentationModel model) async {
    state = const AsyncValue.loading();
    try {
      model.id ??= IdUtils.generateUUID();
      model.createdAt ??= DateTime.now();
      model.updatedAt ??= DateTime.now();

      final result = await _localRepository.insert(model, true);
      if (result > 0) {
        await _localRepository.upsertBulk([model], isInsertToPending: false);
        final updatedItems = [...state.value!.items, model];
        state = AsyncValue.data(state.value!.copyWith(items: updatedItems));
      }
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return 0;
    }
  }

  /// Update an item
  Future<int> updateItem(ItemRepresentationModel model) async {
    state = const AsyncValue.loading();
    try {
      model.updatedAt = DateTime.now();
      final result = await _localRepository.update(model, true);

      if (result > 0) {
        await _localRepository.upsertBulk([model], isInsertToPending: false);
        final updatedItems =
            state.value!.items
                .map((e) => e.id == model.id ? model : e)
                .toList();
        state = AsyncValue.data(state.value!.copyWith(items: updatedItems));
      }
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return 0;
    }
  }

  /// Delete item by ID
  Future<int> delete(String id) async {
    state = const AsyncValue.loading();
    try {
      final result = await _localRepository.delete(id, true);
      if (result > 0) {
        final updatedItems =
            state.value!.items.where((e) => e.id != id).toList();
        state = AsyncValue.data(state.value!.copyWith(items: updatedItems));
      }
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return 0;
    }
  }

  /// Bulk upsert to Hive
  Future<bool> upsertBulk(
    List<ItemRepresentationModel> list, {
    bool isInsertToPending = true,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );
      if (result) {
        final existingItems = List<ItemRepresentationModel>.from(
          state.value!.items,
        );
        for (final item in list) {
          final index = existingItems.indexWhere((e) => e.id == item.id);
          if (index >= 0) {
            existingItems[index] = item;
          } else {
            existingItems.add(item);
          }
        }
        state = AsyncValue.data(state.value!.copyWith(items: existingItems));
      }
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Get item by ID
  Future<ItemRepresentationModel?> getById(String id) async {
    try {
      final items = await _localRepository.getListItemRepresentationModel();
      final item = items.firstWhere(
        (e) => e.id == id,
        orElse: () => ItemRepresentationModel(), // return an empty model
      );
      return item.id != null ? item : null; // if ID is null, treat as not found
    } catch (_) {
      return null;
    }
  }

  /// Sync all items from remote API with pagination
  Future<void> syncFromRemote() async {
    state = const AsyncValue.loading();
    try {
      List<ItemRepresentationModel> allItems = [];
      int currentPage = 1;
      int? lastPage;

      do {
        final responseModel = await _webService.get(
          _remoteRepository.getItemRepresentationWithPagination(
            currentPage.toString(),
          ),
        );

        if (responseModel.isSuccess && responseModel.data != null) {
          // Insert/upsert fetched items into local DB and Hive
          await insertBulk(responseModel.data!, isInsertToPending: false);

          // Add to overall list
          allItems.addAll(responseModel.data!);

          // Determine pagination
          lastPage = responseModel.paginator?.lastPage;
          currentPage++;
        } else {
          // Stop if request fails or no data
          break;
        }
      } while (lastPage != null && currentPage <= lastPage);

      // Update state with all synced items
      state = AsyncValue.data(state.value!.copyWith(items: allItems));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Insert bulk helper
  Future<bool> insertBulk(
    List<ItemRepresentationModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );
      if (result) {
        final updatedItems = [...state.value!.items, ...list];
        state = AsyncValue.data(state.value!.copyWith(items: updatedItems));
      }
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Utility: get file with retry
  Future<File?> getFileWithRetry(
    String path, {
    int retries = 5,
    Duration delay = const Duration(seconds: 1),
  }) async {
    File file = File(path);
    for (int i = 0; i < retries; i++) {
      if (await file.exists()) return file;
      await Future.delayed(delay);
    }
    return null;
  }
}

/// Providers
final itemRepresentationProvider =
    AsyncNotifierProvider<ItemRepresentationNotifier, ItemRepresentationState>(
      () => ItemRepresentationNotifier(),
    );

final itemRepresentationByIdProvider =
    Provider.family<ItemRepresentationModel?, String>((ref, id) {
      final state = ref.watch(itemRepresentationProvider).value;
      if (state == null) return null;

      final item = state.items.firstWhere(
        (item) => item.id == id,
        orElse: () => ItemRepresentationModel(), // return a default model
      );

      return item.id != null ? item : null; // treat default model as null
    });

final sortedItemRepresentationsProvider =
    Provider<List<ItemRepresentationModel>>((ref) {
      final state = ref.watch(itemRepresentationProvider).value;
      if (state == null) return [];
      final sorted = List<ItemRepresentationModel>.from(state.items);
      sorted.sort((a, b) => (a.id ?? '').compareTo(a.id ?? ''));
      return sorted;
    });
