import 'package:easy_localization/easy_localization.dart';
import 'package:fluid_dialog/fluid_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/home_receipt_navigator_enum.dart';
import 'package:mts/core/enum/receipt_status_enum.dart';
import 'package:mts/core/enums/permission_enum.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/features/home_receipt/components/change_payment_type_dialogue.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';

class HomeReceiptOptionsDialogue extends ConsumerStatefulWidget {
  final ReceiptModel receiptModel;
  final ReceiptNotifier receiptNotifier;
  final Function(ReceiptModel) onUpdatePaymentMethod;

  const HomeReceiptOptionsDialogue({
    super.key,
    required this.receiptModel,
    required this.receiptNotifier,
    required this.onUpdatePaymentMethod,
  });

  @override
  ConsumerState<HomeReceiptOptionsDialogue> createState() =>
      _HomeReceiptOptionsDialogueState();
}

class _HomeReceiptOptionsDialogueState
    extends ConsumerState<HomeReceiptOptionsDialogue> {
  @override
  Widget build(BuildContext context) {
    final permissionNotifier = ref.read(permissionProvider.notifier);
    bool hasRefundPermission = permissionNotifier.hasPerformRefundPermission();
    double availableWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: availableWidth / 4.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.receiptModel.receiptStatus == ReceiptStatusEnum.normal
                ? ListTile(
                  title: InkWell(
                    onTap: () async {
                      // close the dialogue
                      DialogNavigator.of(context).close();

                      if (!hasRefundPermission) {
                        await DialogUtils.showPinDialog(
                          context,
                          permission: PermissionEnum.PERFORM_REFUND,
                          onSuccess: () {
                            if (widget.receiptModel.id != null) {
                              widget.receiptNotifier.setPageIndex(
                                HomeReceiptNavigatorEnum.receiptRefund,
                              );

                              final currReceiptItem =
                                  widget
                                      .receiptNotifier
                                      .getInitialListReceiptItems;
                              widget.receiptNotifier.setReceiptItems(
                                currReceiptItem,
                              );
                            }
                          },
                          onError: (error) {
                            ThemeSnackBar.showSnackBar(context, error);
                            return;
                          },
                        );
                      }

                      if (hasRefundPermission) {
                        if (widget.receiptModel.id != null) {
                          widget.receiptNotifier.setPageIndex(
                            HomeReceiptNavigatorEnum.receiptRefund,
                          );

                          final currReceiptItem =
                              widget.receiptNotifier.getInitialListReceiptItems;
                          widget.receiptNotifier.setReceiptItems(
                            currReceiptItem,
                          );
                        }
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_rounded,
                          color: kBlackColor,
                        ),
                        const SizedBox(width: 10),
                        Text('refund'.tr(), style: AppTheme.normalTextStyle()),
                      ],
                    ),
                  ),
                )
                : const SizedBox.shrink(),
            // else for hasRefundPermission
            ListTile(
              title: InkWell(
                onTap: () {
                  DialogNavigator.of(context).push(
                    FluidDialogPage(
                      alignment: Alignment.center,
                      builder: (context) {
                        return ChangePaymentTypeDialogue(
                          receiptModel: widget.receiptModel,
                          onUpdatePaymentMethod: widget.onUpdatePaymentMethod,
                        );
                      },
                    ),
                  );
                },
                child: Row(
                  children: [
                    const Icon(Icons.currency_exchange, color: kBlackColor),
                    const SizedBox(width: 10),
                    Text(
                      'changePaymentType'.tr(),
                      style: AppTheme.normalTextStyle(),
                    ),
                  ],
                ),
              ),
            ),

            // ListTile(
            //   title: InkWell(
            //     onTap: () {
            //       DialogNavigator.of(context).push(
            //         FluidDialogPage(
            //           alignment: Alignment.center,
            //           builder: (context) {
            //             return const SendEmailDialogue(
            //               isFluidDialogue: true,
            //             );
            //           },
            //         ),
            //       );
            //     },
            //     child: Row(
            //       children: [
            //         const Icon(
            //           Icons.email,
            //           color: kBlackColor,
            //         ),
            //         const SizedBox(width: 10),
            //         Text(
            //           'sendReceiptToEmail'.tr(),
            //           style: AppTheme.normalTextStyle(),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            // ListTile(
            //   title: OutlinedButton.icon(
            //     style: getOutlineButtonStyle(kTextGray, FontWeight.normal),
            //     icon: const Icon(Icons.email),
            //     label: Text('sendReceiptToEmail'.tr()),
            //     onPressed: () {
            //       // showDialog(
            //       //     context: context,
            //       //     barrierDismissible: true,
            //       //     builder: (context) {
            //       //       return const SendEmailDialogue();
            //       //     });
            //     },
            //   ),
            //   //  leading: const Icon(Icons.info_outline),
            //   iconColor: Theme.of(context).colorScheme.onSurface,
            //   onTap: () {},
            // ),
          ],
        ),
      ),
    );
  }
}

class TestDialog extends StatelessWidget {
  const TestDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Hello there',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          TextButton(
            onPressed:
                () => DialogNavigator.of(context).push(
                  FluidDialogPage(
                    builder: (context) => const SecondDialogPage(),
                  ),
                ),
            child: const Text('Go to next page'),
          ),
        ],
      ),
    );
  }
}

class SecondDialogPage extends StatelessWidget {
  const SecondDialogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'And a bigger dialog',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Text('placeholder'),
            TextButton(
              onPressed: () => DialogNavigator.of(context).pop(),
              child: const Text('Go back'),
            ),
            TextButton(
              onPressed: () => DialogNavigator.of(context).close(),
              child: const Text('Close the dialog'),
            ),
          ],
        ),
      ),
    );
  }
}
