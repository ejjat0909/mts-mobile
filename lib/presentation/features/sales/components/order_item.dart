import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/core/enums/permission_enum.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/rolling_text.dart';
import 'package:mts/presentation/features/home/home_screen.dart';
import 'package:mts/providers/payment/payment_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/presentation/features/sales/components/menu_item.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/modifier_option/modifier_option_providers.dart';
import 'package:mts/providers/slideshow/slideshow_providers.dart';
import 'package:mts/providers/user/user_providers.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';
import 'package:mts/providers/permission/permission_providers.dart';

class OrderItem extends ConsumerStatefulWidget {
  final Map<String, dynamic> orderData;
  final Function() press;
  final Function(String)? onDeletedSaleItemID;

  static bool _isProcessing = false;
  static Timer? _throttleTimer;
  static final Queue<Function> _pendingOperations = Queue<Function>();
  static bool _isProcessingQueue = false;
  static bool _isCacheInitialized = false;
  const OrderItem({
    super.key,
    required this.press,
    this.onDeletedSaleItemID,
    required this.orderData,
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
  static void initializeCache(
    List<ItemModel> items,
    List<ModifierOptionModel> modifierOptions,
  ) {
    if (_isCacheInitialized) return;

    _isCacheInitialized = true;
  }

  @override
  ConsumerState<OrderItem> createState() => _OrderItemState();
}

class _OrderItemState extends ConsumerState<OrderItem> {
  // Note: Using centralized slideshow cache from home_screen.dart for consistency

  SaleItemModel saleItemModel = SaleItemModel();
  ItemModel itemModel = ItemModel();
  SaleItemModel usedSaleItemModel = SaleItemModel();
  String allModifierOptionName = '';
  String? variantOptionName;

  @override
  void initState() {
    super.initState();

    // Ensure slideshow cache is available for consistent data across all screens
    _ensureSlideshowCacheAvailable();
  }

  /// Ensure slideshow cache is available for consistent data across all screens
  void _ensureSlideshowCacheAvailable() {
    // Use Future.microtask to avoid blocking initState
    Future.microtask(() async {
      if (!Home.isSlideshowCacheInitialized()) {
        prints(
          '🔄 Initializing slideshow cache from order item for consistency',
        );
        await Home.ensureSlideshowCacheInitialized();
      } else {
        prints('✅ Slideshow cache already available for order item');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    //  prints('ORDER ITEM BUILD ${widget.orderData[DataEnum.itemModel].name}');
    // penyebab lag satu sistem bila banyak order item

    final permissionNotifier = ref.read(permissionProvider.notifier);
    final saleItemNotifier = ref.watch(saleItemProvider.notifier);

    saleItemModel = widget.orderData[DataEnum.saleItemModel];
    itemModel = widget.orderData[DataEnum.itemModel];
    usedSaleItemModel = widget.orderData[DataEnum.usedSaleItemModel];
    allModifierOptionName = widget.orderData[DataEnum.allModifierOptionNames];
    variantOptionName = widget.orderData[DataEnum.variantOptionNames];

    if (itemModel.id == null) {
      return SizedBox.shrink();
    }

    return Dismissible(
      key: UniqueKey(),
      onDismissed: (direction) async {
        // If an operation is in progress, add this operation to the queue instead of executing immediately
        if (OrderItem._isProcessing) {
          prints('Adding onDismissed to queue - operation in progress');
          OrderItem._addToQueue(
            () => _processOnDismissed(saleItemNotifier, permissionNotifier),
          );
          return;
        }

        // Cancel any existing throttle timer
        OrderItem._throttleTimer?.cancel();

        // Set processing flag to prevent further immediate operations
        OrderItem._isProcessing = true;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!MenuItem.isCacheInitialized()) {
            final listItemFromNotifier =
                ref.read(itemProvider.notifier).getListItems;
            final listMoFromNotifier =
                ref.read(modifierOptionProvider.notifier).getModifierOptionList;
            MenuItem.initializeCache(listItemFromNotifier, listMoFromNotifier);
          }
        });

        // Process the dismissal after ensuring no conflicts
        await _processOnDismissed(saleItemNotifier, permissionNotifier);
      },
      direction:
          ref.watch(paymentProvider).changeToPaymentScreen
              ? DismissDirection.none
              : DismissDirection.startToEnd,
      background: Container(
        color: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(FontAwesomeIcons.trash, color: white),
            const SizedBox(width: 15),
            Text('remove'.tr(), style: AppTheme.normalTextStyle(color: white)),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: const BoxDecoration(color: white),
            child: InkWell(
              onTap: widget.press,
              splashColor: kPrimaryLightColor,
              highlightColor: kPrimaryLightColor,
              child: _buildContainer(),
              // itemModel.price == null
              //     ? soldByCustomPrice(
              //       usedSaleItemModel,
              //       itemModel,
              //       variantOptionName,
              //       allModifierOptionName,
              //     )
              //     : (itemModel.soldBy == ItemSoldByEnum.ITEM
              //         ? soldByItem(
              //           usedSaleItemModel,
              //           itemModel,
              //           variantOptionName,
              //           allModifierOptionName,
              //         )
              //         : soldByMeasurement(
              //           usedSaleItemModel,
              //           itemModel,
              //           variantOptionName,
              //           allModifierOptionName,
              //         )),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContainer() {
    bool customVariantPrice = isVariantPriceNull(usedSaleItemModel);
    if (itemModel.soldBy == ItemSoldByEnum.item) {
      // check price in item model
      if (itemModel.price == null) {
        // check variant price in sale item model
        if (customVariantPrice) {
          return soldByCustomPrice(
            usedSaleItemModel,
            itemModel,
            variantOptionName,
            allModifierOptionName,
          );
        }
      }
      return soldByItem(
        usedSaleItemModel,
        itemModel,
        variantOptionName,
        allModifierOptionName,
      );
    } else if (itemModel.soldBy == ItemSoldByEnum.measurement) {
      // check price in item model
      if (itemModel.price == null) {
        // check variant price in sale item model
        if (customVariantPrice) {
          return soldByCustomPrice(
            usedSaleItemModel,
            itemModel,
            variantOptionName,
            allModifierOptionName,
          );
        }
      }
      return soldByMeasurement(
        usedSaleItemModel,
        itemModel,
        variantOptionName,
        allModifierOptionName,
      );
    } else {
      // fallback use custom price
      return soldByCustomPrice(
        usedSaleItemModel,
        itemModel,
        variantOptionName,
        allModifierOptionName,
      );
    }
  }

  bool isVariantPriceNull(SaleItemModel usedSaleItemModel) {
    try {
      if (usedSaleItemModel.variantOptionJson == null ||
          usedSaleItemModel.variantOptionJson!.isEmpty) {
        return true;
      }
      // Parse the JSON string
      Map<String, dynamic> variantJson = jsonDecode(
        usedSaleItemModel.variantOptionJson!,
      );

      // Check if price field exists and is null
      return variantJson['price'] == null;
    } catch (e) {
      // If JSON parsing fails or variantOptionJson is null, return true (treat as null price)
      prints('Error parsing variant JSON: $e');
      return true;
    }
  }

  Future<void> _processOnDismissed(
    SaleItemNotifier saleItemNotifier,
    PermissionNotifier permissionNotifier,
  ) async {
    try {
      // Ensure slideshow cache is initialized
      // await _initializeSlideshowCache();

      final saleItemsState0 = ref.read(saleItemProvider);
      final currentSaleModel = saleItemsState0.currSaleModel;
      bool hasPermissionManageOrder =
          permissionNotifier.hasManageAllOpenOrdersPermission();
      bool hasPermissionVoidOrder =
          permissionNotifier.hasVoidSavedItemsInOpenOrderPermission();

      if (currentSaleModel?.id != null) {
        if (saleItemModel.saleId == null) {
          prints('Item can dismissed because sale item dont have sale id yet');
          // this case occur when user open order, then choose new item, then user want to dismiss, so the sale item has no sale id yet
          await processDismissedInDetail(
            saleItemNotifier,
            isUpdateClearedSaleItem: false,
          );
        } else {
          if (!hasPermissionManageOrder) {
            DialogUtils.showNoPermissionDialogue(context);
            return;
          }
          if (!hasPermissionVoidOrder) {
            await DialogUtils.showPinDialog(
              context,
              permission: PermissionEnum.VOID_SAVED_ITEMS_IN_OPEN_ORDER,
              onSuccess: () {
                hasPermissionVoidOrder = true;
              },
              onError: (error) {
                ThemeSnackBar.showSnackBar(context, error);
                return;
              },
            );
          }
          if (hasPermissionManageOrder && hasPermissionVoidOrder) {
            prints('Item dismissed after open order means have sale id');

            /// remove the saleModifierModel and saleModifierOptionModel
            /// from the notifier - now async
            await processDismissedInDetail(
              saleItemNotifier,
              isUpdateClearedSaleItem: true,
            );
          }
        }
      } else {
        // order has not been save yet
        prints('Item dismissed before save the order means no sale id');

        await processDismissedInDetail(
          saleItemNotifier,
          isUpdateClearedSaleItem: false,
        );
      }

      // tak boleh buat kat sini, kene handle masa tekan save dekat order list sales
      // await dlsFacade.createAndInsertDeletedSaleItemModel(
      //   saleModel: currSaleModel,
      // );
    } finally {
      // Reset the processing flag after a short delay to allow operations to complete
      // Reduced from 50ms to 10ms to prevent interaction blocking
      OrderItem._throttleTimer = Timer(const Duration(milliseconds: 10), () {
        OrderItem._isProcessing = false;

        // Process the next item in the queue if there is one
        if (OrderItem._pendingOperations.isNotEmpty) {
          OrderItem._processQueue();
        }
      });
    }
  }

  Future<void> processDismissedInDetail(
    SaleItemNotifier saleItemNotifier, {
    bool isUpdateClearedSaleItem = false,
  }) async {
    /// remove the saleModifierModel and saleModifierOptionModel
    /// from the notifier - now async
    saleItemNotifier.deleteSaleModifierModelAndSaleModifierOptionModel(
      saleItemModel.id!,
      saleItemModel.updatedAt!,
    );

    /// remove the one saleItemModel from the notifier
    saleItemNotifier.removeSaleItemFromNotifier(
      saleItemModel.id!,
      saleItemModel.updatedAt!,
    );

    // recalculate the total
    saleItemNotifier.reCalculateAllTotal(
      saleItemModel.id!,
      saleItemModel.updatedAt!,
    );

    // refresh sale item state
    final saleItemsState = ref.read(saleItemProvider);
    final listSaleItems = saleItemsState.saleItems;
    final currSaleModel = saleItemsState.currSaleModel;
    final currSaleModelId = currSaleModel?.id;

    // update sale item to isVoided = true in a microtask to avoid blocking UI
    if (isUpdateClearedSaleItem) {
      await Future.microtask(() async {
        // find sale item in db
        SaleItemModel si = await saleItemNotifier.getSaleItemById(
          saleItemModel.id!,
        );

        if (si.id != null &&
            si.saleId != null &&
            si.saleId == currSaleModelId) {
          SaleItemModel updatedSI = si.copyWith(isVoided: true);
          // insert into notifier pastu handle masa tekan save dekat order list sales
          saleItemNotifier.addOrUpdateListClearedSaleItem([
            updatedSI,
          ], currSaleModel!);
        } else {
          prints('sale item is null means not in predefined order');
        }
      });
    }

    /// [OPTIMIZED SHOW SECOND DISPLAY]
    if (listSaleItems.isNotEmpty) {
      await _showOptimizedSecondDisplayAfterDismissal(saleItemNotifier);
    } else {
      // list items is empty so show welcome screen
      // Don't await this call to prevent blocking the UI thread
      ref.read(secondDisplayProvider.notifier).showMainCustomerDisplay();
    }
  }

  Future<void> _showOptimizedSecondDisplayAfterDismissal(
    SaleItemNotifier saleItemNotifier,
  ) async {
    try {
      final currentUser =
          ref.read(userProvider.notifier).currentUser ?? UserModel();
      // Create a lightweight data package with only essential information
      Map<String, dynamic> data = {
        // Add a unique update ID to track this update
        DataEnum.cartUpdateId: IdUtils.generateUUID(),
        // Add user model and slideshow data (using centralized cached slideshow)
        DataEnum.userModel: currentUser.toJson(),
        DataEnum.slideshow: Home.getCachedSlideshowModel()?.toJson() ?? {},
        DataEnum.showThankYou: false,
        DataEnum.isCharged: false,
      };

      // Get optimized data from the notifier
      final optimizedData = saleItemNotifier.getMapDataToTransfer();

      // Add only the essential data from the notifier, avoiding large data structures
      optimizedData.forEach((key, value) {
        // Skip large data structures that don't change frequently
        if (key != DataEnum.listItems && key != DataEnum.listMO) {
          data[key] = value;
        }
      });

      // Use cached common data if available
      if (MenuItem.getCachedCommonData().isNotEmpty) {
        prints('✅ Using cached common data for second display in ORDER ITEM');
        MenuItem.getCachedCommonData().forEach((key, value) {
          if (!data.containsKey(key)) {
            data[key] = value;
          }
        });
      } else {
        prints(
          '⚠️ No cached common data available for second display in ORDER ITEM',
        );
      }

      // Use the optimized update method for the second display

      await _updateSecondaryDisplayOptimized(data);
    } catch (e) {
      prints('Error in optimized second display update: $e');
      // Fallback to showing main customer display if there's an error
      if (mounted) {
        // Don't await this call to prevent blocking the UI thread
        ref.read(secondDisplayProvider.notifier).showMainCustomerDisplay();
      }
    }
  }

  Future<void> _updateSecondaryDisplayOptimized(
    Map<String, dynamic> data,
  ) async {
    try {
      await ref.read(slideshowProvider.notifier).updateSecondaryDisplay(data);
    } catch (e) {
      prints('Error updating second display: $e');
      // Fallback to basic update if there's an error
      if (mounted) {
        await ref.read(slideshowProvider.notifier).updateSecondaryDisplay(data);
      }
    }
  }

  Widget soldByMeasurement(
    SaleItemModel usedSaleItemModel,
    ItemModel itemModel,
    String? variantOptionName,
    String allModifierOptionName,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // circle
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 0.9),
                ),
                child: CircleAvatar(
                  backgroundColor: kWhiteColor,
                  radius: 17,
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Text('M', style: AppTheme.normalTextStyle()),
                  ),
                ),
              ),
              const SizedBox(width: 7.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            itemModel.name!,
                            style: AppTheme.normalTextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          'x ${usedSaleItemModel.quantity!.toStringAsFixed(3)}',
                          style: AppTheme.normalTextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 12,
                            color: kTextGray,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    variantOptionName != null
                        ? Text(
                          variantOptionName,
                          style: const TextStyle(
                            color: kTextGray,
                            fontSize: 13,
                          ),
                        )
                        : const SizedBox.shrink(),
                    allModifierOptionName != ''
                        ? Text(
                          allModifierOptionName,
                          style: const TextStyle(
                            color: kTextGray,
                            fontSize: 13,
                          ),
                        )
                        : const SizedBox.shrink(),
                    saleItemModel.comments!.trim() != ''
                        ? Text(
                          saleItemModel.comments!,
                          style: AppTheme.italicTextStyle(),
                        )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
              SizedBox(width: 5.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RollingNumber(
                    value: getSaleItemPrice(usedSaleItemModel).abs(),
                    prefix: "${'rm'.tr()} ",
                    style: AppTheme.normalTextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Text(
                  //   usedSaleItemModel.discountTotal!
                  //       .toStringAsFixed(2),
                  //   style: AppTheme.mediumTextStyle(),
                  // ),
                  // Text(
                  //     usedSaleItemModel.taxAfterDiscount!
                  //         .toStringAsFixed(2),
                  //     style: AppTheme.mediumTextStyle()),
                  // Text(
                  //     usedSaleItemModel.totalAfterDiscAndTax!
                  //         .toStringAsFixed(2),
                  //     style: AppTheme.mediumTextStyle()),
                ],
              ),
            ],
          ),
          // Row(
          //   children: [
          //     Text(
          //         usedSaleItemModel.id! +
          //             usedSaleItemModel.updatedAt!
          //                 .toIso8601String(),
          //         style: AppTheme.normalTextStyle(fontSize: 10)),
          //   ],
          // )
        ],
      ),
    );
  }

  Widget soldByCustomPrice(
    SaleItemModel usedSaleItemModel,
    ItemModel itemModel,
    String? variantOptionName,
    String allModifierOptionName,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // circle
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 0.9),
                ),
                child: CircleAvatar(
                  backgroundColor: kWhiteColor,
                  radius: 17,
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Text('C', style: AppTheme.normalTextStyle()),
                  ),
                ),
              ),
              const SizedBox(width: 7.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            itemModel.name ?? 'Deleted Item',
                            style: AppTheme.normalTextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          itemModel.soldBy == ItemSoldByEnum.measurement
                              ? 'x ${usedSaleItemModel.quantity!.toStringAsFixed(3)}'
                              : 'x ${usedSaleItemModel.quantity!.toStringAsFixed(0)}',
                          style: AppTheme.normalTextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 12,
                            color: kTextGray,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    variantOptionName != null
                        ? Text(
                          variantOptionName,
                          style: const TextStyle(
                            color: kTextGray,
                            fontSize: 13,
                          ),
                        )
                        : const SizedBox.shrink(),
                    allModifierOptionName != ''
                        ? Text(
                          allModifierOptionName,
                          style: const TextStyle(
                            color: kTextGray,
                            fontSize: 13,
                          ),
                        )
                        : const SizedBox.shrink(),
                    saleItemModel.comments!.trim() != ''
                        ? Text(
                          saleItemModel.comments!,
                          style: AppTheme.italicTextStyle(),
                        )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
              SizedBox(width: 5.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RollingNumber(
                    value: getSaleItemPrice(usedSaleItemModel).abs(),
                    prefix: "${'rm'.tr()} ",
                    style: AppTheme.normalTextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Text(
                  //   usedSaleItemModel.discountTotal!
                  //       .toStringAsFixed(2),
                  //   style: AppTheme.mediumTextStyle(),
                  // ),
                  // Text(
                  //     usedSaleItemModel.taxAfterDiscount!
                  //         .toStringAsFixed(2),
                  //     style: AppTheme.mediumTextStyle()),
                  // Text(
                  //     usedSaleItemModel.totalAfterDiscAndTax!
                  //         .toStringAsFixed(2),
                  //     style: AppTheme.mediumTextStyle()),
                ],
              ),
            ],
          ),
          // Row(
          //   children: [
          //     Text(
          //         usedSaleItemModel.id! +
          //             usedSaleItemModel.updatedAt!
          //                 .toIso8601String(),
          //         style: AppTheme.normalTextStyle(fontSize: 10)),
          //   ],
          // )
        ],
      ),
    );
  }

  Widget soldByItem(
    SaleItemModel usedSaleItemModel,
    ItemModel itemModel,
    String? variantOptionName,
    String allModifierOptionName,
  ) {
    String qty = usedSaleItemModel.quantity?.toStringAsFixed(0) ?? '0';
    // String qty = '123';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 0.9),
                ),
                child: CircleAvatar(
                  backgroundColor: kWhiteColor,
                  radius: 17,
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Text(
                      qty.length >= 4 ? 'I' : qty,
                      style: AppTheme.normalTextStyle(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemModel.name!,
                      style: AppTheme.normalTextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    qty.length >= 4
                        ? Text(
                          'x $qty',
                          style: const TextStyle(
                            color: kTextGray,
                            fontSize: 13,
                          ),
                        )
                        : const SizedBox.shrink(),
                    variantOptionName != null
                        ? Text(
                          variantOptionName,
                          style: const TextStyle(
                            color: kTextGray,
                            fontSize: 13,
                          ),
                        )
                        : const SizedBox.shrink(),
                    allModifierOptionName != ''
                        ? Text(
                          allModifierOptionName,
                          style: const TextStyle(
                            color: kTextGray,
                            fontSize: 13,
                          ),
                        )
                        : const SizedBox.shrink(),
                    saleItemModel.comments!.trim() != ''
                        ? Text(
                          saleItemModel.comments!,
                          style: AppTheme.italicTextStyle(),
                        )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RollingNumber(
                    value: getSaleItemPrice(usedSaleItemModel).abs(),
                    prefix: "${'rm'.tr()} ",
                    style: AppTheme.normalTextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Text(
                  //   usedSaleItemModel.discountTotal!
                  //       .toStringAsFixed(2),
                  //   style: AppTheme.mediumTextStyle(),
                  // ),
                  // Text(
                  //     usedSaleItemModel.taxAfterDiscount!
                  //         .toStringAsFixed(2),
                  //     style: AppTheme.mediumTextStyle()),
                  // Text(
                  //     usedSaleItemModel.totalAfterDiscAndTax!
                  //         .toStringAsFixed(2),
                  //     style: AppTheme.mediumTextStyle()),
                ],
              ),
            ],
          ),
          // Row(
          //   children: [
          //     Text(
          //         usedSaleItemModel.id! +
          //             usedSaleItemModel.updatedAt!
          //                 .toIso8601String(),
          //         style: AppTheme.normalTextStyle(fontSize: 10)),
          //   ],
          // )
        ],
      ),
    );
  }

  // double discountTotal(BuildContext context, SaleItemModel usedSaleItemModel) {
  //   return DiscountBloc.getGrandTotalDiscountAmountBasedOnSaleItems(
  //     context,
  //     getSaleItemPrice(usedSaleItemModel),
  //   );
  // }

  // double totalAfterDiscountAndTax(
  //   BuildContext context,
  //   SaleItemModel saleItemModel,
  // ) {
  //   double totalTax = getTax(saleItemModel);
  //   double totalDiscount = discountTotal(context, saleItemModel);

  //   return (getSaleItemPrice(saleItemModel) - totalDiscount) + totalTax;
  // }

  double getSaleItemPrice(SaleItemModel saleItemModel) {
    // double totalVariantPrice = 0;

    // double total = 0;
    // ItemModel? itemModel =
    //     ItemBloc.getItemModelById(context, saleItemModel.itemId!);

    // if (itemModel != null) {
    //   double itemPrice = itemModel.price!;
    //   total = itemPrice * saleItemModel.quantity! + totalVariantPrice;

    //   return total.toStringAsFixed(2);
    // }

    return saleItemModel.price ?? 0.00;
  }

  // double getTax(
  //   SaleItemModel saleItemModel,
  // ) {
  //   // (subtotal - discount) * 2/100
  //   double subTotal = getSaleItemPrice(saleItemModel);
  //   double totalDiscount =
  //       DiscountBloc.getGrandTotalDiscountAmountBasedOnSaleItems(
  //     context,
  //     getSaleItemPrice(saleItemModel),
  //   );
  //   // tax percent = 2%
  //   double taxPercent = TaxBloc.getRateById(context, saleItemModel.taxId!);
  //   double totalTax = (subTotal - totalDiscount) * (taxPercent / 100);

  //   return totalTax;
  // }

  // Widget getVariantDetailsName(VariantDetailsModel? variantDetailModel) {
  //   if (variantDetailModel == null) {
  //     return Container();
  //   }
  //   return Text(
  //     "${variantDetailModel.variantName} - ${variantDetailModel.variantOptionName}",
  //     style: AppTheme.normalTextStyle(fontSize: 10.sp),
  //   );
  // }

  // Widget getVariantDetailsPrice(VariantDetailsModel? variantDetailModel) {
  //   if (variantDetailModel == null) {
  //     return Container();
  //   }
  //   return Text(
  //     "RM".tr(
  //       args: [variantDetailModel.variantOptionPrice.toStringAsFixed(2)],
  //     ),
  //     style: AppTheme.normalTextStyle(fontSize: 10.sp),
  //   );
  // }
}
