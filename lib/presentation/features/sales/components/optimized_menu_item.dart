import 'dart:async';
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
import 'package:mts/data/models/variant_option/variant_option_model.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/layouts/hexagon_clipper.dart';
import 'package:mts/presentation/common/layouts/invalid_image_container.dart';
import 'package:mts/presentation/features/variation_and_modifier/variation_and_modifier_dialogue.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/slideshow/slideshow_providers.dart';

/// This is an optimized version of the MenuItem class that improves performance
/// when sending data to the second display.
class OptimizedMenuItem extends ConsumerStatefulWidget {
  // Static variable to track if an operation is in progress
  static bool _isProcessing = false;
  // Static timer for throttling
  static Timer? _throttleTimer;

  final int index;
  final ItemModel? itemModel;
  final ItemRepresentationModel itemRepresentationModel;
  final DownloadedFileModel downloadedFileModel;

  const OptimizedMenuItem({
    super.key,
    required this.itemRepresentationModel,
    required this.downloadedFileModel,
    required this.itemModel,
    required this.index,
  });

  @override
  ConsumerState<OptimizedMenuItem> createState() => _OptimizedMenuItemState();
}

class _OptimizedMenuItemState extends ConsumerState<OptimizedMenuItem> {
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
      onPressed: () async {
        await onPress(context, isEditMode, saleItemsRiverpod);
      },
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
      onPressed: () async {
        await onPress(context, isEditMode, saleItemsRiverpod);
      },
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
      onPressed: () async {
        await onPress(context, isEditMode, saleItemsRiverpod);
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
                          return InvalidImageContainer(
                            text: widget.itemModel?.name ?? '',
                          );
                        },
                      )
                      : InvalidImageContainer(
                        text: widget.itemModel?.name ?? '',
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
      onPressed: () async {
        await onPress(context, isEditMode, saleItemsRiverpod);
      },
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

  /// Optimized onPress method that improves performance when sending data to the second display
  Future<void> onPress(
    BuildContext context,
    bool isEditMode,
    SaleItemNotifier saleItemsRiverpod,
  ) async {
    // Throttle rapid taps - if an operation is already in progress, ignore this tap
    if (OptimizedMenuItem._isProcessing) {
      prints('Ignoring tap - operation in progress');
      return;
    }

    // Cancel any existing throttle timer
    OptimizedMenuItem._throttleTimer?.cancel();

    // Set processing flag to prevent further taps
    OptimizedMenuItem._isProcessing = true;

    // Remove unnecessary delay that was causing performance issues
    // await Future.delayed(Duration(milliseconds: 200));

    try {
      ItemModel? itemModel = widget.itemModel;
      if (isEditMode) {
        OptimizedMenuItem._isProcessing = false;
        return;
      }

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
          if (variantOptionList.isNotEmpty && widget.itemModel!.price != null) {
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
                    bool isCustomVariant =
                        tempVOModel != null ? tempVOModel.price == null : false;

                    // Remove unnecessary delay
                    // await Future.delayed(Duration.zero);
                    _itemNotifier.resetTempQtyAndPrice();

                    // Use Riverpod to create and update sale items
                    dataToTransfer = await saleItemsRiverpod.createAndUpdateSaleItems(
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

                    /// [SHOW SECOND DISPLAY]
                    await showOptimizedSecondDisplay(dataToTransfer);
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
                    VariantOptionModel? tempVOModel =
                        ref
                            .read(itemProvider.notifier)
                            .getTempVariantOptionModel;
                    bool isCustomVariant =
                        tempVOModel != null ? tempVOModel.price == null : false;

                    // Remove unnecessary delay
                    // await Future.delayed(Duration.zero);
                    _itemNotifier.resetTempQtyAndPrice();

                    // Use Riverpod to create and update sale items
                    dataToTransfer = await saleItemsRiverpod.createAndUpdateSaleItems(
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

                    /// [SHOW SECOND DISPLAY]
                    await showOptimizedSecondDisplay(dataToTransfer);
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

                /// [SHOW SECOND DISPLAY]
                await showOptimizedSecondDisplay(dataToTransfer);
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
                        bool isCustomVariant =
                            tempVOModel != null
                                ? tempVOModel.price == null
                                : false;

                        // Remove unnecessary delay
                        // await Future.delayed(Duration.zero);
                        _itemNotifier.resetTempQtyAndPrice();

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
                        NavigationUtils.pop(context);

                        /// [SHOW SECOND DISPLAY]
                        await showOptimizedSecondDisplay(dataToTransfer);
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
    } finally {
      // Reset the processing flag after a delay to allow animations to complete
      OptimizedMenuItem._throttleTimer = Timer(
        const Duration(milliseconds: 50),
        () {
          OptimizedMenuItem._isProcessing = false;
        },
      );
    }
  }

  /// Helper method to optimize data transfer to second display
  Future<void> showOptimizedSecondDisplay(
    Map<String, dynamic> dataToTransfer,
  ) async {
    if (!mounted) return;
    // Ensure current item is part of the payload; provider will add user/slideshow.
    dataToTransfer[DataEnum.currentItem] = widget.itemModel!.toJson();

    await ref
        .read(slideshowProvider.notifier)
        .showOptimizedSecondDisplay(dataToTransfer);
  }
}
