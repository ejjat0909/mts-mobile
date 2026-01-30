import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/home_receipt_navigator_enum.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/home_receipt/components/cancelled_refund_order_item.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';

class ListReceiptsItemSidebar extends StatefulWidget {
  final ReceiptNotifier receiptNotifier;

  const ListReceiptsItemSidebar({super.key, required this.receiptNotifier});

  @override
  State<ListReceiptsItemSidebar> createState() =>
      _ListReceiptsItemSidebarState();
}

class _ListReceiptsItemSidebarState extends State<ListReceiptsItemSidebar> {
  @override
  Widget build(BuildContext context) {
    final receiptItems = widget.receiptNotifier.getReceiptItemsForRefund;

    final hasItem = receiptItems.isNotEmpty;
    final receiptNavigator = widget.receiptNotifier.getPageIndex;

    prints('LIST RECEIPTS ITEM SIDEBAR ${receiptItems.length}');

    return Expanded(
      flex: 2,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: kPrimaryColor.withValues(alpha: 1),
                    width: 0.05,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(1, 10),
                    blurRadius: 10,
                    spreadRadius: 0,
                    color: Colors.black.withValues(alpha: 0.10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Divider(thickness: 1, height: 1),
                  hasItem
                      ? ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: receiptItems.length,
                        itemBuilder: (BuildContext context, int index) {
                          // if (kDebugMode) {
                          //   prints(
                          //       'VARIANT OPTION JSON for ${receiptItems[index].name} ${receiptItems[index].variants}');
                          //   prints(
                          //       'MODIFIER OPTION JSON ${receiptItems[index].modifiers}');
                          // }
                          return CancelledRefundOrderItem(
                            receiptItemModel: receiptItems[index],
                            press: () {
                              if (receiptItems[index].quantity! > 0) {
                                if (receiptNavigator ==
                                    HomeReceiptNavigatorEnum.receiptRefund) {
                                  prints('CANCELLED REFUND');
                                  widget.receiptNotifier
                                      .removeReceiptItemAndMoveToRefund(
                                        context,
                                        receiptItems[index],
                                      );
                                }
                              }
                            },
                          );
                        },
                      )
                      : Column(
                        children: [
                          const Space(10),
                          Center(child: Text('noItem'.tr())),
                        ],
                      ),
                  const Space(10),

                  // Padding(
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 15,
                  //     vertical: 10,
                  //   ),
                  //   child: Column(
                  //     children: [
                  //       adjustedPrice(saleItemNotifier),
                  //       const Space(10),
                  const Divider(thickness: 1, height: 1),
                  const Space(10),
                  discount(widget.receiptNotifier),
                  const Space(5),
                  tax(widget.receiptNotifier),
                  const Space(5),
                  taxIncluded(widget.receiptNotifier),
                  const Space(5),
                  total(widget.receiptNotifier),
                  //       const Space(20),
                  //       paymentNavigation == PaymentNavigatorEnum.PAYMENT_SCREEN
                  //           ? splitAndAdjustmentPaymentButton()
                  //           : const SizedBox(),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Padding total(ReceiptNotifier receiptNotifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'total'.tr(),
            style: AppTheme.mediumTextStyle(color: kBlackColor),
          ),
          Text(
            FormatUtils.formatNumber(
              'RM'.tr(
                args: [
                  (receiptNotifier.getTotalAfterDiscountAndTax.toStringAsFixed(
                    2,
                  )),
                ],
              ),
            ),
            style: AppTheme.mediumTextStyle(color: kBlackColor),
          ),
        ],
      ),
    );
  }

  Padding discount(ReceiptNotifier receiptNotifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'discount'.tr(),
            style: AppTheme.mediumTextStyle(color: kTextGray),
          ),
          Text(
            FormatUtils.formatNumber(
              'RM'.tr(
                args: [(receiptNotifier.getTotalDiscount.toStringAsFixed(2))],
              ),
            ),
            style: AppTheme.mediumTextStyle(color: kTextGray),
          ),
        ],
      ),
    );
  }

  Padding tax(ReceiptNotifier receiptNotifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('tax'.tr(), style: AppTheme.mediumTextStyle(color: kTextGray)),
          Text(
            FormatUtils.formatNumber(
              'RM'.tr(
                args: [
                  (receiptNotifier.getTaxAfterDiscount.toStringAsFixed(2)),
                ],
              ),
            ),
            style: AppTheme.mediumTextStyle(color: kTextGray),
          ),
        ],
      ),
    );
  }

  Padding taxIncluded(ReceiptNotifier receiptNotifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${'tax'.tr()} (Included)',
            style: AppTheme.mediumTextStyle(color: kTextGray),
          ),
          Text(
            FormatUtils.formatNumber(
              'RM'.tr(
                args: [
                  (receiptNotifier.getTaxIncludedAfterDiscount.toStringAsFixed(
                    2,
                  )),
                ],
              ),
            ),
            style: AppTheme.mediumTextStyle(color: kTextGray),
          ),
        ],
      ),
    );
  }
}
