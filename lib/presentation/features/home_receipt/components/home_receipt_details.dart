import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluid_dialog/fluid_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/receipt_status_enum.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/default_response_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/dialogs/theme_spinner.dart';
import 'package:mts/presentation/common/widgets/no_permission.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/home_receipt/components/header.dart';
import 'package:mts/presentation/features/home_receipt/components/home_receipt_options_dialogue.dart';
import 'package:mts/presentation/features/home_receipt/components/initial_menu_list.dart';
import 'package:mts/presentation/features/home_receipt/components/send_email_dialogue.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:sks_ticket_view/sks_ticket_view.dart';

class HomeReceiptDetails extends ConsumerStatefulWidget {
  final ReceiptNotifier receiptNotifier;

  const HomeReceiptDetails({super.key, required this.receiptNotifier});

  @override
  ConsumerState<HomeReceiptDetails> createState() => _HomeReceiptDetailsState();
}

class _HomeReceiptDetailsState extends ConsumerState<HomeReceiptDetails> {
  PosDeviceModel deviceModel = GetIt.instance<PosDeviceModel>();

  UserModel userModel = GetIt.instance<UserModel>();
  bool _showLoading = false;
  bool _showSlowMessage = false;
  Timer? _loadingTimer;
  Timer? _slowMessageTimer;
  bool _timerStarted = false;

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _slowMessageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final permissionNotifier = ref.read(permissionProvider.notifier);
    bool hasPermissionViewReceipt =
        permissionNotifier.hasViewAllReceiptPermission();

    if (!hasPermissionViewReceipt) {
      return Expanded(flex: 5, child: NoPermission());
    }
    return FutureBuilder(
      future: ref
          .read(receiptProvider.notifier)
          .getDataForReceiptDetails(widget.receiptNotifier.getTempReceiptId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (!_timerStarted) {
            _timerStarted = true;
            _showLoading = false;
            _showSlowMessage = false;

            // Timer for showing spinner after 2 seconds
            _loadingTimer = Timer(Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _showLoading = true;
                });
              }
            });

            // Timer for showing message after 5 seconds
            _slowMessageTimer = Timer(Duration(seconds: 5), () {
              if (mounted) {
                setState(() {
                  _showSlowMessage = true;
                });
              }
            });
          }

          return Expanded(
            flex: 5,
            child:
                _showLoading
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ThemeSpinner.spinner(),
                        if (_showSlowMessage) ...[
                          10.heightBox,
                          Text(
                            'This may take a while...',
                            style: textStyleNormal(),
                          ),
                        ],
                      ],
                    )
                    : SizedBox(),
          );
        } else if (snapshot.hasError) {
          // Reset timer state
          _loadingTimer?.cancel();
          _slowMessageTimer?.cancel();
          _timerStarted = false;
          _showLoading = false;
          _showSlowMessage = false;
          return Expanded(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          // Reset timer state
          _loadingTimer?.cancel();
          _slowMessageTimer?.cancel();
          _timerStarted = false;
          _showLoading = false;
          _showSlowMessage = false;
          final Map<String, dynamic> data = snapshot.data!;
          ReceiptModel receiptModel = data['receiptModel'] as ReceiptModel;
          double totalTaxIncluded = data['totalTaxIncluded'] as double;
          prints("receiptModel.showUUID ${receiptModel.showUUID}");
          return Expanded(
            flex: 5,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: 20,
                      left: 150.w,
                      right: 150.w,
                    ),
                    child: Header(
                      price: FormatUtils.formatNumber(
                        'RM'.tr(
                          args: [
                            receiptModel.payableAmount?.toStringAsFixed(2) ??
                                '0.00',
                          ],
                        ),
                      ),
                      seller: receiptModel.staffName ?? 'Cashier',
                      status: getReceiptStatus(receiptModel),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: 20,
                      left: 150.w,
                      right: 150.w,
                    ),
                    child: SKSTicketView(
                      backgroundPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 0,
                      ),
                      backgroundColor: Colors.transparent,
                      triangleAxis: Axis.vertical,
                      borderRadius: 5,
                      drawTriangle: false,
                      circleDash: false,
                      drawArc: false,
                      dividerPadding: 5,
                      dividerColor: kBlackColor,
                      dashWidth: 3,
                      drawDivider: false,
                      dividerStrokeWidth: 0,
                      drawBorder: true,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Wrap(
                                    alignment: WrapAlignment.end,
                                    // crossAxisAlignment: WrapCrossAlignment.end,
                                    // runAlignment: WrapAlignment.end,
                                    spacing: 10,
                                    runSpacing: 0,
                                    children: [
                                      // receiptModel.receiptStatus ==
                                      //         ReceiptStatusEnum.normal
                                      //     ? OutlinedButton(
                                      //         onPressed: () async {
                                      //           // list receipt item that will be refunded
                                      //           if (snapshot.data!.id != null) {
                                      //             widget.receiptNotifier
                                      //                 .setPageIndex(
                                      //                     HomeReceiptNavigatorEnum
                                      //                         .RECEIPT_REFUND);
                                      //             final currReceiptItem = snapshot
                                      //                 .data!
                                      //                 .getReceiptItemsList();

                                      //             // prints(jsonEncode(currReceiptItem));
                                      //             widget.receiptNotifier
                                      //                 .setReceiptItems(
                                      //                     currReceiptItem);
                                      //           }
                                      //         },
                                      //         style: getOutlineButtonStyle(
                                      //             kTextGray, FontWeight.normal),
                                      //         child: (Text('refund'.tr())),
                                      //       )
                                      //     : const Spacer(),
                                      // const Spacer(),
                                      // send receipt only show if refund receipt is not null
                                      OutlinedButton.icon(
                                        style: AppTheme.getOutlineButtonStyle(
                                          kTextGray,
                                          FontWeight.normal,
                                        ),
                                        icon: const Icon(Icons.email),
                                        label: Text('sendReceiptToEmail'.tr()),
                                        onPressed: () {
                                          showDialogueSendEmail(context);
                                        },
                                      ),

                                      OutlinedButton.icon(
                                        style: AppTheme.getOutlineButtonStyle(
                                          kTextGray,
                                          FontWeight.normal,
                                        ),
                                        icon: const Icon(
                                          FontAwesomeIcons.print,
                                        ),
                                        label: Text('printReceipt'.tr()),
                                        onPressed: () async {
                                          await printReceipt(
                                            context,
                                            receiptModel,
                                          );
                                        },
                                      ),

                                      // option button only show when refund receipt is null
                                      if (receiptModel.refundedReceiptId ==
                                          null)
                                        OutlinedButton.icon(
                                          style: AppTheme.getOutlineButtonStyle(
                                            kTextGray,
                                            FontWeight.normal,
                                          ),
                                          icon: const Icon(
                                            FontAwesomeIcons.barsStaggered,
                                          ),
                                          label: Text('options'.tr()),
                                          onPressed: () async {
                                            handleShowOptionsDialogue(
                                              context,
                                              receiptModel,
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Space(15.h),
                            //Order information
                            receiptModel.refundedReceiptId != null
                                ? Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${'refunded'.tr()} ${receiptModel.refundedReceiptId!}",
                                      style: AppTheme.normalTextStyle(
                                        color: kTextRed,
                                      ),
                                    ),
                                  ],
                                )
                                : const SizedBox.shrink(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateTimeUtils.getDateTimeFormat(
                                    receiptModel.createdAt,
                                  ),
                                  style: AppTheme.mediumTextStyle(),
                                ),
                                Text(
                                  receiptModel.showUUID!.toString(),
                                  style: AppTheme.mediumTextStyle(),
                                ),
                              ],
                            ),

                            Space(15.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        child: Text(
                                          'customer'.tr(),
                                          style: AppTheme.normalTextStyle(
                                            color: kTextColor,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          ' : ${receiptModel.customerName ?? '-'}',
                                          style: AppTheme.normalTextStyle(
                                            color: kTextColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Text(
                                  '${'orderBy'.tr()} : ',
                                  style: AppTheme.normalTextStyle(
                                    color: kTextColor,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    receiptModel.orderedByStaffName ?? 'Waiter',
                                    style: AppTheme.normalTextStyle(
                                      color: kTextColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                              ],
                            ),
                            receiptModel.runningNumber != null
                                ? const SizedBox(height: 7)
                                : const SizedBox.shrink(),
                            receiptModel.runningNumber != null
                                ? Row(
                                  children: [
                                    Text(
                                      '${'orderNumber'.tr()} : ',
                                      style: AppTheme.normalTextStyle(
                                        color: kTextColor,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        receiptModel.runningNumber!,
                                        style: AppTheme.normalTextStyle(
                                          color: kTextColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.start,
                                      ),
                                    ),
                                  ],
                                )
                                : const SizedBox.shrink(),
                            receiptModel.remarks != null
                                ? const SizedBox(height: 7)
                                : const SizedBox.shrink(),
                            receiptModel.remarks != null
                                ? Row(
                                  children: [
                                    Text(
                                      '${'remarks'.tr()} : ',
                                      style: AppTheme.normalTextStyle(
                                        color: kTextColor,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        receiptModel.remarks!,
                                        style: AppTheme.normalTextStyle(
                                          color: kTextColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.start,
                                      ),
                                    ),
                                  ],
                                )
                                : const SizedBox.shrink(),

                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Text(
                                  'POS',
                                  style: AppTheme.normalTextStyle(
                                    color: kTextColor,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    ' : ${deviceModel.name ?? ""}',
                                    style: AppTheme.normalTextStyle(
                                      color: kTextColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Text(
                                  'paymentType'.tr(),
                                  style: AppTheme.normalTextStyle(
                                    color: kTextColor,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    receiptModel.isChangePaymentType!
                                        ? ' : ${receiptModel.paymentType ?? ""}'
                                        : ' : ${receiptModel.paymentType ?? ""}',
                                    style: AppTheme.normalTextStyle(
                                      color:
                                          receiptModel.isChangePaymentType!
                                              ? kTextRed
                                              : kTextColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Space(15.h),
                            Text(
                              receiptModel.orderOption ?? '',
                              textAlign: TextAlign.left,
                              style: AppTheme.mediumTextStyle(),
                            ),

                            //Items Table
                            const InitialMenuList(),
                            Space(15.h),
                            totalAdjustment(receiptModel),
                            Space(15.h),
                            discount(receiptModel),

                            Space(15.h),
                            subTotal(receiptModel),
                            Space(15.h),
                            taxes(receiptModel),
                            Space(15.h),
                            taxesIncluded(totalTaxIncluded),
                            receiptModel.paymentType!.toLowerCase().contains(
                                  'cash',
                                )
                                ? Column(
                                  children: [
                                    Space(15.h),
                                    roundingCash(receiptModel),
                                    const Space(10),
                                    cash(receiptModel),
                                    const Space(10),
                                    change(receiptModel),
                                  ],
                                )
                                : const SizedBox.shrink(),
                            const Space(10),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Space(10),
                ],
              ),
            ),
          );
        } else {
          return const Expanded(flex: 5, child: CircularProgressIndicator());
        }
      },
    );
  }

  Future<void> printReceipt(
    BuildContext context,
    ReceiptModel receiptModel,
  ) async {
    List<PrinterSettingModel> listPsm =
        await ref.read(printerSettingProvider.notifier).getListPrinterSetting();
    // just get that enable print receipt and bills
    // already do the filtering in the SalesDesignPrint
    // listPsm = listPsm.where((ps) => ps.printReceiptBills!).toList();
    await ref
        .read(receiptProvider.notifier)
        .handleOnPressPrintReceipt(
          receiptModel,
          listPsm: listPsm,
          ref: ref,
          onSuccess: () {},
          onError: (errorIps) {
            if (errorIps == '-1') {
              ThemeSnackBar.showSnackBar(context, 'noPrinterAvailable'.tr());
              // printerNotAvailableDialogue(
              //   context,
              //   'noPrinterAvailable'.tr(),
              //   'pleaseAddPrinterToPrint'.tr(),
              // );
              return;
            }
            DialogUtils.printerErrorDialogue(
              context,
              'connectionTimeout'.tr(),
              errorIps,
              null,
            );
            return;
          },
          isAutomaticPrint: false,
          isShouldOpenCashDrawer:
              false, // Reprint from receipt list should NOT open cash drawer
        );
  }

  void showDialogueSendEmail(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return SendEmailDialogue(
          isFluidDialogue: false,
          onSuccess: (response) {
            NavigationUtils.pop(context, response);
          },
          onError: (message) {
            NavigationUtils.pop(context, message);
          },
        );
      },
    ).then((result) {
      if (result is DefaultResponseModel) {
        // success
        CustomDialog.show(
          context,
          icon: FontAwesomeIcons.paperPlane,
          title: 'success'.tr(),
          description: result.message,
          btnOkText: 'ok'.tr(),
          btnOkOnPress: () => NavigationUtils.pop(context),
        );
      } else if (result is String) {
        // error
        CustomDialog.show(
          context,
          dialogType: DialogType.danger,
          icon: FontAwesomeIcons.circleExclamation,
          title: 'error'.tr(),
          description: result,
          btnOkText: 'ok'.tr(),
          btnOkOnPress: () => NavigationUtils.pop(context),
        );
      }
    });
  }

  void handleShowOptionsDialogue(
    BuildContext context,
    ReceiptModel receiptModel,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => FluidDialog(
            edgePadding: const EdgeInsets.all(0),
            rootPage: FluidDialogPage(
              alignment: Alignment.centerRight,
              builder:
                  (context) => HomeReceiptOptionsDialogue(
                    receiptModel: receiptModel,
                    receiptNotifier: widget.receiptNotifier,
                    onUpdatePaymentMethod: (newReceiptModel) {
                      DialogNavigator.of(context).close();
                      // refresh paging controller
                      widget.receiptNotifier.refreshPagingController();
                      setState(() {});
                    },
                  ),
            ),
          ),
    );
  }

  Row change(ReceiptModel receiptModel) {
    double change = receiptModel.cash! - receiptModel.payableAmount!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('change'.tr(), style: AppTheme.mediumTextStyle()),
        Text(
          FormatUtils.formatNumber('RM'.tr(args: [change.toStringAsFixed(2)])),
          style: AppTheme.mediumTextStyle(),
        ),
      ],
    );
  }

  Row cash(ReceiptModel receiptModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Cash', style: AppTheme.mediumTextStyle()),
        Text(
          FormatUtils.formatNumber(
            'RM'.tr(args: [receiptModel.cash!.toStringAsFixed(2)]),
          ),
          style: AppTheme.mediumTextStyle(),
        ),
      ],
    );
  }

  String getReceiptStatus(ReceiptModel model) {
    // prints(model.toJson());
    if (model.receiptStatus == ReceiptStatusEnum.cancelled) {
      return 'cancelled'.tr();
    } else if (model.receiptStatus == ReceiptStatusEnum.refunded) {
      return 'refunded'.tr();
    } else if (model.receiptStatus == ReceiptStatusEnum.normal) {
      return 'paid'.tr();
    }
    return 'PAID';
  }

  Row subTotal(ReceiptModel receiptModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('subtotal'.tr(), style: AppTheme.mediumTextStyle()),
        Text(
          FormatUtils.formatNumber(
            'RM'.tr(args: [(receiptModel.netSale!.toStringAsFixed(2))]),
          ),
          style: AppTheme.mediumTextStyle(),
        ),
      ],
    );
  }

  Row roundingCash(ReceiptModel receiptModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('rounding'.tr(), style: AppTheme.mediumTextStyle()),
        Text(
          FormatUtils.formatNumber(
            'RM'.tr(
              args: [(receiptModel.totalCashRounding!.toStringAsFixed(2))],
            ),
          ),
          style: AppTheme.mediumTextStyle(),
        ),
      ],
    );
  }

  Row totalAdjustment(ReceiptModel receiptModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('adjustment'.tr(), style: AppTheme.mediumTextStyle()),
        Text(
          "-${FormatUtils.formatNumber('RM'.tr(args: [(receiptModel.adjustedPrice!.abs().toStringAsFixed(2))]))}",
          style: AppTheme.mediumTextStyle(),
        ),
      ],
    );
  }

  Row discount(ReceiptModel receiptModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('discount'.tr(), style: AppTheme.mediumTextStyle()),
        Text(
          '-${FormatUtils.formatNumber("RM".tr(args: [(receiptModel.totalDiscount!.toStringAsFixed(2))]))}',
          style: AppTheme.mediumTextStyle(),
        ),
      ],
    );
  }

  Row taxes(ReceiptModel receiptModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('tax'.tr(), style: AppTheme.mediumTextStyle()),
        Text(
          FormatUtils.formatNumber(
            'RM'.tr(args: [(receiptModel.totalTaxes!.toStringAsFixed(2))]),
          ),
          style: AppTheme.mediumTextStyle(),
        ),
      ],
    );
  }

  Row taxesIncluded(double totalTaxIncluded) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("${'tax'.tr()} (Included)", style: AppTheme.mediumTextStyle()),
        Text(
          FormatUtils.formatNumber(
            'RM'.tr(args: [(totalTaxIncluded.toStringAsFixed(2))]),
          ),
          style: AppTheme.mediumTextStyle(),
        ),
      ],
    );
  }
}
