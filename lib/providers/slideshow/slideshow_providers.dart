import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
// import 'package:mts/data/models/slideshow/slideshow_list_response_model.dart';
import 'package:mts/domain/repositories/local/slideshow_repository.dart';
import 'package:mts/providers/slideshow/slideshow_state.dart';
import 'package:mts/core/enum/db_response_enum.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/slideshow/slideshow_list_response_model.dart';
import 'package:mts/data/models/user/user_model.dart';
// import 'package:mts/core/services/secondary_display_service.dart';
import 'package:mts/domain/repositories/remote/slideshow_repository.dart';
import 'package:mts/presentation/features/customer_display_preview/main_customer_display_show_receipt.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';
import 'package:mts/core/enum/data_enum.dart';

/// StateNotifier for Slideshow domain
///
/// Migrated from: slideshow_facade_impl.dart
///
class SlideshowNotifier extends StateNotifier<SlideshowState> {
  final LocalSlideshowRepository _localRepository;
  final SlideshowRepository _remoteRepository;
  final IWebService _webService;
  final Ref _ref;

  SlideshowNotifier({
    required LocalSlideshowRepository localRepository,
    required SlideshowRepository remoteRepository,
    required IWebService webService,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _ref = ref,
       super(const SlideshowState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<SlideshowModel> list, {
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

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<SlideshowModel> list) async {
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

  /// Delete all items from local storage
  Future<bool> deleteAll() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteAll();

      if (result) {
        state = state.copyWith(items: [], itemsFromHive: []);
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
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Get the latest slideshow model
  Future<Map<String, dynamic>> getLatestModel() async {
    try {
      return await _localRepository.getLatestModel();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return {};
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<SlideshowModel> newData, {
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
    List<SlideshowModel> list, {
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
      // Repository doesn't support getting all slideshows
      final items = <SlideshowModel>[];

      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get the list of slideshows (old notifier getter)
  List<SlideshowModel> get listSlideshow => state.items;

  /// Get the current slideshow (old notifier getter)
  SlideshowModel? get currentSlideshow => state.currentSlideshow;

  /// Get loading state (old notifier getter)
  bool get isLoading => state.isLoading;

  /// Get playing state (old notifier getter)
  bool get isPlaying => state.isPlaying;

  /// Get current slide index (old notifier getter)
  int get currentSlideIndex => state.currentSlideIndex;

  /// Set the list of slideshows (old notifier method)
  void setListSlideshow(List<SlideshowModel> slideshows) {
    state = state.copyWith(items: slideshows);
  }

  /// Set the current slideshow (old notifier method)
  void setCurrentSlideshow(SlideshowModel? slideshow) {
    state = state.copyWith(currentSlideshow: slideshow);
  }

  /// Add or update a slideshow in the list (old notifier method)
  void addOrUpdateList(SlideshowModel? slideshow) {
    if (slideshow == null) return;
    if (slideshow.id != null) {
      final currentItems = List<SlideshowModel>.from(state.items);
      final index = currentItems.indexWhere(
        (existing) => existing.id == slideshow.id,
      );
      if (index != -1) {
        currentItems[index] = slideshow;
      } else {
        currentItems.add(slideshow);
      }
      state = state.copyWith(items: currentItems, currentSlideshow: slideshow);
    }
  }

  /// Remove a slideshow from the list (old notifier method)
  void removeSlideshow(String slideshowId) {
    final updatedItems =
        state.items.where((slideshow) => slideshow.id != slideshowId).toList();
    state = state.copyWith(items: updatedItems);
  }

  /// Clear all slideshows (old notifier method)
  void clearSlideshows() {
    state = state.copyWith(items: [], currentSlideshow: null);
  }

  /// Set loading state (old notifier method)
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Set playing state (old notifier method)
  void setPlaying(bool playing) {
    state = state.copyWith(isPlaying: playing);
  }

  /// Set current slide index (old notifier method)
  void setCurrentSlideIndex(int index) {
    state = state.copyWith(currentSlideIndex: index);
  }

  /// Get slideshow by ID (old notifier method)
  SlideshowModel? getSlideshowById(String id) {
    try {
      return state.items.firstWhere((slideshow) => slideshow.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Start slideshow playback (old notifier method)
  void startSlideshow(SlideshowModel slideshow) {
    state = state.copyWith(
      currentSlideshow: slideshow,
      isPlaying: true,
      currentSlideIndex: 0,
    );
  }

  /// Stop slideshow playback (old notifier method)
  void stopSlideshow() {
    state = state.copyWith(isPlaying: false, currentSlideIndex: 0);
  }

  Future<Map<String, dynamic>> insert(SlideshowModel slideshow) async {
    return await _localRepository.insert(slideshow, true);
  }

  Future<int> update(SlideshowModel slideshow) async {
    return await _localRepository.update(slideshow, true);
  }

  Future<List<SlideshowModel>> syncFromRemote() async {
    try {
      final SlideshowListResponseModel response = await _webService.get(
        _remoteRepository.getSlideshows(),
      );
      if (response.isSuccess && response.data != null) {
        // isSynced property removed
        return response.data!;
      }
      return [];
    } catch (e) {
      prints('ERROR FETCHING SLIDESHOWS FROM API: $e');
      return [];
    }
  }

  Future<SlideshowModel> getModelById(String id) async {
    return await _localRepository.getModelById(id);
  }

  Future<SlideshowModel?> getSlideShowModel() async {
    final Map<String, dynamic> slideshowMap = await getLatestModel();

    final SlideshowModel? currSdModel = slideshowMap[DbResponseEnum.data];
    return currSdModel;
  }

  Future<void> updateSecondaryDisplay(Map<String, dynamic> data) async {
    // Check if we need to navigate to a new screen or just update the current one
    final String currRouteName = _ref.read(
      secondDisplayCurrentRouteNameProvider,
    );
    final secondDisplay = _ref.read(secondDisplayProvider.notifier);
    if (currRouteName != CustomerShowReceipt.routeName) {
      // If we're not already on the receipt screen, do a full navigation
      await secondDisplay.navigateSecondScreen(
        CustomerShowReceipt.routeName,
        data: data,
        isShowLoading: true,
      );
    } else {
      // If we're already on the receipt screen, use the optimized update method
      // This is much faster than doing a full navigation
      try {
        await secondDisplay.updateSecondaryDisplay(data);
      } catch (e) {
        prints('Error updating second display: $e');
        // Fall back to full navigation if the update fails
        await secondDisplay.navigateSecondScreen(
          CustomerShowReceipt.routeName,
          data: data,
          isShowLoading: true,
        );
      }
    }
  }

  Future<void> showOptimizedSecondDisplay(
    Map<String, dynamic> dataToTransfer,
  ) async {
    UserModel userModel = ServiceLocator.get<UserModel>();
    SlideshowModel? currSdModel = await getSlideShowModel();
    // Create a lightweight data package with essential information
    Map<String, dynamic> data = {
      // Add a unique update ID to track this update
      DataEnum.cartUpdateId: IdUtils.generateUUID(),
      // Add user model and slideshow data
      DataEnum.userModel: userModel.toJson(),
      DataEnum.slideshow: currSdModel?.toJson() ?? {},
      DataEnum.showThankYou: false,
      DataEnum.isCharged: false,
    };

    // Add data from the original dataToTransfer
    dataToTransfer.forEach((key, value) {
      if (!data.containsKey(key)) {
        data[key] = value;
      }
    });

    // Use the optimized update method for the second display
    await updateSecondaryDisplay(data);
  }
}

/// Provider for sorted items (computed provider)
final sortedSlideshowsProvider = Provider<List<SlideshowModel>>((ref) {
  final items = ref.watch(slideshowProvider).items;
  final sorted = List<SlideshowModel>.from(items);
  sorted.sort(
    (a, b) => (b.createdAt ?? DateTime(2000)).compareTo(
      a.createdAt ?? DateTime(2000),
    ),
  );
  return sorted;
});

/// Provider for slideshow domain
final slideshowProvider =
    StateNotifierProvider<SlideshowNotifier, SlideshowState>((ref) {
      return SlideshowNotifier(
        localRepository: ServiceLocator.get<LocalSlideshowRepository>(),
        remoteRepository: ServiceLocator.get<SlideshowRepository>(),
        webService: ServiceLocator.get<IWebService>(),
        ref: ref,
      );
    });
