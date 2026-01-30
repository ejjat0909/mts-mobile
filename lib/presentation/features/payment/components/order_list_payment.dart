import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/payment_navigator_enum.dart';
import 'package:mts/core/utils/calc_utils.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/button_primary.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/sales/components/adjustment_dialogue.dart';
import 'package:mts/presentation/features/sales/components/order_item.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/payment/payment_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/sale_item/sale_item_state.dart';
import 'package:mts/providers/shift/shift_providers.dart';
import 'package:mts/providers/split_payment/split_payment_providers.dart';

class OrderListPayment extends ConsumerStatefulWidget {
  const OrderListPayment({super.key});

  @override
  ConsumerState<OrderListPayment> createState() => _OrderListPaymentState();
}

class _OrderListPaymentState extends ConsumerState<OrderListPayment> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final saleItemsState = ref.watch(saleItemProvider);
    final saleItemNotifier = ref.watch(saleItemProvider.notifier);
    final splitPaymentNotifier = ref.read(splitPaymentProvider.notifier);
    final splitPaymentState = ref.watch(splitPaymentProvider);
    final paymentState = ref.watch(paymentProvider);

    bool isSplitPayment = saleItemsState.isSplitPayment;
    final saleItemList =
        isSplitPayment ? splitPaymentState.saleItems : saleItemsState.saleItems;
    final hasItem = saleItemList.isNotEmpty;
    final selectedCategoryEat = saleItemsState.orderOptionModel;
    final paymentNavigation = paymentState.paymentNavigator;

    return Expanded(
      flex: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            width: double.infinity,
            decoration: const BoxDecoration(color: white),
            child: Center(
              child: Text(
                selectedCategoryEat?.name ?? '',
                style: AppTheme.normalTextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
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
                  Expanded(
                    child:
                        hasItem
                            ? CustomScrollView(
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                // Top static content if needed
                                SliverToBoxAdapter(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: white,
                                    ),
                                    child: Column(
                                      children: const [
                                        // Add any header widgets here if needed
                                      ],
                                    ),
                                  ),
                                ),

                                // The dynamic list - only order items are scrollable
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (BuildContext context, int index) {
                                      final order =
                                          isSplitPayment
                                              ? splitPaymentNotifier
                                                  .getOrderList()[index]
                                              : saleItemNotifier
                                                  .getOrderList()[index];
                                      return OrderItem(
                                        orderData: order,
                                        press: () async {
                                          prints(
                                            'delete from order list payment',
                                          );
                                          await onPress(
                                            saleItemNotifier,
                                            paymentNavigation,
                                            saleItemList,
                                            index,
                                            context,
                                          );
                                        },
                                      );
                                    },
                                    childCount:
                                        isSplitPayment
                                            ? splitPaymentNotifier
                                                .getOrderList()
                                                .length
                                            : saleItemNotifier
                                                .getOrderList()
                                                .length,
                                  ),
                                ),
                              ],
                            )
                            : Center(child: Text('noItem'.tr())),
                  ),
                  const Space(10),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        paymentNavigation == PaymentNavigatorEnum.paymentScreen
                            ? adjustedPrice(
                              saleItemsState,
                              splitPaymentNotifier,
                            )
                            : const SizedBox(),
                        discount(saleItemsState, splitPaymentNotifier),
                        tax(saleItemsState, splitPaymentNotifier),
                        taxIncluded(saleItemsState, splitPaymentNotifier),
                        const Space(10),
                        paymentNavigation == PaymentNavigatorEnum.paymentScreen
                            ? (saleItemsState.paymentTypeModel?.id != null &&
                                    (saleItemsState.paymentTypeModel?.name
                                            ?.toLowerCase()
                                            .contains('cash') ??
                                        false)
                                ? roundingCash(
                                  saleItemsState,
                                  splitPaymentNotifier,
                                )
                                : const SizedBox.shrink())
                            : const SizedBox(),
                        const Divider(thickness: 0.3),
                        total(
                          saleItemsState,
                          paymentNavigation,
                          splitPaymentNotifier,
                        ),
                        const Space(20),
                        paymentNavigation == PaymentNavigatorEnum.paymentScreen
                            ? (splitAndAdjustmentPaymentButton(
                              saleItemNotifier,
                              saleItemsState,
                              splitPaymentNotifier,
                            ))
                            : const SizedBox(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> onPress(
    SaleItemNotifier saleItemNotifier,
    int paymentNavigation,
    List<SaleItemModel> saleItemList,
    int index,
    BuildContext context,
  ) async {
    if (paymentNavigation == PaymentNavigatorEnum.splitPayment) {
      final saleItemModel = saleItemList[index];

      ItemModel? itemModel = await ref
          .read(itemProvider.notifier)
          .getItemModelById(saleItemModel.itemId!);

      if (itemModel == null) {
        return;
      }
    }
  }

  Widget splitAndAdjustmentPaymentButton(
    SaleItemNotifier saleItemsNotifier,
    SaleItemState saleItemsState,
    SplitPaymentNotifier splitPaymentNotifier,
  ) {
    //prints('splitAndAdjustmentPaymentButton EXIST');
    //prints(saleItemsState.totalWithAdjustedPrice);
    if (saleItemsState.isSplitPayment) {
      if (splitPaymentNotifier.getTotalAmountRemaining == 0.00) {
        return const SizedBox.shrink();
      }
    } else {
      if (saleItemsState.totalAmountRemaining == 0.00) {
        // prints('totalAmountRemaining == 0.00');
        return const SizedBox.shrink();
      }
    }
    return Row(
      children: [
        Expanded(
          child: ButtonTertiary(
            text: 'adjustments'.tr(),
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return const AdjustmentDialogue();
                },
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ButtonPrimary(
            text: 'splitPayment'.tr(),
            onPressed: () {
              final splitPaymentState = ref.read(splitPaymentProvider);
              List<SaleItemModel> selectedSaleItems =
                  saleItemsState.isSplitPayment
                      ? splitPaymentState.saleItems
                      : saleItemsState.saleItems;

              if (selectedSaleItems.isEmpty) {
                ThemeSnackBar.showSnackBar(context, 'noItemsFound'.tr());
                return;
              }

              ///[TESTING SPLIT PAYMENT]
              /// set to false because to show list items from sale item notifier
              if (selectedSaleItems.isNotEmpty) {
                saleItemsNotifier.setIsSplitPayment(false);
                ref
                    .read(paymentProvider.notifier)
                    .setNewPaymentNavigator(
                      PaymentNavigatorEnum.splitPayment,
                      title: 'splitPayment'.tr(),
                    );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget adjustedPrice(
    SaleItemState saleItemsState,
    SplitPaymentNotifier splitNotifier,
  ) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'adjustment'.tr(),
            style: AppTheme.normalTextStyle(
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          Text(
            saleItemsState.isSplitPayment
                ? '-${FormatUtils.formatNumber("RM".tr(args: [(splitNotifier.getAdjustedPrice.toStringAsFixed(2))]))}'
                : '-${FormatUtils.formatNumber("RM".tr(args: [(saleItemsState.adjustedPrice.toStringAsFixed(2))]))}',
            // saleItemNotifier.getAdjustedPrice.toStringAsFixed(2),
            style: AppTheme.normalTextStyle(
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget discount(
    SaleItemState saleItemsState,
    SplitPaymentNotifier splitNotifier,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'discount'.tr(),
            style: AppTheme.normalTextStyle(
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          saleItemsState.isSplitPayment
              ? Text(
                '-${"RM".tr(args: [(splitNotifier.getTotalDiscount.toStringAsFixed(2))])}',
                style: AppTheme.normalTextStyle(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              )
              : Text(
                '-${"RM".tr(args: [(saleItemsState.totalDiscount.toStringAsFixed(2))])}',
                style: AppTheme.normalTextStyle(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
        ],
      ),
    );
  }

  Row tax(SaleItemState saleItemsState, SplitPaymentNotifier splitNotifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('tax'.tr()),
        saleItemsState.isSplitPayment
            ? Text(
              FormatUtils.formatNumber(
                'RM'.tr(
                  args: [splitNotifier.getTaxAfterDiscount.toStringAsFixed(2)],
                ),
              ),
            )
            : Text(
              FormatUtils.formatNumber(
                'RM'.tr(
                  args: [saleItemsState.taxAfterDiscount.toStringAsFixed(2)],
                ),
              ),
            ),
      ],
    );
  }

  Widget taxIncluded(
    SaleItemState saleItemsState,
    SplitPaymentNotifier splitNotifier,
  ) {
    double taxIncluded =
        saleItemsState.isSplitPayment
            ? splitNotifier.getTaxIncludedAfterDiscount
            : saleItemsState.taxIncludedAfterDiscount;
    if (taxIncluded > 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "${'tax'.tr()} (Included)",
            style: textStyleNormal(color: kTextGray),
          ),
          Text(
            FormatUtils.formatNumber(
              'RM'.tr(args: [taxIncluded.toStringAsFixed(2)]),
            ),
            style: textStyleNormal(color: kTextGray),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Row roundingCash(
    SaleItemState saleItemsState,
    SplitPaymentNotifier splitNotifier,
  ) {
    PaymentTypeModel? ptm =
        saleItemsState.isSplitPayment
            ? splitNotifier.getPaymentTypeModel
            : saleItemsState.paymentTypeModel;

    // Calculate cashRound based on autoRounding attribute
    String cashRound = '';
    bool useRounding =
        ptm?.id != null
            ? ptm?.autoRounding ?? false
            : false; // Default to false if null

    if (useRounding) {
      cashRound =
          saleItemsState.isSplitPayment
              ? ref
                  .read(shiftProvider.notifier)
                  .calcChangeCashRounding(
                    splitNotifier.getTotalWithAdjustedPrice,
                  )
                  .toStringAsFixed(2)
              : ref
                  .read(shiftProvider.notifier)
                  .calcChangeCashRounding(saleItemsState.totalWithAdjustedPrice)
                  .toStringAsFixed(2);
    } else {
      cashRound = 0.toStringAsFixed(2);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('rounding'.tr()),
        Text(FormatUtils.formatNumber('RM'.tr(args: [cashRound]))),
      ],
    );
  }

  Row total(
    SaleItemState saleItemsState,
    int paymentNavigator,
    SplitPaymentNotifier splitNotifier,
  ) {
    // only calcCashRounding if payment type is auto rounding
    String afterCashRounding =
        saleItemsState.isSplitPayment
            ? splitNotifier.getPaymentTypeModel != null &&
                    splitNotifier.getPaymentTypeModel!.autoRounding!
                ? CalcUtils.calcCashRounding(
                  splitNotifier.getTotalWithAdjustedPrice,
                ).toStringAsFixed(2)
                : splitNotifier.getTotalWithAdjustedPrice.toStringAsFixed(2)
            : saleItemsState.paymentTypeModel?.id != null &&
                saleItemsState.paymentTypeModel!.autoRounding!
            ? CalcUtils.calcCashRounding(
              saleItemsState.totalWithAdjustedPrice,
            ).toStringAsFixed(2)
            : saleItemsState.totalWithAdjustedPrice.toStringAsFixed(2);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'total'.tr(),
          style: AppTheme.normalTextStyle(fontWeight: FontWeight.bold),
        ),
        paymentNavigator == PaymentNavigatorEnum.paymentScreen
            ? Text(
              FormatUtils.formatNumber('RM'.tr(args: [afterCashRounding])),
              style: AppTheme.normalTextStyle(fontWeight: FontWeight.bold),
            )
            : Text(
              saleItemsState.isSplitPayment
                  ? FormatUtils.formatNumber(
                    'RM'.tr(
                      args: [
                        splitNotifier.getTotalAfterDiscountAndTax
                            .toStringAsFixed(2),
                      ],
                    ),
                  )
                  : FormatUtils.formatNumber(
                    'RM'.tr(
                      args: [
                        saleItemsState.totalAfterDiscountAndTax.toStringAsFixed(
                          2,
                        ),
                      ],
                    ),
                  ),
              style: AppTheme.normalTextStyle(fontWeight: FontWeight.bold),
            ),
      ],
    );
  }
}
