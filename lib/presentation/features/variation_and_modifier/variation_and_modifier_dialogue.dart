import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/data/models/inventory/inventory_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/modifier/modifier_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';
import 'package:mts/form_bloc/edit_variant_modifier_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/my_text_form_field.dart';
import 'package:mts/presentation/common/widgets/rolling_text.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/common/widgets/text_with_badge.dart';
import 'package:mts/presentation/features/variation_and_modifier/components/add_minus_button.dart';
import 'package:mts/presentation/features/variation_and_modifier/components/modifier_section.dart';
import 'package:mts/presentation/features/variation_and_modifier/components/price_number_pad.dart';
import 'package:mts/presentation/features/variation_and_modifier/components/quantity_number_pad.dart';
import 'package:mts/presentation/features/variation_and_modifier/components/variant_option_item.dart';
import 'package:mts/providers/deleted_sale_item/deleted_sale_item_providers.dart';
import 'package:mts/providers/inventory/inventory_providers.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/item_modifier/item_modifier_providers.dart';
import 'package:mts/providers/modifier_option/modifier_option_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';

class VariantAndModifierDialogue extends ConsumerStatefulWidget {
  final SaleItemModel? saleItemModel;
  final List<ModifierOptionModel> listSelectedModifierOption;
  final List<String> selectedModifierOptionIds;
  final ItemModel itemModel;
  final bool isFromMenuList;
  final List<VariantOptionModel> listVariantOptions;

  final Function(
    ItemModel itemModel,
    VariantOptionModel? varOptModel,
    List<ModifierOptionModel> listModOpt,
    double qty,
    SaleItemModel? saleItem,
    double totalPrice,
    String comments,
    List<String> modifierOptionIds,
    List<String> modifierIds,
    double cost,
  )
  onSave;

  final Function(Map<String, dynamic> data)? onDelete;

  const VariantAndModifierDialogue({
    super.key,
    required this.saleItemModel,
    required this.onSave,
    required this.itemModel,
    required this.selectedModifierOptionIds,
    required this.listSelectedModifierOption,
    required this.isFromMenuList,
    required this.listVariantOptions,
    required this.onDelete,
  });

  @override
  ConsumerState<VariantAndModifierDialogue> createState() =>
      _VariantAndModifierDialogueState();
}

class _VariantAndModifierDialogueState
    extends ConsumerState<VariantAndModifierDialogue> {
  double currentQty = 1;
  double currentCost = 0.00;
  String? selectedVariantOptionId;
  String? selectedCustomVarOptId;
  final ScrollController _scrollController = ScrollController();
  ItemModel itemModelLocal = ItemModel();
  TextEditingController commentController = TextEditingController();
  FocusNode commentFocusNode = FocusNode();

  double tempPrice = 0.0;
  List<VariantOptionModel> listVariantOption = [];
  Map<String, InventoryModel?> inventoryModelMap = {};

  final SaleItemNotifier notifierSaleItem =
      ServiceLocator.get<SaleItemNotifier>();
  InventoryModel? _itemInventoryModel;
  bool isAtTheTop = false;
  bool _isAnimating = false;
  bool isModifierRequired = false;
  bool isModifierInitialSelected = false;
  Set<String> selectedModifierSections = {};

  //Set<String> uniqueSelectedSections = {};

  @override
  void dispose() {
    _scrollController.dispose();
    commentFocusNode.dispose();
    selectedModifierSections.clear();
    super.dispose();
  }

  Future<void> _loadInventoryModelsForVariants() async {
    if (listVariantOption.isNotEmpty) {
      for (var variantOption in listVariantOption) {
        if (variantOption.inventoryId != null &&
            variantOption.inventoryId!.isNotEmpty) {
          final inventoryModel = await ref
              .read(inventoryProvider.notifier)
              .getInventoryModelById(variantOption.inventoryId!);
          if (mounted) {
            inventoryModelMap[variantOption.inventoryId!] = inventoryModel;
          }
        }
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadItemInventory() async {
    if (listVariantOption.isEmpty) {
      if (widget.itemModel.inventoryId != null &&
          widget.itemModel.inventoryId!.isNotEmpty) {
        final inventoryModel = await ref
            .read(inventoryProvider.notifier)
            .getInventoryModelById(widget.itemModel.inventoryId!);
        if (mounted) {
          setState(() {
            _itemInventoryModel = inventoryModel;
          });
        }
      }
    }
  }

  // Future<void> getSelectedModifier() async {
  //   selectedModifierSections.clear(); // Clear before recalculating
  //   // List<ModifierModel> listModifier = await _modifierFacade
  //   //     .getListModifierModelByItemId(widget.itemModel.id!);

  //   // for (ModifierModel elementM in listModifier) {
  //   //   List<ModifierOptionModel> options = await _modifierOptionFacade
  //   //       .getListModifierOptionByModifierId(elementM.id!);
  //   // }
  //   setState(() {});
  // }

  // Method to scroll to the top
  void scrollToTop() async {
    if (_isAnimating) return; // Return if an animation is already in progress

    setState(() {
      _isAnimating = true; // Start animation
    });

    // Animate to the top of the scroll view
    await _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    // Check if the scroll is at the top after animation completes
    if (_scrollController.offset <=
        _scrollController.position.minScrollExtent) {
      // The scroll view is at the top
      setState(() {
        isAtTheTop = true;
      });

      // checking for required  modifier (not modifier option)
      if (widget.itemModel.requiredModifierNum != null) {
        setState(() {
          isModifierRequired = true;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isAnimating = false; // Animation completed
      });
    }
  }

  // scroll to bottom
  void scrollToBottom() async {
    if (_isAnimating) return; // Return if an animation is already in progress

    setState(() {
      _isAnimating = true; // Start animation
    });

    // Animate to the bottom of the scroll view
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    // Check if the scroll is at the bottom after animation completes
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent) {
      // The scroll view is at the bottom
      setState(() {
        isAtTheTop = false; // Set to false because now at the bottom
      });

      // Checking for required modifier
      if (widget.itemModel.requiredModifierNum != null) {
        setState(() {
          isModifierRequired = true;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isAnimating = false; // Animation completed
      });
    }
  }

  void setTempPriceInItemNotifier(double tempPrice) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(itemProvider.notifier)
          .setTempPrice(tempPrice.toStringAsFixed(2));
    });
  }

  double getInitCurrentQty() {
    if (widget.saleItemModel != null &&
        widget.saleItemModel!.quantity != null) {
      return widget.saleItemModel!.quantity!;
    } else {
      // means from menu item will be default
      if (widget.itemModel.soldBy == ItemSoldByEnum.item) {
        return 1;
      } else {
        // SOLD BY MEASUREMENT
        // return 0 because requirement from client
        return 0;
      }
    }
  }

  @override
  void initState() {
    listVariantOption = widget.listVariantOptions;

    currentQty = getInitCurrentQty();
    currentCost = widget.saleItemModel?.cost ?? widget.itemModel.cost ?? 0.0;
    //  currentCost = widget.saleItemModel?.cost ?? 0.0;
    if (itemModelLocal.price == null) {
      /// only for itemModel.price == null
      tempPrice = widget.saleItemModel?.price ?? 0.00;
      if (tempPrice != 0.00) {
        tempPrice = tempPrice / currentQty;
        setTempPriceInItemNotifier(tempPrice);
      }
    }
    selectedVariantOptionId = widget.saleItemModel?.variantOptionId;
    commentController.text = widget.saleItemModel?.comments ?? '';

    // Add focus listener to scroll to comment field when focused
    commentFocusNode.addListener(() {
      if (commentFocusNode.hasFocus) {
        // Add a small delay to ensure keyboard is fully visible
        Future.delayed(const Duration(milliseconds: 300), () {
          // Scroll to bottom to show the comment field
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadInventoryModelsForVariants();
      await _loadItemInventory();
      final saleItemsNotifier = ref.read(saleItemProvider.notifier);
      saleItemsNotifier.setSelectedModifierOptionList(
        widget.listSelectedModifierOption,
      );
    });

    // check item sold by
    if (widget.itemModel.price == null) {
      if (widget.itemModel.soldBy == ItemSoldByEnum.item) {
        if (widget.itemModel.variantOptionJson != null) {
          isShowPricePad = false;
        } else {
          showPricePad(isInstance: true);
        }
      } else {
        if (widget.itemModel.variantOptionJson != null) {
          prints('123');

          isShowPricePad = false;
          isShowQtyPadMeasurement = false;
        } else {
          prints('234');
          showPricePad(isInstance: true);
        }
      }
    } else {
      // price tak null
      if (widget.itemModel.soldBy == ItemSoldByEnum.measurement) {
        isShowQtyPadMeasurement = true;
        showQtyPad(isInstance: true);
        if (widget.saleItemModel != null) {
          setInitQty(
            widget.saleItemModel!.quantity?.toStringAsFixed(3) ?? '0.000',
          );
          prints('sale item not null ${widget.saleItemModel?.quantity}');
        } else {
          setInitQty('0.000');
          prints('sale item null set 1');
        }
      }
    }

    super.initState();
  }

  void setInitQty(String qty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemProvider.notifier).setTempQty(qty);
    });
  }

  // Future<void> getItemModelFromLocalDB() async {
  //   itemModelLocal =
  //       await _itemFacade.getItemModelById(widget.itemModel.id!) ??
  //       widget.itemModel;
  //   setState(() {});
  // }

  void onPressQty(String type) {
    if (type == 'PLUS') {
      if (currentQty < 99) {
        setState(() {
          currentQty++;
        });
      }
    } else if (type == 'MINUS') {
      setState(() {
        if (currentQty > 0) {
          if (currentQty < 1) {
            // means in decimal
            currentQty = 0;
          } else {
            currentQty--;
          }
        }
      });
    }
  }

  double getGrandTotalItem(
    double? price,
    VariantOptionModel? varOptModel,
    List<ModifierOptionModel> listModOptModel,
  ) {
    // Calculate the total price of all modifier options
    double totalModPrice = listModOptModel.fold(
      0,
      (total, element) => total + (element.price ?? 0),
    );

    // Calculate base price considering variant and modifier options
    double basePrice = (price ?? 0) + (varOptModel?.price ?? 0) + totalModPrice;

    // Return the total price multiplied by the quantity
    return basePrice * currentQty;
  }

  Map<String, dynamic> _fetchData(
    ItemNotifier itemNotifier,
    ItemModifierNotifier itemModifierNotifier,
  ) {
    // Fetch the ItemModel first
    final itemModel = widget.itemModel;
    // prints("itemModel.variantOptionJson");
    // prints(itemModel.variantOptionJson);

    List<VariantOptionModel> variantOptionList = itemNotifier
        .getListVariantOptionByItemId(itemModel.id!);
    // get list modifiers
    List<ModifierModel> listModifier = itemModifierNotifier
        .getListModifierModelByItemId(itemModel.id!);

    return {
      'itemModel': itemModel,
      'listVariant': variantOptionList,
      'listModifier': listModifier,
    };
  }

  String _getItemInventoryQty() {
    if (_itemInventoryModel?.currentQuantity != null) {
      if (widget.itemModel.soldBy == ItemSoldByEnum.item) {
        return _itemInventoryModel!.currentQuantity!.toStringAsFixed(0);
      } else {
        return _itemInventoryModel!.currentQuantity!.toStringAsFixed(3);
      }
    }
    return '';
  }

  /// Get background color based on quantity
  Color _getInventoryBgColor(String inventoryQty) {
    double? qty = double.tryParse(inventoryQty);
    if (qty != null) {
      return qty > 0 ? kBadgeBgGreen : kBadgeBgRed;
    }
    return Colors.transparent;
  }

  /// Get text color based on quantity
  Color _getInventoryTextColor(String inventoryQty) {
    double? qty = double.tryParse(inventoryQty);
    if (qty != null) {
      return qty > 0 ? kBadgeTextGreen : kBadgeTextRed;
    }
    return Colors.transparent;
  }

  /// [for animations]
  /// // Center horizontally (as a fraction of screen width)
  //final double _left = 0.23;
  double _left = 0.375;
  double _top = 0; // Start at 0% from the top, will be adjusted for keyboard
  bool isShowPricePad = false;
  bool isShowQtyPadMeasurement = false;
  bool isShowQtyPadItem = false;

  @override
  Widget build(BuildContext context) {
    final itemNotifier = ref.watch(itemProvider.notifier);

    itemModelLocal = itemNotifier.getItemById(widget.itemModel.id!);
    final itemModifierNotifier = ref.watch(itemModifierProvider.notifier);

    final usedSaleItemModel = widget.saleItemModel;
    double availableHeight = MediaQuery.of(context).size.height;
    double availableWidth = MediaQuery.of(context).size.width;

    // Detect keyboard visibility and adjust dialog position
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    if (keyboardHeight > 0 && commentFocusNode.hasFocus) {
      // Keyboard is visible and comment field is focused
      final adjustmentRatio = (keyboardHeight / availableHeight) * 0.8;
      _top = -adjustmentRatio;
    } else if (keyboardHeight == 0) {
      // Keyboard is hidden, reset position
      _top = 0;
    }

    // if (itemModelLocal.soldBy == ItemSoldByEnum.ITEM) {
    //   if (itemModelLocal.price == null) {
    //     // call price numpad
    //   } else {
    return mainBody(
      availableHeight,
      availableWidth,
      usedSaleItemModel,
      itemNotifier,
      itemModifierNotifier,
    );

    //   }
    // } else {
    //   // sold by measurement
    //   // call price numpad then call qtyNumpad
    // }
    // return PriceNumberPad(
    //     itemModel: itemModelLocal,
    //     onOkPress: (price) {
    //       tempPrice = price;
    //       setState(() {});
    //     });

    // return QuantityNumberPad(
    //   itemModel: itemModelLocal,
    //   onOkPress: (qty) {
    //     currentQty = qty;
    //     setState(() {});
    //   },
    // );
  }

  Widget mainBody(
    double availableHeight,
    double availableWidth,
    SaleItemModel? usedSaleItemModel,
    ItemNotifier ni,
    ItemModifierNotifier imn,
  ) {
    final saleItemsNotifier = ref.watch(saleItemProvider.notifier);
    final data = _fetchData(ni, imn);
    final itemModel = data['itemModel'] as ItemModel;
    final listVariantOption = data['listVariant'] as List<VariantOptionModel>;
    final listModifier = data['listModifier'] as List<ModifierModel>;
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
            // rn.setReceiptDialogueNavigator(DialogueNaviagtorEnum.RESET);

            // rn.dateFormatting(rn.getLastSelectedDateRange);

            ni.setSelectedPrice(ni.getPreviousPrice);
            ni.setSelectedQty(ni.getPreviousQty);
            saleItemsNotifier.resetModAndVar();
          },
          child: Container(color: Colors.transparent),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          left: _left * availableWidth - (availableWidth / 4),
          // Adjust to move dialog
          top: _top * availableHeight,
          curve: Curves.easeInOutCirc,
          child: Material(
            color: Colors.transparent,
            child: Dialog(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: SafeArea(
                child: BlocProvider(
                  create:
                      (context) =>
                          EditVariantModifierFormBloc(widget.saleItemModel),
                  child: Builder(
                    builder: (context) {
                      // Note: SaleItemModel doesn't have variantOptionModel property
                      // Variant option will be loaded from the listVariantOptions if needed
                      VariantOptionModel? varOptModel;

                      List<ModifierOptionModel> listSelectedModOptmodel =
                          widget.listSelectedModifierOption;

                      return FormBlocListener<
                        EditVariantModifierFormBloc,
                        String,
                        String
                      >(
                        onSubmitting: (context, state) {},
                        onSuccess: (context, state) {},
                        onFailure: (context, state) {},
                        onSubmissionFailed: (context, state) {},
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: availableHeight / 1.1,
                            maxWidth: availableWidth / 1.5,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Column(
                              children: [
                                const Space(15),
                                AppBar(
                                  elevation: 0,
                                  backgroundColor: white,
                                  title: Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                if (listVariantOption.isEmpty &&
                                                    _itemInventoryModel !=
                                                        null &&
                                                    _itemInventoryModel!.id !=
                                                        null &&
                                                    _itemInventoryModel!
                                                            .currentQuantity !=
                                                        null) ...[
                                                  TextWithBadge(
                                                    text:
                                                        _getItemInventoryQty(),
                                                    backgroundColor:
                                                        _getInventoryBgColor(
                                                          _getItemInventoryQty(),
                                                        ),
                                                    textColor:
                                                        _getInventoryTextColor(
                                                          _getItemInventoryQty(),
                                                        ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                                Expanded(
                                                  child: Text(
                                                    itemModel.name!,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        AppTheme.h1TextStyle(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            itemModel.requiredModifierNum !=
                                                    null
                                                ? Text(
                                                  'modifierRequired'.tr(
                                                    args: [
                                                      itemModel
                                                          .requiredModifierNum
                                                          .toString(),
                                                    ],
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style:
                                                      AppTheme.italicTextStyle(),
                                                )
                                                : const SizedBox.shrink(),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 25),
                                      !widget.isFromMenuList
                                          ? Expanded(
                                            child: ButtonTertiary(
                                              onPressed: () async {
                                                await handleOnPressDelete(
                                                  context,
                                                  saleItemsNotifier,
                                                );
                                              },
                                              text: 'delete'.tr(),
                                              icon: FontAwesomeIcons.trash,
                                              textColor: kTextRed,
                                            ),
                                          )
                                          : const SizedBox(),
                                      SizedBox(
                                        width: !widget.isFromMenuList ? 10 : 0,
                                      ),
                                      Expanded(
                                        child: ButtonTertiary(
                                          onPressed: () async {
                                            await onPressSave(
                                              itemModel,
                                              varOptModel,
                                              listSelectedModOptmodel,
                                              usedSaleItemModel,
                                              listVariantOption,
                                              commentController,
                                              saleItemsNotifier,
                                            );
                                          },
                                          text: 'save'.tr(),
                                          icon: FontAwesomeIcons.download,
                                        ),
                                      ),
                                    ],
                                  ),
                                  leading: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: canvasColor,
                                    ),
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      ni.setSelectedPrice(ni.getPreviousPrice);
                                      ni.setSelectedQty(ni.getPreviousQty);
                                      ni.setTempPrice('0.00');
                                      ni.setTempQty('0.000');

                                      saleItemsNotifier.resetModAndVar();
                                    },
                                  ),
                                ),
                                const Space(10),
                                const Divider(),
                                const Space(10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'rm'.tr(),
                                      style: AppTheme.normalTextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    2.5.widthBox,
                                    RollingNumber(
                                      value:
                                          getGrandTotalItem(
                                            isCustomPrice()
                                                ? tempPrice
                                                : listVariantOption.isEmpty
                                                ? itemModel.price
                                                : 0,
                                            varOptModel,
                                            listSelectedModOptmodel,
                                          ).abs(),

                                      style: AppTheme.normalTextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ],
                                ),

                                const Space(25),
                                isCustomPrice()
                                    ? InkWell(
                                      onTap: () async {
                                        if (isCustomPrice()) {
                                          await showPricePad();
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              width: isCustomPrice() ? 1 : 0,
                                              color:
                                                  isCustomPrice()
                                                      ? kBlackColor
                                                      : white,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'RM'.tr(
                                            args: [
                                              currentCost.toStringAsFixed(2),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                    : const SizedBox.shrink(),
                                Space(isCustomPrice() ? 25 : 0),
                                Row(
                                  children: [
                                    const Expanded(child: SizedBox()),
                                    AddMinusButton(
                                      press: () {
                                        onPressQty('MINUS');
                                      },
                                      icon: FontAwesomeIcons.minus,
                                    ),
                                    const SizedBox(width: 25),
                                    InkWell(
                                      onTap: () async {
                                        // if (itemModelLocal.price == null) {
                                        //   await showQtyPad();
                                        //   return;
                                        // }
                                        // if (itemModelLocal.soldBy ==
                                        //     ItemSoldByEnum.MEASUREMENT) {
                                        //   await showQtyPad();
                                        //   return;
                                        // }

                                        /// new: no condition for qty pad
                                        await onQtyPress(context);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 50,
                                        ),
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              /// old tips:
                                              /// Set width to 1 if price is null or item is sold by measurement,
                                              /// otherwise set to 0
                                              width: 1,

                                              color: kBlackColor,
                                            ),
                                          ),
                                        ),
                                        child: RollingNumber(
                                          value: currentQty.abs(),
                                          //prefix: 'rm'.tr(),
                                          decimalPlaces:
                                              itemModelLocal.soldBy ==
                                                      ItemSoldByEnum.item
                                                  ? 0
                                                  : 3,
                                          style: AppTheme.normalTextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 30,
                                          ),
                                        ),
                                        // Text(
                                        //   itemModelLocal.soldBy ==
                                        //           ItemSoldByEnum.ITEM
                                        //       ? currentQty.toStringAsFixed(0)
                                        //       : currentQty.toStringAsFixed(3),
                                        //   style: AppTheme.normalTextStyle(
                                        //     fontWeight: FontWeight.bold,
                                        //     fontSize: 30,
                                        //   ),
                                        // ),
                                      ),
                                    ),
                                    const SizedBox(width: 25),
                                    AddMinusButton(
                                      press: () {
                                        onPressQty('PLUS');
                                      },
                                      icon: FontAwesomeIcons.plus,
                                    ),
                                    const Expanded(child: SizedBox()),
                                  ],
                                ),
                                const Space(10),
                                Expanded(
                                  child: SingleChildScrollView(
                                    controller: _scrollController,
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ..._getListVariant(
                                          listVariantOption,
                                          saleItemsNotifier,
                                        ),
                                        ..._getListModifier(
                                          listModifier,
                                          widget.selectedModifierOptionIds,
                                          widget.listSelectedModifierOption,
                                        ),
                                        textSelectedModifier(),

                                        const Space(20),

                                        /// [comment]
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 15,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('comment'.tr()),
                                              const Space(10),
                                              // comments
                                              MyTextFormField(
                                                controller: commentController,
                                                focusNode: commentFocusNode,
                                                labelText: ''.tr(),
                                                hintText: '',
                                                scrollPadding:
                                                    const EdgeInsets.all(100.0),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Space(20),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isShowPricePad)
          Positioned(
            left:
                (_left * availableWidth - (availableWidth / 4)) +
                (availableWidth / 1.5) +
                15, // Position next to the first dialog with spacing
            top: _top * availableHeight,
            child: Material(
              color: Colors.transparent,
              child: PriceNumberPad(
                itemModel: itemModelLocal,
                onOkPress: (cost) {
                  VariantOptionModel? tempVOModel =
                      ref.read(itemProvider.notifier).getTempVariantOptionModel;

                  bool isCustomVariant =
                      tempVOModel != null ? tempVOModel.price == null : false;
                  if (!isCustomVariant) {
                    tempPrice = cost;
                    prints('tempPrice: $tempPrice');
                    currentCost = cost;
                  } else {
                    if (itemModelLocal.variantOptionJson != null) {
                      VariantOptionModel? customVariant =
                          context
                              .read<ItemNotifier>()
                              .getTempVariantOptionModel;
                      if (customVariant != null) {
                        VariantOptionModel customVarOpt = customVariant
                            .copyWith(price: cost);
                        selectedCustomVarOptId = null;
                        overrideVariantOptionJson(customVarOpt);
                        handlePressVOItem(
                          customVarOpt,
                          saleItemsNotifier,
                          false,
                        );
                        setState(() {});
                        // set is custom to false
                        // set custom variant to null when on save callback
                      } else {
                        if (kDebugMode) {
                          prints('CUSTOM VARIANT IS NULL');
                        }
                      }
                    } else {
                      /// TAKDE VARIANT
                      currentCost = cost;
                      tempPrice = cost * currentQty;
                    }
                  }

                  setState(() {});
                },
                onClose: () async {
                  isShowPricePad = false;
                  setState(() {});
                  await Future.delayed(const Duration(milliseconds: 100));
                  _left = 0.375;

                  setState(() {});
                },
              ),
            ),
          ),
        if (isShowQtyPadMeasurement)
          Positioned(
            left:
                (_left * availableWidth - (availableWidth / 4)) +
                (availableWidth / 1.5) +
                15, // Position next to the first dialog with spacing
            top: _top * availableHeight,
            child: Material(
              color: Colors.transparent,
              child: QuantityNumberPad(
                itemModel: itemModelLocal,
                onOkPress: (qty) {
                  currentQty = qty;
                  setState(() {});
                },
                onClose: () async {
                  isShowQtyPadMeasurement = false;
                  setState(() {});
                  await Future.delayed(const Duration(milliseconds: 100));
                  _left = 0.375;

                  setState(() {});
                },
              ),
            ),
          ),
      ],
    );
  }

  Future<void> onQtyPress(BuildContext context) async {
    if (itemModelLocal.soldBy == ItemSoldByEnum.measurement) {
      ref.read(itemProvider.notifier).setTempQty(currentQty.toStringAsFixed(3));
    } else if (itemModelLocal.soldBy == ItemSoldByEnum.item) {
      ref.read(itemProvider.notifier).setTempQty(currentQty.toStringAsFixed(0));
    }
    await showQtyPad();
  }

  bool isCustomPrice() {
    if (itemModelLocal.price == null) {
      if (widget.itemModel.variantOptionJson == null) {
        return true;
        // kalau ade variant, dah jadi bukan custom price sebab harga based on variant
      }
      if (kDebugMode) {
        //     prints('VARIANT OPTION JSON ${widget.itemModel.variantOptionJson}');
      }
      return false;
    }
    return false;
  }

  Future<void> showPricePad({bool isInstance = false}) async {
    _left = 0.23;
    setState(() {});
    await Future.delayed(Duration(milliseconds: isInstance ? 50 : 500));
    if (isShowQtyPadMeasurement) {
      isShowQtyPadMeasurement = false;
    }
    isShowPricePad = true;

    setState(() {});
  }

  Future<void> showQtyPad({bool isInstance = false}) async {
    _left = 0.23;
    setState(() {});
    await Future.delayed(Duration(milliseconds: isInstance ? 50 : 500));
    if (isShowPricePad) {
      isShowPricePad = false;
    }
    isShowQtyPadMeasurement = true;
    setState(() {});
  }

  Future<void> handleOnPressDelete(
    BuildContext context,
    SaleItemNotifier saleItemsNotifier,
  ) async {
    SaleItemModel? si = widget.saleItemModel;
    // refresh sale item state
    final saleItemsState0 = ref.read(saleItemProvider);
    final currSaleModel = saleItemsState0.currSaleModel;
    final currSaleModelId = currSaleModel?.id;

    // avoid lag
    await Future.delayed(const Duration(milliseconds: 500));

    if (si != null &&
        si.id != null &&
        si.saleId != null &&
        si.saleId == currSaleModelId) {
      SaleItemModel updatedSI = si.copyWith(isVoided: true);

      // insert into notifier dulu
      if (currSaleModel != null) {
        notifierSaleItem.addOrUpdateListClearedSaleItem([
          updatedSI,
        ], currSaleModel);
      }
      // // update sale item
      // int success = await _saleItemFacade.update(updatedSI);
    } else {
      prints('DOESNT HAVE SALE ID');
    }

    /// close the dialogue first
    NavigationUtils.pop(context);

    /// delete the sale item modifier and sale item modifier options - now async
    saleItemsNotifier.deleteSaleModifierModelAndSaleModifierOptionModel(
      widget.saleItemModel?.id ?? '',
      widget.saleItemModel?.updatedAt ?? DateTime.now(),
    );

    /// delete the sale item model
    saleItemsNotifier.removeSaleItemFromNotifier(
      widget.saleItemModel?.id ?? '',
      widget.saleItemModel?.updatedAt ?? DateTime.now(),
    );

    /// recalculate the all total
    saleItemsNotifier.reCalculateAllTotal(
      widget.saleItemModel?.id ?? '',
      widget.saleItemModel?.updatedAt ?? DateTime.now(),
    );
    if (currSaleModel != null) {
      await ref
          .read(deletedSaleItemProvider.notifier)
          .createAndInsertDeletedSaleItemModel(saleModel: currSaleModel);
    }

    // refresh sale items state - use RiverpodService to read after dialog is closed
    // final saleItemsState = _riverpodService.read(saleItemsProvider);
    // final listSaleItems = saleItemsState.saleItems;

    // /// [SHOW SECOND DISPLAY]

    // if (listSaleItems.isNotEmpty) {
    //   UserModel userModel = GetIt.instance<UserModel>();
    //   SlideshowModel? currSdModel = Home.getCachedSlideshowModel();

    //   data.addEntries([
    //     MapEntry(DataEnum.userModel, userModel.toJson()),
    //     MapEntry(DataEnum.slideshow, currSdModel?.toJson() ?? {}),
    //     const MapEntry(DataEnum.showThankYou, false),
    //     const MapEntry(DataEnum.isCharged, false),
    //   ]);

    //   // context = null because the dialogue already closed
    //   await _showSecondaryDisplayFacade.navigateSecondScreen(
    //     CustomerShowReceipt.routeName,
    //     displayManager,
    //     data: data,
    //     isShowLoading: false,
    //   );
    // } else {
    //   // Don't await this call to prevent blocking the UI thread
    //   _showSecondaryDisplayFacade.showMainCustomerDisplay();
    // }
    Map<String, dynamic> data = saleItemsNotifier.getMapDataToTransfer();
    if (widget.onDelete != null) {
      widget.onDelete!(data);
    }
  }

  Future<void> onPressSave(
    ItemModel itemModel,
    VariantOptionModel? varOptModel,
    List<ModifierOptionModel> listModOpt,
    SaleItemModel? existingSaleItemModel,
    List<VariantOptionModel> listVariantOption,
    TextEditingController commentController,
    SaleItemNotifier saleItemsNotifier,
  ) async {
    final saleItemsState = ref.read(saleItemProvider);
    // if (kDebugMode) {
    //   prints('on press save');
    //   prints(commentController.text);
    // }
    // prints(selectedVariantOptionId);
    // prints(jsonEncode(varOptModel));
    // prints(jsonEncode(listModOpt));

    // kvn3r

    List<String> listModifierIds = await ref
        .read(modifierOptionProvider.notifier)
        .getListModifierIdsByModifierOptionIds(
          listModOpt.where((e) => e.id != null).map((e) => e.id!).toList(),
        );
    // if (kDebugMode) {
    //   prints(listModOpt.where((e) => e.id != null).map((e) => e.id!).toList());
    // }

    // checking for required modifier
    if (itemModel.requiredModifierNum != null &&
        selectedModifierSections.length < itemModel.requiredModifierNum!) {
      scrollToBottom();
      return;
    }

    if (selectedVariantOptionId != null && listVariantOption.isNotEmpty) {
      // avoid lag animation
      NavigationUtils.pop(context);
      await Future.delayed(const Duration(milliseconds: 170));
      // if (kDebugMode) {
      prints(saleItemsState.saleModifiers.length);

      prints('statement 1');
      //   prints('VARIANT JSON ${varOptModel.toJson()}');
      // }
      // for item that have  variant
      widget.onSave(
        itemModel,
        varOptModel?.id == null ? null : varOptModel,
        listModOpt,
        currentQty,
        existingSaleItemModel,
        getGrandTotalItem(
          isCustomPrice()
              ? tempPrice
              : listVariantOption.isEmpty
              ? itemModel.price
              : 0,
          varOptModel,
          listModOpt,
        ),
        commentController.text,
        listModOpt.where((e) => e.id != null).map((e) => e.id!).toList(),
        listModifierIds,
        currentCost,
      );
      saleItemsNotifier.resetModAndVar();
    } else if (selectedVariantOptionId == null && listVariantOption.isEmpty) {
      // avoid lag animation
      NavigationUtils.pop(context);
      await Future.delayed(const Duration(milliseconds: 170));
      if (kDebugMode) {
        prints('statement 2');
      }
      // prints(
      //   getGrandTotalItem(
      //     listVariantOption.isEmpty ? itemModel.price : 0,
      //     varOptModel,
      //     listModOpt,
      //   ),
      // );
      // prints("${listVariantOption.isEmpty ? itemModel.price : 0}");
      // prints(jsonEncode(listModOpt));

      widget.onSave(
        itemModel,
        varOptModel?.id == null ? null : varOptModel,
        listModOpt,
        currentQty,
        existingSaleItemModel,
        getGrandTotalItem(
          isCustomPrice()
              ? tempPrice
              : listVariantOption.isEmpty
              ? itemModel.price
              : 0,
          varOptModel,
          listModOpt,
        ),
        commentController.text,
        listModOpt.where((e) => e.id != null).map((e) => e.id!).toList(),
        listModifierIds,
        currentCost,
      );
      saleItemsNotifier.resetModAndVar();
    } else {
      scrollToTop();
    }

    prints('statement 3');
  }

  Widget textSelectedModifier() {
    bool shouldShowWarning =
        isModifierRequired && itemModelLocal.requiredModifierNum != null;

    if (!shouldShowWarning) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Text(
        'selectedModifiers'.tr(
          args: [selectedModifierSections.length.toString()],
        ),
        style: AppTheme.normalTextStyle(
          color: kTextRed,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<Widget> _getListVariant(
    List<VariantOptionModel> listVariantOption,
    SaleItemNotifier saleItemsNotifier,
  ) {
    if (listVariantOption.isNotEmpty) {
      List<Widget> listVarOpt = [];

      for (var elementV in listVariantOption) {
        listVarOpt.add(
          VariantOptionItem(
            isAtTheTop: isAtTheTop,
            variantOptionModel: elementV,
            itemModel: widget.itemModel,
            inventoryModel:
                inventoryModelMap[elementV.inventoryId] ?? InventoryModel(),
            onPressed: () async {
              // avoid lag
              await Future.delayed(const Duration(milliseconds: 100));
              if (elementV.price != null) {
                //   if (elementV.isCustom == false) {
                if (elementV.price != null) {
                  handlePressVOItem(elementV, saleItemsNotifier, true);
                  ref
                      .read(itemProvider.notifier)
                      .setTempVariantOptionModel(elementV);
                  setState(() {});
                  // context.read<ItemNotifier>().setIsCustomVariant(false);
                } else {
                  // handle in callback pricePad
                  // context.read<ItemNotifier>().setIsCustomVariant(true);
                  // if (kDebugMode) {
                  //   prints(elementV.toJson());
                  // }
                  selectedCustomVarOptId = elementV.id;
                  setState(() {});
                  // set temp price to show price in price pad
                  ref
                      .read(itemProvider.notifier)
                      .setTempPrice(
                        elementV.price?.toStringAsFixed(2) ?? '0.00',
                      );
                  // refresh price pad
                  if (isShowPricePad) {
                    isShowPricePad = false;
                    setState(() {});
                  }
                  context.read<ItemNotifier>().setTempVariantOptionModel(
                    elementV,
                  );
                  await showPricePad(isInstance: true);
                }
              } else {
                // handle in callback pricePad
                // context.read<ItemNotifier>().setIsCustomVariant(true);
                // if (kDebugMode) {
                //   prints(elementV.toJson());
                // }
                // handle select temp variant
                selectedCustomVarOptId = elementV.id;
                setState(() {});
                // set temp price to show price in price pad
                ref
                    .read(itemProvider.notifier)
                    .setTempPrice(elementV.price?.toStringAsFixed(2) ?? '0.00');
                // refresh price pad
                if (isShowPricePad) {
                  isShowPricePad = false;
                  setState(() {});
                }
                ref
                    .read(itemProvider.notifier)
                    .setTempVariantOptionModel(elementV);
                await showPricePad(isInstance: true);
              }
            },
            isSelected: selectedVariantOptionId == elementV.id,
            isSelectedCustom: selectedCustomVarOptId == elementV.id,
          ),
        );
      }
      const int crossAxisCount = 2; // Number of items per row
      const double crossAxisSpacing = 10.0; // Horizontal spacing
      const double mainAxisSpacing = 10.0; // Vertical spacing
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'variants'.tr(),
                style: AppTheme.normalTextStyle(
                  color: kBlackColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              isAtTheTop
                  ? Text(
                    'pleaseChooseAtLeastOneVariant'.tr(),
                    style: AppTheme.normalTextStyle(
                      color: kTextRed,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : Container(),
            ],
          ),
        ),
        const Space(10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount, // Number of items per row
              crossAxisSpacing: crossAxisSpacing, // Horizontal spacing
              mainAxisSpacing: mainAxisSpacing, // Vertical spacing
              childAspectRatio: 7.5,
            ),
            itemCount: listVarOpt.isNotEmpty ? listVarOpt.length : 0,
            itemBuilder: (context, index) {
              if (listVarOpt.isNotEmpty) {
                return listVarOpt[index];
              } else {
                return Container(
                  decoration: BoxDecoration(
                    color: kPrimaryLightColor,
                    borderRadius: BorderRadius.circular(7.5),
                    border: Border.all(width: 0.5),
                  ),
                );
              }
            },
          ),
        ),
      ];
    } else {
      return [];
    }
  }

  void handleModifierSectionSelected(bool isSelected, String? modifierId) {
    setState(() {
      if (modifierId != null) {
        if (isSelected) {
          selectedModifierSections.add(modifierId);
        } else {
          if (selectedModifierSections.contains(modifierId)) {
            selectedModifierSections.remove(modifierId);
          }
        }
      }
    });
  }

  List<Widget> _getListModifier(
    List<ModifierModel> listModfier,
    List<String> listSelectedModIds,
    List<ModifierOptionModel> selectedModifierOptions,
  ) {
    if (listModfier.isNotEmpty) {
      List<Widget> listMod = [];

      for (var (_, elementM) in listModfier.indexed) {
        //  prints('indexModifier $indexM');
        listMod.add(
          ModifierSection(
            modifierModel: elementM,
            selectedModifierOptionIds: listSelectedModIds,
            selectedModifierOptions: selectedModifierOptions,
            listModifiers: listModfier,
            isModifierRequired: isModifierRequired,
            totalRequiredModifier: widget.itemModel.requiredModifierNum,
            isFromOrderListSales: !widget.isFromMenuList,
            onSectionSelected: (isSelected, modifierId) async {
              handleModifierSectionSelected(isSelected, modifierId);
            },
          ),
        );
      }
      return listModfier.isEmpty ? [] : listMod;
    } else {
      return [];
    }
  }

  void handlePressVOItem(
    VariantOptionModel variantOptionModel,

    SaleItemNotifier saleItemsNotifier,
    bool canDiselectVariant,
  ) {
    isAtTheTop = false;

    if (variantOptionModel.price == null) {
      if (selectedVariantOptionId != null) {
        // set the variant option model
        saleItemsNotifier.setVariantOptionModel(variantOptionModel);
      }
      // Update the selected variant option and add the new price
      selectedVariantOptionId = variantOptionModel.id;

      saleItemsNotifier.setVariantOptionModel(variantOptionModel);
      return;
    }

    if (selectedVariantOptionId != variantOptionModel.id) {
      if (selectedVariantOptionId != null) {
        // set the variant option model
        saleItemsNotifier.setVariantOptionModel(variantOptionModel);
      }
      // Update the selected variant option and add the new price
      selectedVariantOptionId = variantOptionModel.id;

      saleItemsNotifier.setVariantOptionModel(variantOptionModel);
    } else {
      // If the same item is selected again, it should be deselected
      if (canDiselectVariant) {
        selectedVariantOptionId = null;
        saleItemsNotifier.setVariantOptionModel(VariantOptionModel());
      } else {
        // prints(variantOptionModel.price);

        // prints("variantOptionModel.price != null");
        if (selectedVariantOptionId != null) {
          // set the variant option model
          saleItemsNotifier.setVariantOptionModel(variantOptionModel);
        }
        // Update the selected variant option and add the new price
        selectedVariantOptionId = variantOptionModel.id;

        saleItemsNotifier.setVariantOptionModel(variantOptionModel);
      }
    }
  }

  void overrideVariantOptionJson(VariantOptionModel customVarOpt) {
    /// decode variant option json from itemModelLocal -> jadikan list variant option model
    List<dynamic> variantOptionJson = jsonDecode(
      itemModelLocal.variantOptionJson ?? '[]',
    );
    List<VariantOptionModel> listVOM = List.generate(
      variantOptionJson.length,
      (index) => VariantOptionModel.fromJson(variantOptionJson[index]),
    );

    /// replace variant option model with custom variant option model
    int indexVOM = listVOM.indexWhere(
      (element) => element.id == customVarOpt.id,
    );

    if (indexVOM != -1) {
      listVOM[indexVOM] = customVarOpt;
    } else {
      if (kDebugMode) {
        prints('indexVOM == -1');
      }
    }
    listVariantOption = listVOM;

    /// encode list variant option model to json
    String variantOptionJsonEncoded = jsonEncode(listVOM);

    /// update variant option json in itemModelLocal
    itemModelLocal = itemModelLocal.copyWith(
      variantOptionJson: variantOptionJsonEncoded,
    );
  }
}
