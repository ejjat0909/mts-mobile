import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/enum/item_shape_enum.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/core/utils/color_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/core/utils/ui_utils.dart';
import 'package:mts/data/models/downloaded_file/downloaded_file_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/item_representation/item_representation_model.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';
import 'package:mts/main.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/layouts/hexagon_clipper.dart';
import 'package:mts/presentation/common/layouts/invalid_image_container.dart';
import 'package:mts/presentation/features/customer_display_preview/main_customer_display_show_receipt.dart';
import 'package:mts/presentation/features/variation_and_modifier/variation_and_modifier_dialogue.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';
import 'package:mts/presentation/features/home/home_screen.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/modifier_option/modifier_option_providers.dart';
import 'package:mts/providers/slideshow/slideshow_providers.dart';
import 'package:mts/providers/user/user_providers.dart';

/// This is an optimized version of the MenuItem class that improves performance
/// when sending data to the second display with advanced debouncing for spam taps.
class MenuItem extends ConsumerStatefulWidget {
  // Static variable to track if an operation is in progress
  static bool _isProcessing = false;
  // Static timer for throttling UI updates
  static Timer? _throttleTimer;
  // Static timer for debouncing second display updates (1.5 seconds)
  static Timer? _secondDisplayDebounceTimer;
  // Queue for pending operations
  static final Queue<Function> _pendingOperations = Queue<Function>();
  // Flag to track if queue is being processed
  static bool _isProcessingQueue = false;
  // Cache for common data
  static Map<String, dynamic> _cachedCommonData = {};
  // Flag to track if cache has been initialized
  static bool _isCacheInitialized = false;
  // Map to accumulate pending quantity changes for each item
  static final Map<String, Map<String, dynamic>> _pendingSecondDisplayUpdates =
      {};
  // Flag to track if second display update is pending
  static bool _isSecondDisplayUpdatePending = false;
  // Last sent state to second display for comparison

  final int index;
  final ItemModel? itemModel;
  final ItemRepresentationModel itemRepresentationModel;
  final DownloadedFileModel downloadedFileModel;

  const MenuItem({
    super.key,
    required this.itemRepresentationModel,
    required this.downloadedFileModel,
    required this.itemModel,
    required this.index,
  });

  /// Add an operation to the queue and process it
  static void _addToQueue(Function operation) {
    _pendingOperations.add(operation);
    _processQueue();
  }

  /// Process queue items one at a time
  static Future<void> _processQueue() async {
    if (_isProcessingQueue || _pendingOperations.isEmpty) return;

    _isProcessingQueue = true;

    while (_pendingOperations.isNotEmpty) {
      final operation = _pendingOperations.removeFirst();
      await operation();
      // Small delay between operations to allow UI to update
      await Future.delayed(const Duration(milliseconds: 10));
    }

    _isProcessingQueue = false;
  }

  /// Initialize cache with common data
  static void initializeCache(List items, List modifierOptions) {
    if (_isCacheInitialized) return;

    _cachedCommonData = {
      DataEnum.listItems: items.map((e) => e.toJson()).toList(),
      DataEnum.listMO: modifierOptions.map((e) => e.toJson()).toList(),
    };
    _isCacheInitialized = true;
  }

  static void reInitializeCache(List items, List modifierOptions) {
    // if (_isCacheInitialized) return;

    prints("REINITIALIZE CACHINGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG");

    _cachedCommonData = {
      DataEnum.listItems: items.map((e) => e.toJson()).toList(),
      DataEnum.listMO: modifierOptions.map((e) => e.toJson()).toList(),
    };
    //  _isCacheInitialized = true;
  }

  /// Update cache when data changes
  static void updateCache(String key, dynamic value) {
    _cachedCommonData[key] = value;
  }

  static Map<String, dynamic> getCachedCommonData() {
    return _cachedCommonData;
  }

  /// Check if MenuItem cache is initialized
  static bool isCacheInitialized() {
    return _isCacheInitialized;
  }

  /// Schedule a debounced second display update
  /// This method accumulates changes and only sends to second display after 1.5 seconds of inactivity
  static void _scheduleSecondDisplayUpdate(
    String itemId,
    Map<String, dynamic> dataToTransfer,
    Function sendToSecondDisplay,
  ) {
    // Cancel existing debounce timer
    _secondDisplayDebounceTimer?.cancel();

    // Accumulate the pending update data
    _pendingSecondDisplayUpdates[itemId] = dataToTransfer;
    _isSecondDisplayUpdatePending = true;

    prints(
      '📱 Scheduling second display update for item: $itemId (50ms debounce)',
    );

    // Set new debounce timer for 50 milliseconds for faster response
    _secondDisplayDebounceTimer = Timer(
      const Duration(milliseconds: 50),
      () async {
        prints(
          '⏰ Debounce timer triggered - sending accumulated updates to second display',
        );
        await _sendAccumulatedUpdatesToSecondDisplay(sendToSecondDisplay);
      },
    );
  }

  /// Send all accumulated updates to second display
  static Future<void> _sendAccumulatedUpdatesToSecondDisplay(
    Function sendToSecondDisplay,
  ) async {
    if (!_isSecondDisplayUpdatePending ||
        _pendingSecondDisplayUpdates.isEmpty) {
      return;
    }

    try {
      prints(
        '🚀 Sending ${_pendingSecondDisplayUpdates.length} accumulated updates to second display',
      );

      // Get the most recent update data (last item that was tapped)
      final String lastItemId = _pendingSecondDisplayUpdates.keys.last;
      final Map<String, dynamic> finalData =
          _pendingSecondDisplayUpdates[lastItemId]!;

      // Send the final accumulated state to second display
      await sendToSecondDisplay(finalData);

      // Store the sent state for future comparison

      prints('✅ Successfully sent accumulated updates to second display');
    } catch (e) {
      prints('❌ Error sending accumulated updates to second display: $e');
    } finally {
      // Clear pending updates
      _pendingSecondDisplayUpdates.clear();
      _isSecondDisplayUpdatePending = false;
    }
  }

  /// Cancel any pending second display updates
  static void cancelPendingSecondDisplayUpdates() {
    _secondDisplayDebounceTimer?.cancel();
    _pendingSecondDisplayUpdates.clear();
    _isSecondDisplayUpdatePending = false;
    prints('🚫 Cancelled pending second display updates');
  }

  /// Check if there are pending second display updates
  static bool hasPendingSecondDisplayUpdates() {
    return _isSecondDisplayUpdatePending &&
        _pendingSecondDisplayUpdates.isNotEmpty;
  }

  /// Prepare for payment screen transition by optimizing second display updates
  /// This method should be called when transitioning back to sales screen
  static void prepareForPaymentTransition() {
    // Cancel any pending second display updates to prevent conflicts
    cancelPendingSecondDisplayUpdates();

    // Reduce debounce timer for faster response after payment screen
    prints(
      '🔄 Preparing for payment transition - optimizing second display updates',
    );
  }

  /// Reset optimization settings after payment transition is complete
  static void resetAfterPaymentTransition() {
    // Clear any processing flags to ensure smooth operation
    _isProcessing = false;
    _isProcessingQueue = false;

    prints('✅ Payment transition complete - reset optimization settings');
  }

  @override
  ConsumerState<MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends ConsumerState<MenuItem> {
  DownloadedFileModel? dfmLocal = DownloadedFileModel();
  Uint8List? _cachedImageBytes;
  String? _currentImagePath;
  File? file;
  late final ItemNotifier _itemNotifier;
  final int miliseconds = 50;

  @override
  void initState() {
    super.initState();

    _itemNotifier = ref.read(itemProvider.notifier);

    // Ensure slideshow cache is available for consistent data across all screens
    if (hasSecondaryDisplay) {
      _ensureSlideshowCacheAvailable();
    }
  }

  /// Ensure slideshow cache is available for consistent data across all screens
  void _ensureSlideshowCacheAvailable() {
    // Use Future.microtask to avoid blocking initState
    Future.microtask(() async {
      if (!Home.isSlideshowCacheInitialized()) {
        prints(
          '🔄 Initializing slideshow cache from menu item for consistency',
        );
        await Home.ensureSlideshowCacheInitialized();
      } else {
        prints('✅ Slideshow cache already available for menu item');
      }
    });
  }

  Future<Uint8List?> loadImage(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      return await file.readAsBytes(); // Read the file as bytes
    } else {
      prints('Image file does not exist at path: $imagePath');
      return null;
    }
  }

  void getIRById(DownloadedFileModel dfm) async {
    dfmLocal = dfm;

    if (dfmLocal?.id != null && dfmLocal!.path != null) {
      if (_cachedImageBytes == null) {
        // Avoid reloading if already cached
        if (_currentImagePath != dfmLocal!.path) {
          _currentImagePath = dfmLocal!.path;
          Uint8List? imageData = await loadImage(dfmLocal!.path!);
          setState(() {
            _cachedImageBytes = imageData;
          });
        }
      } else {
        if (_currentImagePath != dfmLocal!.path) {
          _currentImagePath = dfmLocal!.path;
          Uint8List? imageData = await loadImage(dfmLocal!.path!);
          setState(() {
            _cachedImageBytes = imageData;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final saleItemsState = ref.watch(saleItemProvider);
    final saleItemsRiverpod = ref.watch(saleItemProvider.notifier);
    bool isEditMode = saleItemsState.isEditMode;

    if (widget.itemModel!.itemRepresentationId != null) {
      if (widget.itemRepresentationModel.id == null) {
        // Handle case where data is null
        return dontHaveRepresentation(
          isEditMode,
          context,
          ItemRepresentationModel(),
          saleItemsRiverpod,
        );
      }

      if (widget.itemRepresentationModel.useImage != null &&
          widget.itemRepresentationModel.useImage! &&
          widget.downloadedFileModel.id != null) {
        // Have image
        return haveAndUseImage(
          widget.itemRepresentationModel,
          widget.downloadedFileModel,
          isEditMode,
          context,
          _cachedImageBytes,
          file,
          saleItemsRiverpod,
        );
      } else if (widget.itemRepresentationModel.shape != null &&
          widget.itemRepresentationModel.shape != ItemShapeEnum.hexagon) {
        // Have shape (circle and rectangle)
        return circleAndRectangle(
          isEditMode,
          context,
          widget.itemRepresentationModel,
          saleItemsRiverpod,
        );
      } else if (widget.itemRepresentationModel.shape != null &&
          widget.itemRepresentationModel.shape == ItemShapeEnum.hexagon) {
        // Have shape hexagon
        return hexagon(
          isEditMode,
          context,
          widget.itemRepresentationModel,
          saleItemsRiverpod,
        );
      } else {
        // Default fallback
        return dontHaveRepresentation(
          isEditMode,
          context,
          widget.itemRepresentationModel,
          saleItemsRiverpod,
        );
      }
    }

    return dontHaveRepresentation(
      isEditMode,
      context,
      ItemRepresentationModel(),
      saleItemsRiverpod,
    );
  }

  Widget hexagon(
    bool isEditMode,
    BuildContext context,
    ItemRepresentationModel itemRepresentationModel,
    SaleItemNotifier saleItemsRiverpod,
  ) {
    bool isDarkColor = false;
    if (itemRepresentationModel.color != null) {
      isDarkColor = ColorUtils.isColorDark(itemRepresentationModel.color!);
    }
    return ScaleTap(
      onPressed: () {
        // Don't use async here to prevent blocking the animation
        // The animation will complete first, then onPress will handle the async work
        onPress(context, isEditMode, saleItemsRiverpod);
      },
      // Add ScaleTap configuration for smoother animation
      scaleMinValue: 0.95, // Less scaling for smoother feel
      duration: const Duration(milliseconds: 120), // Faster animation
      child: HexagonContainer(
        boxShadow: UIUtils.itemShadows,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color:
              itemRepresentationModel.color != null
                  ? ColorUtils.hexToColor(itemRepresentationModel.color!)
                  : white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.itemModel?.name ?? 'No Name',
              style: AppTheme.normalTextStyle(
                color: isDarkColor ? white : kBlackColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget circleAndRectangle(
    bool isEditMode,
    BuildContext context,
    ItemRepresentationModel itemRepresentationModel,
    SaleItemNotifier saleItemsRiverpod,
  ) {
    bool isDarkColor = false;
    if (itemRepresentationModel.color != null) {
      isDarkColor = ColorUtils.isColorDark(itemRepresentationModel.color!);
    }

    return ScaleTap(
      onPressed: () {
        // Don't use async here to prevent blocking the animation
        onPress(context, isEditMode, saleItemsRiverpod);
      },
      // Add ScaleTap configuration for smoother animation
      scaleMinValue: 0.95, // Less scaling for smoother feel
      duration: const Duration(milliseconds: 120), // Faster animation
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 17.5),
        decoration: BoxDecoration(
          shape:
              itemRepresentationModel.shape == ItemShapeEnum.square
                  ? BoxShape.rectangle
                  : BoxShape.circle,
          color:
              itemRepresentationModel.color != null
                  ? ColorUtils.hexToColor(itemRepresentationModel.color!)
                  : white,
          boxShadow: UIUtils.itemShadows,
          borderRadius:
              itemRepresentationModel.shape == ItemShapeEnum.square
                  ? BorderRadius.circular(7.5)
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.itemModel?.name ?? 'No Name',
              style: AppTheme.normalTextStyle(
                color: isDarkColor ? white : kBlackColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget haveAndUseImage(
    ItemRepresentationModel itemRepresentationModel,
    DownloadedFileModel dfm,
    bool isEditMode,
    BuildContext context,
    Uint8List? cachedImage,
    File? file,
    SaleItemNotifier saleItemsRiverpod,
  ) {
    getIRById(dfm);
    final imagePath = dfm.path;
    if (imagePath != null) {
      file = File(imagePath);
      if (!file.existsSync()) {
        file = null;
      }
    }

    return ScaleTap(
      // duration: Duration(milliseconds: miliseconds),
      onPressed: () {
        onPress(context, isEditMode, saleItemsRiverpod);
      },
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(7.5),
              boxShadow: UIUtils.itemShadows,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7.5),
              child:
                  (cachedImage != null)
                      ? Image.memory(
                        cachedImage,
                        fit: BoxFit.fitWidth,
                        errorBuilder: (_, __, ___) {
                          prints("CACHED IMAGE");
                          return InvalidImageContainer();
                        },
                      )
                      : (file != null)
                      ? Image.memory(
                        file.readAsBytesSync(),
                        fit: BoxFit.fitWidth,
                        errorBuilder: (_, __, ___) {
                          prints("FILE IMAGE");
                          return InvalidImageContainer();
                        },
                      )
                      : const InvalidImageContainer(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kBlackColor.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(7.5),
                  bottomRight: Radius.circular(7.5),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.itemModel?.name ?? 'No Name',
                    style: AppTheme.normalTextStyle(color: white),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget dontHaveRepresentation(
    bool isEditMode,
    BuildContext context,
    ItemRepresentationModel itemRepresentationModel,
    SaleItemNotifier saleItemsRiverpod,
  ) {
    return ScaleTap(
      onPressed: () {
        // Don't use async here to prevent blocking the animation
        onPress(context, isEditMode, saleItemsRiverpod);
      },
      // Add ScaleTap configuration for smoother animation
      scaleMinValue: 0.95, // Less scaling for smoother feel
      duration: const Duration(milliseconds: 120), // Faster animation
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(7.5),
          boxShadow: UIUtils.itemShadows,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.itemModel?.name ?? 'No Name',
              style: AppTheme.normalTextStyle(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Enhanced onPress method with debounced second display updates
  /// First display updates immediately, second display updates after 3s debounce
  void onPress(
    BuildContext context,
    bool isEditMode,
    SaleItemNotifier saleItemsRiverpod,
  ) {
    // Make this method non-async to prevent blocking the ScaleTap animation
    // The animation will complete first, then we'll schedule the data processing

    prints(
      '🎯 Item tapped: ${widget.itemModel?.name} (ID: ${widget.itemModel?.id})',
    );

    // If an operation is in progress, add this operation to the queue instead of executing immediately
    if (MenuItem._isProcessing) {
      prints('⏳ Adding tap to queue - operation in progress');
      MenuItem._addToQueue(
        () =>
            _processItemTapWithDebounce(context, isEditMode, saleItemsRiverpod),
      );
      return;
    }

    // Cancel any existing throttle timer
    MenuItem._throttleTimer?.cancel();

    // Set processing flag to prevent further immediate taps
    MenuItem._isProcessing = true;

    // Schedule the data processing after the animation completes
    // This is crucial for smooth animations with ScaleTap
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Cache should already be initialized from Home screen, but check as fallback
      if (!MenuItem._isCacheInitialized) {
        prints(
          "⚠️ MenuItem cache not initialized from Home screen, initializing now (fallback)",
        );
        final listItemFromNotifier =
            ref.read(itemProvider.notifier).getListItems;
        final listMoFromNotifier =
            ref.read(modifierOptionProvider.notifier).getModifierOptionList;
        MenuItem.initializeCache(listItemFromNotifier, listMoFromNotifier);
      } else {
        prints(
          "✅ MenuItem cache already initialized from Home screen - no lag!",
        );
      }

      // Add a minimal delay to ensure the animation completes
      await Future.delayed(const Duration(milliseconds: 100));

      // Now process the tap with debounced second display updates
      await _processItemTapWithDebounce(context, isEditMode, saleItemsRiverpod);
    });
  }

  /// Process the item tap with debounced second display updates
  /// This method runs after the animation completes and handles both immediate UI updates
  /// and debounced second display updates
  Future<void> _processItemTapWithDebounce(
    BuildContext context,
    bool isEditMode,
    SaleItemNotifier saleItemsRiverpod,
  ) async {
    try {
      // Pre-check if we should continue processing
      if (!mounted || isEditMode) {
        MenuItem._isProcessing = false;
        return;
      }

      prints(
        '🔄 Processing item tap with debounce for: ${widget.itemModel?.name}',
      );

      // Check if this is the first item addition and second display isn't initialized
      final bool isFirstItemAddition = !Home.isSecondDisplayInitialized();
      if (isFirstItemAddition) {
        prints(
          '🚀 First item addition detected - using immediate update for better UX',
        );
      }

      // Process the tap and get the data for both displays
      final Map<String, dynamic>? dataToTransfer = await _processItemTapCore(
        context,
        isEditMode,
        saleItemsRiverpod,
        updateSecondDisplayImmediately:
            isFirstItemAddition, // Update immediately for first item
      );

      // If we have data to transfer, handle second display update
      if (dataToTransfer != null && dataToTransfer.isNotEmpty) {
        final String itemId = widget.itemModel?.id?.toString() ?? 'unknown';

        if (isFirstItemAddition) {
          // For first item, update immediately to avoid lag perception
          prints('⚡ Immediate second display update for first item: $itemId');
          await showOptimizedSecondDisplay(dataToTransfer);
        } else {
          // For subsequent items, use debounced updates
          MenuItem._scheduleSecondDisplayUpdate(
            itemId,
            dataToTransfer,
            (Map<String, dynamic> data) => showOptimizedSecondDisplay(data),
          );
          prints(
            '📅 Scheduled debounced second display update for item: $itemId',
          );
        }
      }
    } finally {
      // Reset the processing flag after a minimal delay to allow animations to complete
      // Reduced from 30ms to 10ms to prevent interaction blocking
      MenuItem._throttleTimer = Timer(const Duration(milliseconds: 10), () {
        MenuItem._isProcessing = false;

        // Process the next item in the queue if there is one
        if (MenuItem._pendingOperations.isNotEmpty) {
          MenuItem._processQueue();
        }
      });
    }
  }

  /// Core item tap processing logic - separated for reusability
  /// This method handles the business logic of adding items to cart
  Future<Map<String, dynamic>?> _processItemTapCore(
    BuildContext context,
    bool isEditMode,
    SaleItemNotifier saleItemsRiverpod, {
    bool updateSecondDisplayImmediately = true,
  }) async {
    try {
      // Pre-check if we should continue processing
      if (!mounted || isEditMode) {
        return null;
      }

      // Process in a separate microtask to avoid blocking the UI thread
      Map<String, dynamic>? resultData;
      await Future.microtask(() async {
        ItemModel? itemModel = widget.itemModel;

        bool isItemExist = itemModel != null;
        if (isItemExist) {
          List<dynamic> listVariantOptions = [];
          List<VariantOptionModel> variantOptionList = [];

          if (widget.itemModel?.variantOptionJson != null) {
            listVariantOptions = jsonDecode(
              widget.itemModel?.variantOptionJson ?? '[]',
            );
            variantOptionList =
                listVariantOptions.map((item) {
                  return VariantOptionModel.fromJson(item);
                }).toList();
          }

          Map<String, dynamic> dataToTransfer = {};

          if (mounted) {
            if (variantOptionList.isNotEmpty &&
                widget.itemModel!.price != null) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext contextDialogue) {
                  String uuid = IdUtils.generateUUID();
                  return VariantAndModifierDialogue(
                    onDelete: null,
                    listVariantOptions: variantOptionList,
                    isFromMenuList: true,
                    listSelectedModifierOption: const [],
                    onSave: (
                      itemModel,
                      varOptModel,
                      listModOpt,
                      qty,
                      saleItem,
                      saleItemPrice,
                      comments,
                      listModifierOptionIds,
                      listModifierIds,
                      cost,
                    ) async {
                      final itemNotifier = ref.read(itemProvider.notifier);
                      VariantOptionModel? tempVOModel =
                          itemNotifier.getTempVariantOptionModel;
                      bool isCustomVariant =
                          tempVOModel != null
                              ? tempVOModel.price == null
                              : false;

                      // Remove unnecessary delay
                      // await Future.delayed(Duration.zero);
                      itemNotifier.resetTempQtyAndPrice();

                      // Use Riverpod to create and update sale items
                      dataToTransfer = await saleItemsRiverpod
                          .createAndUpdateSaleItems(
                            itemModel,
                            existingSaleItem: saleItem,
                            newSaleItemUuid: uuid,
                            varOptModel: varOptModel,
                            listModOpt: listModOpt,
                            qty: qty,
                            saleItemPrice: saleItemPrice,
                            comments: comments,
                            listModifierOptionIds: listModifierOptionIds,
                            pricePerItem: cost,
                            isCustomVariant: isCustomVariant,
                          );

                      // close dialogue variation and modifier
                      // NavigationUtils.pop(context); // dah handle dekat onSave
                      await Future.delayed(const Duration(milliseconds: 100));

                      /// [SHOW SECOND DISPLAY] - Conditional based on parameter
                      if (updateSecondDisplayImmediately) {
                        await showOptimizedSecondDisplay(dataToTransfer);
                      } else {
                        // Schedule debounced second display update for variant/modifier items
                        final String itemId =
                            widget.itemModel?.id?.toString() ?? 'unknown';
                        MenuItem._scheduleSecondDisplayUpdate(
                          itemId,
                          dataToTransfer,
                          (Map<String, dynamic> data) =>
                              showOptimizedSecondDisplay(data),
                        );
                        prints(
                          '📅 Scheduled debounced second display update for variant item: $itemId',
                        );
                      }

                      // Store data for potential debounced update
                      resultData = dataToTransfer;
                    },
                    saleItemModel: null,
                    itemModel: widget.itemModel!,
                    selectedModifierOptionIds: const [],
                  );
                },
              );
            } else if (widget.itemModel!.price == null) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext contextDialogue) {
                  String uuid = IdUtils.generateUUID();
                  return VariantAndModifierDialogue(
                    onDelete: null,
                    listVariantOptions: variantOptionList,
                    isFromMenuList: true,
                    listSelectedModifierOption: const [],
                    onSave: (
                      itemModel,
                      varOptModel,
                      listModOpt,
                      qty,
                      saleItem,
                      saleItemPrice,
                      comments,
                      listModifierOptionIds,
                      listModifierIds,
                      cost,
                    ) async {
                      final itemNotifier = ref.read(itemProvider.notifier);
                      VariantOptionModel? tempVOModel =
                          itemNotifier.getTempVariantOptionModel;
                      bool isCustomVariant =
                          tempVOModel != null
                              ? tempVOModel.price == null
                              : false;

                      // Remove unnecessary delay
                      // await Future.delayed(Duration.zero);
                      itemNotifier.resetTempQtyAndPrice();

                      // Use Riverpod to create and update sale items
                      dataToTransfer = await saleItemsRiverpod
                          .createAndUpdateSaleItems(
                            itemModel,
                            existingSaleItem: saleItem,
                            newSaleItemUuid: uuid,
                            varOptModel: varOptModel,
                            listModOpt: listModOpt,
                            qty: qty,
                            saleItemPrice: saleItemPrice,
                            comments: comments,
                            listModifierOptionIds: listModifierOptionIds,
                            pricePerItem: cost,
                            isCustomVariant: isCustomVariant,
                          );

                      // close dialogue variation and modifier
                      // NavigationUtils.pop(context); // dah Handle dekat onSave
                      await Future.delayed(const Duration(milliseconds: 100));

                      /// [SHOW SECOND DISPLAY] - Conditional based on parameter
                      if (updateSecondDisplayImmediately) {
                        await showOptimizedSecondDisplay(dataToTransfer);
                      } else {
                        // Schedule debounced second display update for variant/modifier items
                        final String itemId =
                            widget.itemModel?.id?.toString() ?? 'unknown';
                        MenuItem._scheduleSecondDisplayUpdate(
                          itemId,
                          dataToTransfer,
                          (Map<String, dynamic> data) =>
                              showOptimizedSecondDisplay(data),
                        );
                        prints(
                          '📅 Scheduled debounced second display update for variant item: $itemId',
                        );
                      }

                      // Store data for potential debounced update
                      resultData = dataToTransfer;
                    },
                    saleItemModel: null,
                    itemModel: widget.itemModel!,
                    selectedModifierOptionIds: const [],
                  );
                },
              );
            } else {
              // No variant, add directly to list
              if (!isEditMode) {
                if (widget.itemModel!.soldBy == ItemSoldByEnum.item) {
                  // Remove unnecessary delay
                  // await Future.delayed(Duration(milliseconds: 50));
                  String uuid = IdUtils.generateUUID();

                  // Use Riverpod to add the item and get the data in one step
                  dataToTransfer = await saleItemsRiverpod.createAndUpdateSaleItems(
                    widget.itemModel!,
                    saleItemPrice: widget.itemModel!.price ?? 0.00,
                    pricePerItem: widget.itemModel?.cost ?? 0.00,
                    newSaleItemUuid: uuid,
                    qty: 1,
                    comments: '',
                    listModifierOptionIds: [],
                    isCustomVariant: false,
                    existingSaleItem: null,
                  );

                  /// [SHOW SECOND DISPLAY] - Conditional based on parameter
                  if (updateSecondDisplayImmediately) {
                    await showOptimizedSecondDisplay(dataToTransfer);
                  }

                  // Store data for potential debounced update
                  resultData = dataToTransfer;
                } else {
                  // if item == MEASUREMENT
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext contextDialogue) {
                      String uuid = IdUtils.generateUUID();
                      return VariantAndModifierDialogue(
                        onDelete: null,
                        listVariantOptions: variantOptionList,
                        isFromMenuList: true,
                        listSelectedModifierOption: const [],
                        onSave: (
                          itemModel,
                          varOptModel,
                          listModOpt,
                          qty,
                          saleItem,
                          saleItemPrice,
                          comments,
                          listModifierOptionIds,
                          listModifierIds,
                          cost,
                        ) async {
                          final itemNotifier = ref.read(itemProvider.notifier);
                          VariantOptionModel? tempVOModel =
                              itemNotifier.getTempVariantOptionModel;
                          bool isCustomVariant =
                              tempVOModel != null
                                  ? tempVOModel.price == null
                                  : false;

                          // Remove unnecessary delay
                          // await Future.delayed(Duration.zero);
                          itemNotifier.resetTempQtyAndPrice();

                          // Use Riverpod to create and update sale items
                          dataToTransfer = await saleItemsRiverpod
                              .createAndUpdateSaleItems(
                                widget.itemModel!,
                                newSaleItemUuid: uuid,
                                qty: qty,
                                pricePerItem: cost,
                                existingSaleItem: null,
                                saleItemPrice: saleItemPrice,
                                comments: comments,
                                listModifierOptionIds: [],
                                isCustomVariant: isCustomVariant,
                              );

                          // close dialogue variation and modifier
                          // NavigationUtils.pop(context); // dah handle dekat onSave
                          await Future.delayed(
                            const Duration(milliseconds: 100),
                          );

                          /// [SHOW SECOND DISPLAY] - Conditional based on parameter
                          if (updateSecondDisplayImmediately) {
                            await showOptimizedSecondDisplay(dataToTransfer);
                          } else {
                            // Schedule debounced second display update for variant/modifier items
                            final String itemId =
                                widget.itemModel?.id?.toString() ?? 'unknown';
                            MenuItem._scheduleSecondDisplayUpdate(
                              itemId,
                              dataToTransfer,
                              (Map<String, dynamic> data) =>
                                  showOptimizedSecondDisplay(data),
                            );
                            prints(
                              '📅 Scheduled debounced second display update for measurement item: $itemId',
                            );
                          }

                          // Store data for potential debounced update
                          resultData = dataToTransfer;
                        },
                        saleItemModel: null,
                        itemModel: widget.itemModel!,
                        selectedModifierOptionIds: const [],
                      );
                    },
                  );
                }
              }
            }
          }
        } else {
          prints('ITEM HAS BEEN DELETED FROM MANAGEMENT HUB');

          CustomDialog.show(
            context,
            icon: FontAwesomeIcons.trashCan,
            title: 'itemDeleted'.tr(),
            description: 'itemHasBeenDeletedFromManagementHub'.tr(
              args: [widget.itemModel?.name ?? ''],
            ),
            btnOkText: 'OK'.tr(),
            btnOkOnPress: () => NavigationUtils.pop(context, true),
          );
        }
      }); // Close the Future.microtask

      return resultData;
    } catch (e) {
      prints('❌ Error in _processItemTapCore: $e');
      return null;
    }
  }

  /// Helper method to optimize data transfer to second display
  Future<void> showOptimizedSecondDisplay(
    Map<String, dynamic> dataToTransfer,
  ) async {
    if (!mounted) return;

    // Use cached slideshow model from home_screen.dart to avoid DB calls
    SlideshowModel? currSdModel = Home.getCachedSlideshowModel();

    // If cache is not available, fallback to provider
    if (currSdModel == null) {
      prints('⚠️ Slideshow cache not available, falling back to provider');
      currSdModel =
          await ref.read(slideshowProvider.notifier).getSlideShowModel();
    } else {
      prints('✅ Using cached slideshow model for second display');
    }

    // Create a lightweight data package with only essential information
    final currentUser =
        ref.read(userProvider.notifier).currentUser ?? UserModel();

    Map<String, dynamic> data = {
      // Add only the specific item being added
      DataEnum.currentItem: widget.itemModel!.toJson(),
      // Add a unique update ID to track this update
      DataEnum.cartUpdateId: IdUtils.generateUUID(),
      // Add user model and slideshow data
      DataEnum.userModel: currentUser.toJson(),
      DataEnum.slideshow: currSdModel?.toJson() ?? {},
      DataEnum.showThankYou: false,
      DataEnum.isCharged: false,
    };

    // Add any specific transaction data from the original dataToTransfer
    // but avoid duplicating large data structures
    dataToTransfer.forEach((key, value) {
      if (key != DataEnum.listItems &&
          key != DataEnum.listMO &&
          !data.containsKey(key)) {
        data[key] = value;
      }
    });

    // Use cached common data instead of regenerating it every time
    if (MenuItem._cachedCommonData.isNotEmpty) {
      // Only add cached data if it's not already in the data package
      MenuItem._cachedCommonData.forEach((key, value) {
        if (!data.containsKey(key)) {
          data[key] = value;
        }
      });
    }

    // Use the optimized update method for the second display
    await updateSecondaryDisplay(data);
  }

  /// Optimized method to update the second display without full navigation
  Future<void> updateSecondaryDisplay(Map<String, dynamic> data) async {
    // Check if we need to navigate to a new screen or just update the current one
    final String currRouteName = ref.read(
      secondDisplayCurrentRouteNameProvider,
    );
    final secondDisplay = ref.read(secondDisplayProvider.notifier);
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
}
