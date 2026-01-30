import 'package:dotted_line/dotted_line.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/core/utils/network_utils.dart';
import 'package:mts/core/utils/ui_utils.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/dialogs/loading_dialogue.dart';
import 'package:mts/presentation/common/widgets/button_bottom.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/home_receipt/components/incoming_refund_order_item.dart';
import 'package:mts/providers/refund/refund_providers.dart';

class RefundDetails extends ConsumerStatefulWidget {
  final BuildContext homeReceiptBodyContext;
  const RefundDetails({super.key, required this.homeReceiptBodyContext});

  @override
  ConsumerState<RefundDetails> createState() => _RefundDetailsState();
}

class _RefundDetailsState extends ConsumerState<RefundDetails> {
  @override
  Widget build(BuildContext context) {
    final refundState = ref.watch(refundProvider);
    final refundNotifier = ref.watch(refundProvider.notifier);
    final refundItems = refundState.refundItems;
    return Expanded(
      flex: 5,
      child:
          refundItems.isNotEmpty
              ? Column(
                children: [
                  Space(20.h),
                  Row(
                    children: [
                      Expanded(flex: 4, child: Container()),
                      Expanded(
                        child: ButtonBottom(
                          '${"refund".tr()} ${"RM".tr(args: [refundState.totalAfterDiscountAndTax.toStringAsFixed(2)])}',
                          press: () async {
                            // check internet connection
                            if (await NetworkUtils.hasInternetConnection()) {
                              // show loading dialoge
                              LoadingDialog.show(context);
                              await refundNotifier.handleOnRefund(
                                closeLoading: () {
                                  LoadingDialog.hide(context);
                                },
                                onSuccess: () {},
                                onError: (errorMessage) {
                                  DialogUtils.printerErrorDialogue(
                                    widget.homeReceiptBodyContext,
                                    'connectionTimeout'.tr(),
                                    errorMessage,
                                    null,
                                  );
                                },
                              );
                            } else {
                              if (mounted) {
                                CustomDialog.show(
                                  context,
                                  icon: Icons.wifi_off_rounded,
                                  title: 'noInternet'.tr(),
                                  description: 'pleaseConnectInternet'.tr(),
                                  btnOkText: 'ok'.tr(),
                                  btnOkOnPress: () {
                                    NavigationUtils.pop(context);
                                  },
                                );
                              }
                            }
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
                                      'refundReceipt'.tr(),
                                      style: AppTheme.h1TextStyle(),
                                    ),
                                    Space(20.h),
                                    const DottedLine(),

                                    ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: refundItems.length,
                                      itemBuilder: (context, index) {
                                        return IncomingRefundOrderItem(
                                          receiptItemModel: refundItems[index],
                                          press: () {
                                            refundNotifier
                                                .removeItemFromRefundAndMoveToReceipt(
                                                  context,
                                                  refundItems[index],
                                                );

                                            // final removedItem = context
                                            //     .read<ReceiptNotifier>()
                                            //     .removeIncomingRefundReceiptItem(
                                            //         incomingReceiptItems![index]);
                                          },
                                        );
                                      },
                                    ),
                                    Space(10.h),
                                    const DottedLine(),
                                    Space(20.h),
                                    //adjustedPrice(splitPaymentNotifier),
                                    discount(refundState),
                                    const Space(5),
                                    tax(refundState),
                                    const Space(5),
                                    taxIncluded(refundState),
                                    const Space(10),
                                    // const Divider(thickness: 1),
                                    total(refundState),
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
                    'tapItemToStartRefund'.tr(),
                    style: AppTheme.mediumTextStyle(),
                  ),
                ],
              ),
    );
  }

  Row total(refundState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('total'.tr(), style: AppTheme.mediumTextStyle(color: kBlackColor)),
        Text(
          FormatUtils.formatNumber(
            'RM'.tr(
              args: [(refundState.totalAfterDiscountAndTax.toStringAsFixed(2))],
            ),
          ),
          style: AppTheme.mediumTextStyle(color: kBlackColor),
        ),
      ],
    );
  }

  Widget discount(refundState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'discount'.tr(),
          style: AppTheme.mediumTextStyle(color: kTextGray),
        ),
        Text(
          FormatUtils.formatNumber(
            'RM'.tr(args: [(refundState.totalDiscount.toStringAsFixed(2))]),
          ),
          style: AppTheme.mediumTextStyle(color: kTextGray),
        ),
      ],
    );
  }

  Widget tax(refundState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('tax'.tr(), style: AppTheme.mediumTextStyle(color: kTextGray)),
        Text(
          FormatUtils.formatNumber(
            'RM'.tr(args: [(refundState.taxAfterDiscount.toStringAsFixed(2))]),
          ),
          style: AppTheme.mediumTextStyle(color: kTextGray),
        ),
      ],
    );
  }

  Widget taxIncluded(refundState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${'tax'.tr()} (Included)',
          style: AppTheme.mediumTextStyle(color: kTextGray),
        ),
        Text(
          FormatUtils.formatNumber(
            'RM'.tr(
              args: [(refundState.taxIncludedAfterDiscount.toStringAsFixed(2))],
            ),
          ),
          style: AppTheme.mediumTextStyle(color: kTextGray),
        ),
      ],
    );
  }
}
