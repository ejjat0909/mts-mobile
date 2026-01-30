import 'package:dotted_line/dotted_line.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/enum/db_response_enum.dart';
import 'package:mts/core/enum/payment_navigator_enum.dart';
import 'package:mts/core/utils/calc_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/ui_utils.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/presentation/common/widgets/button_bottom.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/customer_display_preview/main_customer_display_show_receipt.dart';
import 'package:mts/presentation/features/home/home_screen.dart';
import 'package:mts/presentation/features/split_payment/components/split_order_item.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/payment/payment_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';
import 'package:mts/providers/slideshow/slideshow_providers.dart';
import 'package:mts/providers/split_payment/split_payment_providers.dart';

class SplitPaymentDetails extends ConsumerStatefulWidget {
  const SplitPaymentDetails({super.key});

  @override
  ConsumerState<SplitPaymentDetails> createState() =>
      _SplitPaymentDetailsState();
}

class _SplitPaymentDetailsState extends ConsumerState<SplitPaymentDetails> {
  @override
  Widget build(BuildContext context) {
    final splitPaymentNotifier = ref.read(splitPaymentProvider.notifier);
    final splitPaymentState = ref.watch(splitPaymentProvider);
    final saleItemModels = splitPaymentState.saleItems;
    final listOrderData = splitPaymentNotifier.getOrderList();
    return Expanded(
      flex: 5,
      child:
          listOrderData.isNotEmpty
              ? Column(
                children: [
                  Space(20.h),
                  Row(
                    children: [
                      Expanded(flex: 4, child: Container()),
                      Expanded(
                        child: ButtonBottom(
                          'split'.tr(),
                          press: () async {
                            await onPressSplit(context, ref);
                          },
                        ),
                      ),
                      SizedBox(width: 20.w),
                    ],
                  ),
                  Space(20.h),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  vertical: 20.h,
                                  horizontal: 20.w,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: UIUtils.itemShadows,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'receipt'.tr(),
                                      style: AppTheme.h1TextStyle(),
                                    ),
                                    Space(20.h),
                                    const DottedLine(),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: listOrderData.length,
                                      itemBuilder: (context, index) {
                                        final order = listOrderData[index];
                                        return SplitOrderItem(
                                          orderData: order,
                                          press: () async {
                                            await onPress(
                                              saleItemModels,
                                              index,
                                              context,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    Space(10.h),
                                    const DottedLine(),
                                    Space(20.h),
                                    //adjustedPrice(splitPaymentNotifier),
                                    discount(),

                                    tax(),
                                    taxIncluded(),
                                    const Divider(thickness: 1),
                                    total(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FontAwesomeIcons.receipt, size: 100, color: white),
                  Space(40.h),
                  Text(
                    'selectOrderToStartPayment'.tr(),
                    style: AppTheme.mediumTextStyle(),
                  ),
                ],
              ),
    );
  }

  // Static variable to track if a split operation is in progress
  static bool _isSplitProcessing = false;
  // Cache for slideshow data to avoid repeated fetches

  Future<void> onPressSplit(BuildContext context, WidgetRef ref) async {
    // Prevent multiple simultaneous split operations
    if (_isSplitProcessing) {
      prints('Split operation already in progress, ignoring tap');
      return;
    }

    _isSplitProcessing = true;

    try {
      // Get notifiers from ref
      final saleItemsNotifier = ref.read(saleItemProvider.notifier);
      final splitPaymentNotifier = ref.read(splitPaymentProvider.notifier);
      final paymentNotifier = ref.read(paymentProvider.notifier);

      // Batch state updates to minimize rebuilds
      _updateSplitPaymentState(
        saleItemsNotifier,
        splitPaymentNotifier,
        paymentNotifier,
      );

      // Get slideshow model with caching
      final SlideshowModel? currSdModel = await _getCachedSlideshowModel();

      // Create optimized data transfer package
      final Map<String, dynamic> data = await _createOptimizedDataPackage(
        saleItemsNotifier,
        splitPaymentNotifier,
        currSdModel,
      );
      // Optimize the delay - reduce from 300ms to 150ms for better responsiveness
      await Future.delayed(const Duration(milliseconds: 200));

      /// [SHOW SECOND SCREEN: CUSTOMER SHOW RECEIPT SCREEN]
      await _updateSecondaryDisplayOptimized(data);
    } finally {
      _isSplitProcessing = false;
    }
  }

  /// Batch state updates to minimize rebuilds
  void _updateSplitPaymentState(
    SaleItemNotifier saleItemsNotifier,
    SplitPaymentNotifier splitPaymentNotifier,
    PaymentNotifier paymentNotifier,
  ) {
    // Group related state updates together
    saleItemsNotifier.setTotalWithAdjustedPrice(0);
    saleItemsNotifier.setIsSplitPayment(true);
    saleItemsNotifier.setCanBackToSalesPage(false);

    // Calculate totals once
    splitPaymentNotifier.calcTotalWithAdjustedPrice();

    // Set payment navigator
    paymentNotifier.setNewPaymentNavigator(PaymentNavigatorEnum.paymentScreen);
  }

  /// Get slideshow model with caching to avoid repeated API calls
  Future<SlideshowModel?> _getCachedSlideshowModel() async {
    // Use cached slideshow model from home_screen.dart to avoid DB calls
    SlideshowModel? currSdModel = Home.getCachedSlideshowModel();

    // If cache is not available, fallback to DB call (should be rare)
    if (currSdModel == null) {
      prints('⚠️ Slideshow cache not available, falling back to DB call');
      try {
        final Map<String, dynamic> slideshowMap =
            await ref.read(slideshowProvider.notifier).getLatestModel();

        currSdModel = slideshowMap[DbResponseEnum.data];
      } catch (e) {
        prints('❌ Error fetching slideshow model: $e');
        return null;
      }
    } else {
      prints('✅ Using cached slideshow model for split payment');
    }

    return currSdModel;
  }

  /// Create optimized data package with only essential information
  Future<Map<String, dynamic>> _createOptimizedDataPackage(
    SaleItemNotifier saleItemsNotifier,
    SplitPaymentNotifier splitPaymentNotifier,
    SlideshowModel? slideshowModel,
  ) async {
    UserModel userModel = GetIt.instance<UserModel>();

    // Create lightweight data package
    Map<String, dynamic> data = {
      // Essential split payment data
      DataEnum.userModel: userModel.toJson(),
      DataEnum.slideshow: slideshowModel?.toJson() ?? {},
      DataEnum.showThankYou: false,
      DataEnum.isCharged: false,
      // Add split payment identifier
      'isSplitPayment': true,
      'splitUpdateId': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    // Add split payment specific data efficiently
    final spn = splitPaymentNotifier;

    // Only serialize data that's actually needed for the display
    data[DataEnum.listSaleItems] =
        spn.getSaleItems.map((e) => e.toJson()).toList();
    data[DataEnum.listSM] =
        spn.getSaleModifiers.map((e) => e.toJson()).toList();
    data[DataEnum.listSMO] =
        spn.getSaleModifierOptions.map((e) => e.toJson()).toList();

    // Add calculated totals
    data[DataEnum.totalAmountRemaining] = spn.getTotalAmountRemaining;
    data[DataEnum.totalAfterDiscAndTax] = spn.getTotalAfterDiscountAndTax;
    data[DataEnum.totalDiscount] = spn.getTotalDiscount;
    data[DataEnum.totalTax] = spn.getTaxAfterDiscount;
    data[DataEnum.totalTaxIncluded] = spn.getTaxIncludedAfterDiscount;
    data[DataEnum.totalWithAdjustedPrice] = CalcUtils.calcCashRounding(
      spn.getTotalWithAdjustedPrice,
    );

    // prints(data);

    // Add any additional data from saleItemsNotifier that's not already included
    final additionalData = saleItemsNotifier.getMapDataToTransfer();
    additionalData.forEach((key, value) {
      if (!data.containsKey(key)) {
        data[key] = value;
      }
    });

    return data;
  }

  /// Optimized method to update the second display
  Future<void> _updateSecondaryDisplayOptimized(
    Map<String, dynamic> data,
  ) async {
    try {
      // Check if we're already on the receipt screen to avoid unnecessary navigation
      final String currentRouteName =
          ref.read(secondDisplayProvider).currentRouteName;
      final SecondDisplayNotifier secondDisplayNotifier = ref.read(
        secondDisplayProvider.notifier,
      );

      if (currentRouteName == CustomerShowReceipt.routeName) {
        // If already on receipt screen, use optimized update
        await secondDisplayNotifier.updateSecondaryDisplay(data);
      } else {
        // If not on receipt screen, navigate to it
        await secondDisplayNotifier.navigateSecondScreen(
          CustomerShowReceipt.routeName,
          data: data,
        );
      }
    } catch (e) {
      prints('Error updating secondary display: $e');
      // Fallback to full navigation if update fails
      await ref
          .read(secondDisplayProvider.notifier)
          .navigateSecondScreen(CustomerShowReceipt.routeName, data: data);
    }
  }

  Future<void> onPress(
    List<SaleItemModel> saleItemList,
    int index,
    BuildContext context,
  ) async {
    final currentSaleItem = saleItemList[index];
    ItemModel? itemModel = await ref
        .read(itemProvider.notifier)
        .getItemModelById(currentSaleItem.itemId!);

    if (itemModel == null) {
      return;
    }

    final splitPaymentNotifier = ref.read(splitPaymentProvider.notifier);
    await splitPaymentNotifier.removeSaleItemAndMoveToOrder(
      saleItemList[index],
      itemModel,
    );
  }

  Row total() {
    final splitPaymentState = ref.watch(splitPaymentProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('total'.tr(), style: AppTheme.mediumTextStyle(color: kBlackColor)),
        Text(
          'RM'.tr(
            args: [
              (splitPaymentState.totalAfterDiscountAndTax.toStringAsFixed(2)),
            ],
          ),
          style: AppTheme.mediumTextStyle(color: kBlackColor),
        ),
      ],
    );
  }

  // Widget adjustedPrice(SplitPaymentNotifier splitPaymentNotifier) {
  //   final saleItemNotifier = context.watch<SaleItemNotifier>();
  //   if (saleItemNotifier.getAdjustedPrice == 0) {
  //     return Container();
  //   }
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       Text(
  //         "adjustment".tr(),
  //         style: AppTheme.mediumTextStyle(),
  //       ),
  //       Text(
  //         "RM".tr(args: [
  //           "-${saleItemNotifier.getAdjustedPrice.toStringAsFixed(2)}"
  //         ]),
  //         style: AppTheme.mediumTextStyle(),
  //       ),
  //     ],
  //   );
  // }

  Row tax() {
    final splitPaymentState = ref.watch(splitPaymentProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('tax'.tr(), style: AppTheme.mediumTextStyle()),
        Text(
          'RM'.tr(
            args: [(splitPaymentState.taxAfterDiscount.toStringAsFixed(2))],
          ),
          //  splitPaymentNotifier.tax.toStringAsFixed(2),
          style: AppTheme.mediumTextStyle(),
        ),
      ],
    );
  }

  Widget taxIncluded() {
    final splitPaymentState = ref.watch(splitPaymentProvider);
    double taxIncluded = splitPaymentState.taxIncludedAfterDiscount;
    if (taxIncluded > 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("${'tax'.tr()} (Included)", style: AppTheme.mediumTextStyle()),
          Text(
            'RM'.tr(args: [(taxIncluded.toStringAsFixed(2))]),
            //  splitPaymentNotifier.tax.toStringAsFixed(2),
            style: AppTheme.mediumTextStyle(),
          ),
        ],
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget discount() {
    final splitPaymentState = ref.watch(splitPaymentProvider);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('discount'.tr(), style: AppTheme.mediumTextStyle()),
          Text(
            '-${"RM".tr(args: [(splitPaymentState.totalDiscount.toStringAsFixed(2))])}',
            //   saleItemNotifier.getSalesDiscount.toStringAsFixed(2),
            style: AppTheme.mediumTextStyle(),
          ),
        ],
      ),
    );
  }
}

// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:mts/core/config/constants.dart';
// import 'package:mts/enum/payment_navigator_enum.dart';
// import 'package:mts/providers/payment_notifier.dart';
// import 'package:mts/presentation/common/widgets/button_primary.dart';
// import 'package:mts/public_components/customer_card_display.dart';
// import 'package:mts/public_components/space.dart';
// import 'package:mts/screens/split_payment/components/payment_row.dart';
// import 'package:provider/provider.dart';

// class SplitPaymentDetails extends StatefulWidget {
//   final double totalPrice;
//   const SplitPaymentDetails({super.key, required this.totalPrice});

//   @override
//   State<SplitPaymentDetails> createState() => _SplitPaymentDetailsState();
// }

// class _SplitPaymentDetailsState extends State<SplitPaymentDetails> {
//   final List<int> _payments = [0];
//   final List<TextEditingController> _inputControllers = [
//     TextEditingController()
//   ];
//   final List<String> _selectedValues = ["cash".tr()];
//   final List<bool> _isPaid = [false];

//   @override
//   void initState() {
//     super.initState();
//   }

//   void _addPayment() {
//     setState(() {
//       _payments.add(_payments.length); // Add a new payment
//       _inputControllers.add(TextEditingController()); // add a new controller
//       _selectedValues.add("Cash");
//       _isPaid.add(false);
//     });
//   }

//   // Removes a payment at the specified index and updates the state if there are more than one payment.
//   void _removePayment(int index) {
//     setState(() {
//       if (_payments.length > 1) {
//         // Move the item to be removed to the end
//         _payments.removeAt(index);
//         _inputControllers.removeAt(index);
//         _selectedValues.removeAt(index);
//         _isPaid.removeAt(index);
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     bool allPaid = _isPaid.every((element) => element == true);

//     return Expanded(
//       flex: 5,
//       child: Column(
//         children: [
//           Expanded(
//             child: Container(
//               margin: EdgeInsets.symmetric(
//                 vertical: 20.h,
//                 horizontal: 20.w,
//               ),
//               padding: EdgeInsets.symmetric(
//                 vertical: 20.h,
//                 horizontal: 20.w,
//               ),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withValues(alpha: 0.5),
//                     spreadRadius: -4,
//                     blurRadius: 35,
//                     offset: const Offset(0, 9), // changes position of shadow
//                   ),
//                 ],
//                 borderRadius: const BorderRadius.all(
//                   Radius.circular(20),
//                 ),
//               ),
//               child: Column(
//                 children: [
//                   Text(
//                     "totalAmountRemaining".tr(),
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     widget.totalPrice.toStringAsFixed(2),
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                         fontSize: 40, fontWeight: FontWeight.bold),
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       ClipRRect(
//                           borderRadius:
//                               const BorderRadius.all(Radius.circular(32.0)),
//                           child: Material(
//                             shadowColor: Colors.transparent,
//                             color: Colors.transparent,
//                             child: IconButton(
//                               icon: const Icon(
//                                   Icons.remove_circle_outline_rounded,
//                                   size: 32,
//                                   color: kPrimaryColor),
//                               onPressed: () {
//                                 _removePayment(_payments.length - 1);
//                               },
//                             ),
//                           )),
//                       SizedBox(
//                         width: 90,
//                         child: ListTile(
//                           dense: true,
//                           title: Text(
//                             _payments.length.toString(),
//                             textAlign: TextAlign.center,
//                             style: const TextStyle(
//                                 fontSize: 20, fontWeight: FontWeight.bold),
//                           ),
//                           subtitle: Text(
//                             "payments".tr(),
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                       ),
//                       ClipRRect(
//                         borderRadius:
//                             const BorderRadius.all(Radius.circular(32.0)),
//                         child: Material(
//                           shadowColor: Colors.transparent,
//                           color: Colors.transparent,
//                           child: IconButton(
//                             icon: const Icon(Icons.add_circle_outline_rounded,
//                                 size: 32, color: kPrimaryColor),
//                             onPressed: () {
//                               _addPayment();
//                             },
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const Divider(height: 1),
//                   const SizedBox(height: 20),
//                   Expanded(
//                     child: ListView.builder(
//                         physics: const BouncingScrollPhysics(),
//                         itemCount: _payments.length,
//                         shrinkWrap: true,
//                         itemBuilder: (context, index) {
//                           return PaymentRow(
//                             length: _payments.length,
//                             inputController: _inputControllers[index],
//                             selectedValue: _selectedValues[index],
//                             isPaid: _isPaid[index],
//                             onPressPaid: (value) {
//                               setState(() {
//                                 _isPaid[index] = value;
//                               });
//                             },
//                             onPressDelete: () {
//                               _removePayment(index);
//                             },
//                             onSelectedChanged: (newValue) {
//                               setState(() {
//                                 _selectedValues[index] = newValue;
//                               });
//                             },
//                           );
//                         }),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: ButtonPrimary(
//               primaryColor: kPrimaryColor,
//               onPressed: allPaid
//                   ? () {
//                       context.read<PaymentNotifier>().setNewPaymentNavigator(
//                             PaymentNavigatorEnum.SALE_SUMMARY,
//                             title: 'salesSummary'.tr(),
//                           );
//                     }
//                   : null,
//               text: "done".tr(),
//             ),
//           ),
//           const SizedBox(
//             height: 10,
//           ),
//         ],
//       ),
//     );
//   }
// }
