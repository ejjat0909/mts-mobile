import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/core/enum/page_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/features/customer_display_preview/main_customer_display_show_receipt.dart';
import 'package:mts/presentation/features/sales/components/choose_menu.dart';
import 'package:mts/presentation/features/sales/components/order_list_sales.dart';
import 'package:mts/presentation/features/variation_and_modifier/variation_and_modifier_dialogue.dart';
import 'package:mts/providers/barcode_scanner/barcode_scanner_providers.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/sale_item/sale_item_state.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';
import 'package:mts/presentation/features/home/home_screen.dart';
import 'package:mts/providers/page_item/page_item_providers.dart';
import 'package:mts/providers/slideshow/slideshow_providers.dart';
import 'package:mts/providers/tax/tax_providers.dart';
import 'package:mts/providers/user/user_providers.dart';

class SalesScreen extends ConsumerStatefulWidget {
  // Static timer for debouncing second display updates (1.5 seconds)
  static Timer? _secondDisplayDebounceTimer;
  // Queue for pending operations
  static final Queue<Function> _pendingOperations = Queue<Function>();
  // Flag to track if queue is being processed
  static bool _isProcessingQueue = false;
  // Map to accumulate pending quantity changes for each item
  static final Map<String, Map<String, dynamic>> _pendingSecondDisplayUpdates =
      {};
  // Flag to track if second display update is pending
  static bool _isSecondDisplayUpdatePending = false;
  // Track last processed barcode to prevent duplicates
  static String? _lastProcessedBarcode;
  static DateTime? _lastProcessedTime;
  final BuildContext homeContext;

  const SalesScreen({super.key, required this.homeContext});

  /// Add an operation to the queue and process it
  static void _addToQueue(Function operation) {
    _pendingOperations.add(operation);
    prints(
      '📋 Added operation to queue. Queue size: ${_pendingOperations.length}',
    );
    _processQueue();
  }

  /// Process queue items one at a time
  static Future<void> _processQueue() async {
    if (_isProcessingQueue || _pendingOperations.isEmpty) return;

    _isProcessingQueue = true;
    int processedCount = 0;
    final int initialQueueSize = _pendingOperations.length;

    prints(
      '🚀 Starting queue processing. Initial queue size: $initialQueueSize',
    );

    try {
      while (_pendingOperations.isNotEmpty) {
        final operation = _pendingOperations.removeFirst();
        processedCount++;
        try {
          await operation();
          prints(
            '✅ Successfully processed queued operation $processedCount/$initialQueueSize',
          );
        } catch (e) {
          prints(
            '❌ Error processing queued operation $processedCount/$initialQueueSize: $e',
          );
          // Continue processing other operations even if one fails
        }
        // Small delay between operations to allow UI to update
        await Future.delayed(const Duration(milliseconds: 10));
      }
    } finally {
      _isProcessingQueue = false;
      prints(
        '🏁 Queue processing completed. Processed: $processedCount operations. Remaining queue size: ${_pendingOperations.length}',
      );
    }
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
      '📱 Scheduling second display update for item: $itemId (1.5s debounce)',
    );

    // Set new debounce timer for 1.5 seconds
    _secondDisplayDebounceTimer = Timer(
      const Duration(milliseconds: 100),
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

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  ItemModel? itemModel;
  TextEditingController searchController = TextEditingController();
  // SecondaryDisplayService replaced by secondDisplayProvider.notifier usage
  late final BarcodeScannerNotifier _barcodeScannerNotifier;
  late final ItemNotifier _itemNotifier;
  late final TaxNotifier _taxNotifier;

  @override
  void initState() {
    super.initState();

    _barcodeScannerNotifier = ref.read(barcodeScannerProvider.notifier);
    _itemNotifier = ref.read(itemProvider.notifier);
    _taxNotifier = ref.read(taxProvider.notifier);

    _barcodeScannerNotifier.initializeForSalesScreen();
    // Listen to sales screen barcode changes via Riverpod
    ref.listen<String?>(salesScreenBarcodeProvider, (prev, next) {
      if (mounted && next != null) {
        _handleBarcodeScanned();
      }
    });
  }

  void _onSearchChanged() {}

  /// Handle barcode scanner events
  void _handleBarcodeScanned() {
    if (!mounted) return;

    final barcode = _barcodeScannerNotifier.salesScreenBarcode;
    final isProcessing = _barcodeScannerNotifier.isProcessing;

    if (barcode == null || isProcessing) return;

    // Check for duplicate processing within a very short time window (10ms)
    // This prevents true duplicates while allowing rapid intentional scanning
    final now = DateTime.now();
    if (SalesScreen._lastProcessedBarcode == barcode &&
        SalesScreen._lastProcessedTime != null &&
        now.difference(SalesScreen._lastProcessedTime!).inMilliseconds < 10) {
      prints('🚫 Duplicate barcode detected (within 10ms), skipping: $barcode');
      return;
    }

    prints('🔍 Barcode scanned: $barcode (${now.millisecondsSinceEpoch})');

    // Update tracking variables
    SalesScreen._lastProcessedBarcode = barcode;
    SalesScreen._lastProcessedTime = now;

    // Process the barcode synchronously to avoid timing issues
    _processBarcodeSync(barcode);
    _itemNotifier.setSearchItemName(barcode);
    _barcodeScannerNotifier.clearScannedItem();
    // Clear the scanned item after a short delay to allow other components
    // (like search functionality) to read the barcode value
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        prints('🧹 Cleared scanned barcode after processing: $barcode');
      }
    });
  }

  /// Process barcode synchronously to avoid race conditions
  void _processBarcodeSync(String barcode) {
    if (!mounted) return;

    // First, find item by barcode in sales screen
    final multipleItems = _barcodeScannerNotifier.findItemsByBarcode(barcode);

    if (multipleItems.length == 1) {
      // Only one partial match found, treat as exact match
      prints('📦 Processing single partial match: ${multipleItems.first.name}');
      _handleSingleItemFound(multipleItems.first);
    } else if (multipleItems.length > 1) {
      // Multiple matches found, trigger search
      prints(
        '🔍 Multiple items found (${multipleItems.length}), triggering search for: $barcode',
      );
      _handleItemNotFoundOrMultiple(barcode);
    } else {
      // No item barcode matches found, search for variant barcodes
      prints(
        '🔍 No item barcode matches found, searching variant barcodes for: $barcode',
      );
      final variantMatch = _barcodeScannerNotifier.findItemByVariantBarcode(
        barcode,
      );

      if (variantMatch != null) {
        // Found a variant barcode match
        final ItemModel item = variantMatch['item'] as ItemModel;
        final VariantOptionModel variantOption =
            variantMatch['variantOption'] as VariantOptionModel;

        prints(
          '✅ Found variant barcode match: ${item.name} - ${variantOption.name}',
        );
        if (item.soldBy == ItemSoldByEnum.item) {
          if (variantOption.price != null) {
            _handleVariantBarcodeFound(item, variantOption);
          } else {
            _handleSingleItemFound(item);
          }
        } else {
          _handleSingleItemFound(item);
        }
      } else {
        // No matches found at all
        prints(
          '🔍 No items or variants found, triggering search for: $barcode',
        );
        _handleItemNotFoundOrMultiple(barcode);
      }
    }
  }

  /// Handle when a single item is found by barcode
  void _handleSingleItemFound(ItemModel item) {
    prints('✅ Single item found: ${item.name}');

    // Get the required notifiers and state
    final saleItemsRiverpod = ref.read(saleItemProvider.notifier);
    final saleItemsState = ref.read(saleItemProvider);
    final isEditMode = saleItemsState.isEditMode;

    if (isEditMode) {
      prints('⚠️ Cannot add item in edit mode');
      return;
    }

    // Always add to queue to ensure proper sequential processing
    // This prevents race conditions and ensures all scanned items are processed
    prints(
      '📝 Adding item to processing queue: ${item.name} (Queue size before: ${SalesScreen._pendingOperations.length})',
    );
    SalesScreen._addToQueue(
      () => _processItemTapWithDebounce(
        context,
        isEditMode,
        saleItemsRiverpod,
        item,
      ),
    );
    prints(
      '📝 Item added to queue. New queue size: ${SalesScreen._pendingOperations.length}',
    );
  }

  /// Handle when a variant barcode is found
  void _handleVariantBarcodeFound(
    ItemModel item,
    VariantOptionModel variantOption,
  ) {
    prints('✅ Variant barcode found: ${item.name} - ${variantOption.name}');

    // Get the required notifiers and state
    final saleItemsRiverpod = ref.read(saleItemProvider.notifier);
    final saleItemsState = ref.read(saleItemProvider);
    final isEditMode = saleItemsState.isEditMode;

    if (isEditMode) {
      prints('⚠️ Cannot add item in edit mode');
      return;
    }

    // Always add to queue to ensure proper sequential processing
    // This prevents race conditions and ensures all scanned variants are processed
    prints(
      '📝 Adding variant to processing queue: ${item.name} - ${variantOption.name} (Queue size before: ${SalesScreen._pendingOperations.length})',
    );
    SalesScreen._addToQueue(
      () => _processVariantBarcodeWithDebounce(
        context,
        isEditMode,
        saleItemsRiverpod,
        item,
        variantOption,
        saleItemsState,
      ),
    );
    prints(
      '📝 Variant added to queue. New queue size: ${SalesScreen._pendingOperations.length}',
    );
  }

  Future<void> _processItemTapWithDebounce(
    BuildContext context,
    bool isEditMode,
    SaleItemNotifier saleItemsRiverpod,
    ItemModel itemModel,
  ) async {
    // Pre-check if we should continue processing
    if (!mounted || isEditMode) {
      return;
    }

    prints('🔄 Processing item tap with debounce for: ${itemModel.name}');

    // Process the tap and get the data for both displays
    final Map<String, dynamic>? dataToTransfer = await _processItemTapCore(
      context,
      isEditMode,
      saleItemsRiverpod,
      updateSecondDisplayImmediately: false,
      itemModel: itemModel,
    );

    // If we have data to transfer, schedule the debounced second display update
    if (dataToTransfer != null && dataToTransfer.isNotEmpty) {
      final String itemId = itemModel.id?.toString() ?? 'unknown';

      // Schedule debounced update for second display
      SalesScreen._scheduleSecondDisplayUpdate(
        itemId,
        dataToTransfer,
        (Map<String, dynamic> data) =>
            showOptimizedSecondDisplay(data, itemModel),
      );

      prints('📅 Scheduled debounced second display update for item: $itemId');
    }
  }

  Future<void> _processVariantBarcodeWithDebounce(
    BuildContext context,
    bool isEditMode,
    SaleItemNotifier saleItemsRiverpod,
    ItemModel itemModel,
    VariantOptionModel variantOption,
    SaleItemState saleItemsState,
  ) async {
    // Pre-check if we should continue processing
    if (!mounted || isEditMode) {
      return;
    }

    prints(
      '🔄 Processing variant barcode with debounce for: ${itemModel.name} - ${variantOption.name}',
    );

    // Process the variant barcode and get the data for both displays
    final Map<String, dynamic>? dataToTransfer =
        await _processVariantBarcodeCore(
          context,
          isEditMode,
          saleItemsRiverpod,
          itemModel,
          variantOption,
          saleItemsState,
        );

    // If we have data to transfer, schedule the debounced second display update
    if (dataToTransfer != null && dataToTransfer.isNotEmpty) {
      final String itemId = itemModel.id?.toString() ?? 'unknown';

      // Schedule debounced update for second display
      SalesScreen._scheduleSecondDisplayUpdate(
        itemId,
        dataToTransfer,
        (Map<String, dynamic> data) =>
            showOptimizedSecondDisplay(data, itemModel),
      );

      prints(
        '📅 Scheduled debounced second display update for variant item: $itemId',
      );
    }
  }

  /// Process variant barcode - automatically select the variant and add to cart
  /// This method handles the business logic of adding items with pre-selected variants to cart
  Future<Map<String, dynamic>?> _processVariantBarcodeCore(
    BuildContext context,
    bool isEditMode,
    SaleItemNotifier saleItemsRiverpod,
    ItemModel itemModel,
    VariantOptionModel variantOption,
    SaleItemState saleItemsState,
  ) async {
    try {
      // Pre-check if we should continue processing
      if (!mounted || isEditMode) {
        return null;
      }

      prints(
        '🔄 Processing variant barcode core for: ${itemModel.name} - ${variantOption.name}',
      );

      // Process in a separate microtask to avoid blocking the UI thread
      Map<String, dynamic> resultData = {};
      await Future.microtask(() async {
        List<TaxModel> taxModels = [];
        taxModels = _taxNotifier.getAllTaxModelsForThatItem(
          itemModel,
          taxModels,
        );

        double saleItemPrice = variantOption.price ?? 0.0;
        double pricePerItem = variantOption.cost ?? 0.0;
        double qty = 1.0;
        String comments = '';
        String incomingSaleItemId = IdUtils.generateHashId(
          variantOption.id,
          [],
          comments,
          itemModel.id!,
          cost: pricePerItem,
          variantPrice: variantOption.price,
        );

        List<SaleItemModel> saleItemsExist =
            saleItemsState.saleItems
                .where((saleItem) => saleItem.id == incomingSaleItemId)
                .toList();

        bool exist =
            saleItemsExist.isNotEmpty &&
            saleItemsExist[0].id == incomingSaleItemId;

        if (exist) {
          resultData = await saleItemsRiverpod.updateSaleItemHaveVariantAndModifier(
            varOptModel: variantOption,
            comments: comments,
            listModifierOptionIds: [],
            itemModel: itemModel,
            pricePerItem: pricePerItem,
            saleItemPrice: saleItemPrice,
            taxModels: taxModels,
            qty: qty,
            isCustomVariant: false,
          );
        } else {
          resultData = await saleItemsRiverpod.insertSaleItemHaveVariantAndModifier(
            varOptModel: variantOption,
            comments: comments,
            listModifierOptionIds: [], // no modifier since scan from barcode
            itemModel: itemModel,
            pricePerItem: pricePerItem,
            saleItemPrice: saleItemPrice,
            taxModels: taxModels,
            qty: qty,
            isCustomVariant: false,
          );
        }
      });

      return resultData;
    } catch (e) {
      prints('❌ Error in _processVariantBarcodeCore: $e');
      return null;
    }
  }

  /// Process scanned item similar to SalesScreen's core logic
  /// Core item tap processing logic - separated for reusability
  /// This method handles the business logic of adding items to cart
  Future<Map<String, dynamic>?> _processItemTapCore(
    BuildContext context,
    bool isEditMode,
    SaleItemNotifier saleItemsRiverpod, {
    bool updateSecondDisplayImmediately = true,
    ItemModel? itemModel,
  }) async {
    try {
      // Pre-check if we should continue processing
      if (!mounted || isEditMode) {
        return null;
      }

      // Process in a separate microtask to avoid blocking the UI thread
      Map<String, dynamic>? resultData;
      await Future.microtask(() async {
        bool isItemExist = itemModel != null;
        if (isItemExist) {
          List<dynamic> listVariantOptions = [];
          List<VariantOptionModel> variantOptionList = [];

          if (itemModel.variantOptionJson != null) {
            listVariantOptions = jsonDecode(
              itemModel.variantOptionJson ?? '[]',
            );
            variantOptionList =
                listVariantOptions.map((item) {
                  return VariantOptionModel.fromJson(item);
                }).toList();
          }

          Map<String, dynamic> dataToTransfer = {};

          if (mounted) {
            if (variantOptionList.isNotEmpty && itemModel.price != null) {
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
                      VariantOptionModel? tempVOModel =
                          ref
                              .read(itemProvider.notifier)
                              .getTempVariantOptionModel;
                      bool isCustomVariant = tempVOModel?.price == null;

                      // Remove unnecessary delay
                      // await Future.delayed(Duration.zero);
                      _itemNotifier.resetTempQtyAndPrice();

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
                      NavigationUtils.pop(context);
                      await Future.delayed(const Duration(milliseconds: 100));

                      /// [SHOW SECOND DISPLAY] - Conditional based on parameter
                      if (updateSecondDisplayImmediately) {
                        await showOptimizedSecondDisplay(
                          dataToTransfer,
                          itemModel,
                        );
                      }

                      // Store data for potential debounced update
                      resultData = dataToTransfer;
                    },
                    saleItemModel: null,
                    itemModel: itemModel,
                    selectedModifierOptionIds: const [],
                  );
                },
              );
            } else if (itemModel.price == null) {
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
                      VariantOptionModel? tempVOModel =
                          ref
                              .read(itemProvider.notifier)
                              .getTempVariantOptionModel;
                      bool isCustomVariant = tempVOModel?.price == null;

                      // Remove unnecessary delay
                      // await Future.delayed(Duration.zero);
                      _itemNotifier.resetTempQtyAndPrice();

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
                      NavigationUtils.pop(context);
                      await Future.delayed(const Duration(milliseconds: 100));

                      /// [SHOW SECOND DISPLAY] - Conditional based on parameter
                      if (updateSecondDisplayImmediately) {
                        await showOptimizedSecondDisplay(
                          dataToTransfer,
                          itemModel,
                        );
                      }

                      // Store data for potential debounced update
                      resultData = dataToTransfer;
                    },
                    saleItemModel: null,
                    itemModel: itemModel,
                    selectedModifierOptionIds: const [],
                  );
                },
              );
            } else {
              // No variant, add directly to list
              if (!isEditMode) {
                if (itemModel.soldBy == ItemSoldByEnum.item) {
                  // Remove unnecessary delay
                  // await Future.delayed(Duration(milliseconds: 50));
                  String uuid = IdUtils.generateUUID();

                  // Use Riverpod to add the item and get the data in one step
                  dataToTransfer = await saleItemsRiverpod.createAndUpdateSaleItems(
                    itemModel,
                    saleItemPrice: itemModel.price ?? 0.00,
                    pricePerItem: itemModel.cost ?? 0.00,
                    newSaleItemUuid: uuid,
                    qty: 1,
                    comments: '',
                    listModifierOptionIds: [],
                    isCustomVariant: false,
                    existingSaleItem: null,
                  );

                  /// [SHOW SECOND DISPLAY] - Conditional based on parameter
                  if (updateSecondDisplayImmediately) {
                    await showOptimizedSecondDisplay(dataToTransfer, itemModel);
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
                          VariantOptionModel? tempVOModel =
                              ref
                                  .read(itemProvider.notifier)
                                  .getTempVariantOptionModel;
                          bool isCustomVariant = tempVOModel?.price == null;

                          // Remove unnecessary delay
                          // await Future.delayed(Duration.zero);
                          _itemNotifier.resetTempQtyAndPrice();

                          // Use Riverpod to create and update sale items
                          dataToTransfer = await saleItemsRiverpod
                              .createAndUpdateSaleItems(
                                itemModel,
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
                          NavigationUtils.pop(context);
                          await Future.delayed(
                            const Duration(milliseconds: 100),
                          );

                          /// [SHOW SECOND DISPLAY] - Conditional based on parameter
                          if (updateSecondDisplayImmediately) {
                            await showOptimizedSecondDisplay(
                              dataToTransfer,
                              itemModel,
                            );
                          }

                          // Store data for potential debounced update
                          resultData = dataToTransfer;
                        },
                        saleItemModel: null,
                        itemModel: itemModel,
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
              args: [itemModel?.name ?? ''],
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

  /// Handle when no item is found or multiple items found - trigger search
  void _handleItemNotFoundOrMultiple(String barcode) {
    prints('🔍 No single item found, triggering search for: $barcode');

    // Get the required notifiers
    final pageItemNotifier = ref.read(pageItemProvider.notifier);
    final itemNotifier = ref.read(itemProvider.notifier);

    // Switch to search page
    pageItemNotifier.setCurrentPageId(PageEnum.pageSearchItem);

    // Set the search term to the barcode
    itemNotifier.setSearchItemName(barcode);
  }

  /// Helper method to optimize data transfer to second display
  Future<void> showOptimizedSecondDisplay(
    Map<String, dynamic> dataToTransfer,
    ItemModel itemModel,
  ) async {
    if (!mounted) return;

    // Use cached slideshow model from home_screen.dart to avoid DB calls
    SlideshowModel? currSdModel = Home.getCachedSlideshowModel();

    // If cache is not available, fallback to DB call (should be rare)
    if (currSdModel == null) {
      prints('⚠️ Slideshow cache not available, falling back to DB call');
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
      DataEnum.currentItem: itemModel.toJson(),
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

    // Use the optimized update method for the second display
    await updateSecondaryDisplay(data);
  }

  /// Optimized method to update the second display without full navigation
  Future<void> updateSecondaryDisplay(Map<String, dynamic> data) async {
    // Check if we need to navigate to a new screen or just update the current one
    final String currRouteName = ref.read(
      secondDisplayCurrentRouteNameProvider,
    );

    if (currRouteName != CustomerShowReceipt.routeName) {
      await ref
          .read(secondDisplayProvider.notifier)
          .navigateSecondScreen(
            CustomerShowReceipt.routeName,
            data: data,
            isShowLoading: true,
          );
    } else {
      try {
        await ref
            .read(secondDisplayProvider.notifier)
            .updateSecondaryDisplay(data);
      } catch (e) {
        prints('Error updating second display: $e');
        await ref
            .read(secondDisplayProvider.notifier)
            .navigateSecondScreen(
              CustomerShowReceipt.routeName,
              data: data,
              isShowLoading: true,
            );
      }
    }
  }

  // Removed getSlideShowModel(SlideshowFacade) in favor of slideshowProvider

  @override
  void dispose() {
    _barcodeScannerNotifier.disposeAllSubscriptions();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation from sales screen
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // Do nothing - prevent back button action from sales screen
        // Users should use the drawer or other navigation methods
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChooseMenu(),
          //order list
          OrderListSales(salesContext: widget.homeContext),
        ],
      ),
    );
  }
}
