import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/models/downloaded_file/downloaded_file_model.dart';
import 'package:mts/data/repositories/local/local_downloaded_file_repository_impl.dart';
import 'package:mts/domain/repositories/local/downloaded_file_repository.dart';
import 'package:mts/providers/downloaded_file/downloaded_file_state.dart';

/// StateNotifier for DownloadedFile domain
///
/// Migrated from: downloaded_file_facade_impl.dart
class DownloadedFileNotifier extends StateNotifier<DownloadedFileState> {
  final LocalDownloadedFileRepository _localRepository;

  DownloadedFileNotifier({
    required LocalDownloadedFileRepository localRepository,
  }) : _localRepository = localRepository,
       super(const DownloadedFileState());

  /// Insert a single item
  Future<int> insert(DownloadedFileModel downloadedFileModel) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.insert(downloadedFileModel, true);

      if (result > 0) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Update an existing item
  Future<int> update(DownloadedFileModel downloadedFileModel) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.update(downloadedFileModel, true);

      if (result > 0) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<DownloadedFileModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Get all items from local storage
  Future<List<DownloadedFileModel>> getListDownloadedFile() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListDownloadedFile();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Get items from Hive cache (sync)
  List<DownloadedFileModel> getListDownloadedFilesFromHive() {
    try {
      final items = _localRepository.getListDownloadedFilesFromHive();
      return items;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get a downloaded file by URL
  Future<DownloadedFileModel?> getDownloadedFileByUrl(String url) async {
    try {
      return await _localRepository.getDownloadedFileByUrl(url);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Get downloaded files by model ID
  Future<List<DownloadedFileModel>> getDownloadedFilesByModelId(
    String modelId,
  ) async {
    try {
      return await _localRepository.getDownloadedFilesByModelId(modelId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get printed logo path
  Future<DownloadedFileModel> getPrintedLogoPath() async {
    try {
      return await _localRepository.getPrintedLogoPath();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return DownloadedFileModel();
    }
  }

  /// Get downloaded file by image path and URL
  Future<DownloadedFileModel> getByImagePathAndUrl({
    required String imagePath,
    required String downloadUrl,
  }) async {
    try {
      return await _localRepository.getByImagePathAndUrl(
        imagePath: imagePath,
        downloadUrl: downloadUrl,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return DownloadedFileModel();
    }
  }

  /// Get local image path for a given URL
  ///
  /// Business logic: Searches downloaded files for matching URL and returns local path
  Future<String> getImagePath(String? imageUrl) async {
    try {
      if (imageUrl == null || imageUrl.isEmpty) {
        return '';
      }

      List<DownloadedFileModel> listDfm = await getListDownloadedFile();

      String imagePath =
          listDfm
              .firstWhere(
                (element) =>
                    element.url == imageUrl &&
                    element.isDownloaded! &&
                    element.path != null,
                orElse: () => DownloadedFileModel(),
              )
              .path ??
          '';

      return imagePath;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return '';
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<DownloadedFileModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete a single item by ID
  Future<int> delete(String id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.delete(id, true);

      if (result > 0) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Find an item by its ID
  Future<DownloadedFileModel?> getDownloadedFileModelById(String itemId) async {
    try {
      final items = await _localRepository.getListDownloadedFile();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => DownloadedFileModel(),
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

  /// Remove bulk items from Hive box by IDs
  Future<bool> removeBulkFromHiveBox(List<String> ids) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.removeBulkFromHiveBox(ids);

      if (result) {
        await _loadItems();
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
    List<DownloadedFileModel> list, {
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
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Internal helper to load items and update state
  Future<void> _loadItems() async {
    try {
      final items = await _localRepository.getListDownloadedFile();
      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get list of downloaded files (old notifier getter)
  List<DownloadedFileModel> get getListDownloadedFiles => state.items;
}

/// Provider for sorted items (computed provider)
final sortedDownloadedFilesProvider = Provider<List<DownloadedFileModel>>((
  ref,
) {
  final items = ref.watch(downloadedFileProvider).items;
  final sorted = List<DownloadedFileModel>.from(items);
  sorted.sort((a, b) {
    final aTime = a.createdAt;
    final bTime = b.createdAt;
    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    return aTime.compareTo(bTime);
  });
  return sorted;
});

/// Provider for downloadedFile domain
final downloadedFileProvider =
    StateNotifierProvider<DownloadedFileNotifier, DownloadedFileState>((ref) {
      return DownloadedFileNotifier(
        localRepository: ref.read(downloadedFileLocalRepoProvider),
      );
    });

/// Provider for downloadedFile by ID (family provider for indexed lookups)
final downloadedFileByIdProvider =
    FutureProvider.family<DownloadedFileModel?, String>((ref, id) async {
      final notifier = ref.watch(downloadedFileProvider.notifier);
      return notifier.getDownloadedFileModelById(id);
    });

/// Provider for downloaded file by URL (async family provider)
final downloadedFileByUrlProvider =
    FutureProvider.family<DownloadedFileModel?, String>((ref, url) async {
      final notifier = ref.watch(downloadedFileProvider.notifier);
      return notifier.getDownloadedFileByUrl(url);
    });

/// Provider for downloaded files by model ID (async family provider)
final downloadedFilesByModelIdProvider =
    FutureProvider.family<List<DownloadedFileModel>, String>((
      ref,
      modelId,
    ) async {
      final notifier = ref.watch(downloadedFileProvider.notifier);
      return notifier.getDownloadedFilesByModelId(modelId);
    });

/// Provider for downloaded files from Hive cache (synchronous)
final downloadedFilesFromHiveProvider = Provider<List<DownloadedFileModel>>((
  ref,
) {
  final notifier = ref.watch(downloadedFileProvider.notifier);
  return notifier.getListDownloadedFilesFromHive();
});

/// Provider for image path by URL (async family provider)
final imagePathByUrlProvider = FutureProvider.family<String, String>((
  ref,
  imageUrl,
) async {
  final notifier = ref.watch(downloadedFileProvider.notifier);
  return notifier.getImagePath(imageUrl);
});

/// Provider for downloaded files count (computed provider)
final downloadedFilesCountProvider = Provider<int>((ref) {
  final items = ref.watch(downloadedFileProvider).items;
  return items.length;
});

/// Provider for successfully downloaded files (computed provider)
final successfullyDownloadedFilesProvider = Provider<List<DownloadedFileModel>>(
  (ref) {
    final items = ref.watch(downloadedFileProvider).items;
    return items.where((file) => file.isDownloaded == true).toList();
  },
);

/// Provider for failed downloads (computed provider)
final failedDownloadsProvider = Provider<List<DownloadedFileModel>>((ref) {
  final items = ref.watch(downloadedFileProvider).items;
  return items.where((file) => file.isDownloaded == false).toList();
});

/// Provider for checking if file exists by URL (computed family provider)
final fileExistsByUrlProvider = Provider.family<bool, String>((ref, url) {
  final items = ref.watch(downloadedFileProvider).items;
  return items.any((file) => file.url == url && file.isDownloaded == true);
});

/// Provider for files with local paths (computed provider)
final filesWithLocalPathsProvider = Provider<List<DownloadedFileModel>>((ref) {
  final items = ref.watch(downloadedFileProvider).items;
  return items
      .where((file) => file.path != null && file.path!.isNotEmpty)
      .toList();
});
