import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/presentation/common/widgets/button_primary.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/home_receipt/components/order_option_dialogue.dart';
import 'package:mts/presentation/features/home_receipt/components/payment_type_dialogue.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';
import 'package:mts/providers/receipt/receipt_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeReceiptFilterDialogue extends ConsumerStatefulWidget {
  const HomeReceiptFilterDialogue({super.key});

  @override
  ConsumerState<HomeReceiptFilterDialogue> createState() =>
      _HomeReceiptFilterDialogueState();
}

class _HomeReceiptFilterDialogueState
    extends ConsumerState<HomeReceiptFilterDialogue> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final notifier = ref.read(receiptProvider.notifier);
      notifier.resetSelectedDateRange();
      notifier.resetPreviousPaymentType();
      notifier.resetPreviousOrderOption();
    });
  }

  // Start with the dialog aligned to the center
  double _left = 0.5; // Center horizontally (as a fraction of screen width)
  final double _top = 0.1; // Start at 30% from the top
  bool isShowPaymentTypeDialogue = false;
  bool isShowOrderOptionsDialogue = false;

  @override
  Widget build(BuildContext context) {
    final receiptState = ref.watch(receiptProvider);
    final notifier = ref.read(receiptProvider.notifier);

    double availableHeight = MediaQuery.of(context).size.height;
    double availableWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
            notifier.setReceiptDialogueNavigator(DialogNavigatorEnum.reset);

            // if (!receiptState.isApplyFilter) {
            //   if (receiptState.lastSelectedDateRange != null) {
            notifier.dateFormatting(receiptState.lastSelectedDateRange);
            notifier.setSelectedPaymentType(
              receiptState.previousPaymentType,
              receiptState.previousPaymentTypeIndex,
            );
            notifier.setSelectedOrderOption(
              receiptState.previousOrderOption,
              receiptState.previousOrderOptionIndex,
            );
            //   }
            // }
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
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: availableHeight / 1.5,
                  maxWidth: availableWidth / 2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Space(10),
                    AppBar(
                      elevation: 0,
                      backgroundColor: white,
                      title: Row(
                        children: [
                          Text('filter'.tr(), style: AppTheme.h1TextStyle()),
                          const Expanded(flex: 2, child: SizedBox()),
                          Expanded(
                            flex: 1,
                            child: ButtonPrimary(
                              text: 'applyFilter'.tr(),
                              icon: FontAwesomeIcons.fileCircleCheck,
                              onPressed: () async {
                                notifier.applyLastSelectedDateRange();
                                notifier.applyPreviousPaymentType();
                                notifier.applyPreviousOrderOption();

                                notifier.setSelectedReceiptIndex(null);
                                notifier.clearTempReceiptId();
                                ref
                                    .read(myNavigatorProvider.notifier)
                                    .setSelectedTab(0, '');
                                notifier.refreshPagingController();

                                Navigator.of(context).pop();
                                notifier.setReceiptDialogueNavigator(
                                  DialogNavigatorEnum.reset,
                                );

                                //  await showPaymenTypeDialogue();
                              },
                            ),
                          ),
                        ],
                      ),
                      // close button
                      leading: IconButton(
                        icon: const Icon(Icons.close, color: canvasColor),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          notifier.setReceiptDialogueNavigator(
                            DialogNavigatorEnum.reset,
                          );
                          notifier.dateFormatting(
                            receiptState.lastSelectedDateRange,
                          );
                          notifier.setSelectedPaymentType(
                            receiptState.previousPaymentType,
                            receiptState.previousPaymentTypeIndex,
                          );
                          notifier.setSelectedOrderOption(
                            receiptState.previousOrderOption,
                            receiptState.previousOrderOptionIndex,
                          );
                        },
                      ),
                    ),
                    dateRange(receiptState),
                    paymentType(receiptState),
                    orderOption(receiptState),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isShowPaymentTypeDialogue)
          Positioned(
            left:
                (_left * availableWidth - (availableWidth / 4)) +
                (availableWidth / 2) +
                16, // Position next to the first dialog with spacing
            top: _top * availableHeight,
            child: Material(
              color: Colors.transparent,
              child: PaymentTypeDialogue(
                onCallback: () {
                  setState(() {});
                },
                onClose: () async {
                  isShowPaymentTypeDialogue = false;
                  setState(() {});
                  await Future.delayed(const Duration(milliseconds: 100));
                  _left = 0.5;

                  setState(() {});
                },
              ),
            ),
          ),
        if (isShowOrderOptionsDialogue)
          Positioned(
            left:
                (_left * availableWidth - (availableWidth / 4)) +
                (availableWidth / 2) +
                16, // Position next to the first dialog with spacing
            top: _top * availableHeight,
            child: Material(
              color: Colors.transparent,
              child: OrderOptionDialogue(
                onCallback: () {
                  setState(() {});
                },
                onClose: () async {
                  isShowOrderOptionsDialogue = false;
                  setState(() {});
                  await Future.delayed(const Duration(milliseconds: 100));
                  _left = 0.5;

                  setState(() {});
                },
              ),
            ),
          ),
      ],
    );
  }

  Future<void> showPaymentTypeDialogue() async {
    prints('move to left');

    _left = 0.27; // Move closer to the left edge
    setState(() {}); // Update the UI
    await Future.delayed(const Duration(milliseconds: 500));
    // Show the new dialog on the right
    if (isShowOrderOptionsDialogue) {
      // close the order option dialogue
      isShowOrderOptionsDialogue = false;
    }
    isShowPaymentTypeDialogue = true;

    setState(() {});
  }

  Future<void> showOrderOptionDialogue() async {
    _left = 0.27; // Move closer to the left edge
    setState(() {}); // Update the UI
    await Future.delayed(const Duration(milliseconds: 500));
    // Show the new dialog on the right
    if (isShowPaymentTypeDialogue) {
      // close the payment type dialogue
      isShowPaymentTypeDialogue = false;
    }
    isShowOrderOptionsDialogue = true;

    setState(() {});
  }

  Widget dateRange(ReceiptState receiptState) {
    bool isHaveDateRange = receiptState.formattedDateRange != '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Space(10),
          Text(
            'dateRange'.tr(),
            style: AppTheme.normalTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Space(10),
          Row(
            children: [
              Expanded(
                child: ScaleTap(
                  onPressed: () async {
                    await DialogUtils.showCustomDatePicker(
                      context,
                      ref.read(receiptProvider.notifier),
                      onSelectDate: () async {
                        setState(() {});
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kWhiteColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isHaveDateRange ? kPrimaryColor : kTextGray,
                        width: isHaveDateRange ? 2 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(FontAwesomeIcons.calendar),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isHaveDateRange
                                ? receiptState.formattedDateRange
                                : 'selectDateRange'.tr(),
                            style: AppTheme.normalTextStyle(
                              color: isHaveDateRange ? kBlackColor : kTextGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: isHaveDateRange ? 5 : 0),
              isHaveDateRange
                  ? IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40, // Minimum width of the clickable area
                      minHeight: 40, // Minimum height of the clickable area
                    ),
                    splashRadius: 20,
                    onPressed: () {
                      ref
                          .read(receiptProvider.notifier)
                          .setSelectedDateRange(null);
                      setState(() {});
                    },
                    icon: const Icon(FontAwesomeIcons.xmark),
                  )
                  : const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }

  Widget paymentType(ReceiptState receiptState) {
    bool isHavePaymentType = receiptState.selectedPaymentType != null;
    prints(isHavePaymentType);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Space(30),
          Text(
            'paymentType'.tr(),
            style: AppTheme.normalTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Space(10),
          Row(
            children: [
              Expanded(
                child: ScaleTap(
                  onPressed: () async {
                    await showPaymentTypeDialogue();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kWhiteColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isHavePaymentType ? kPrimaryColor : kTextGray,
                        width: isHavePaymentType ? 2 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(FontAwesomeIcons.solidCreditCard),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isHavePaymentType
                                ? receiptState.selectedPaymentType!
                                : 'selectPaymentType'.tr(),
                            style: AppTheme.normalTextStyle(
                              color:
                                  isHavePaymentType ? kBlackColor : kTextGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: isHavePaymentType ? 5 : 0),
              isHavePaymentType
                  ? IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40, // Minimum width of the clickable area
                      minHeight: 40, // Minimum height of the clickable area
                    ),
                    splashRadius: 20,
                    onPressed: () {
                      ref
                          .read(receiptProvider.notifier)
                          .setTempPaymentType(null, null);

                      setState(() {});
                    },
                    icon: const Icon(FontAwesomeIcons.xmark),
                  )
                  : const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }

  Widget orderOption(ReceiptState receiptState) {
    bool isHaveOrderOption = receiptState.selectedOrderOption != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Space(30),
          Text(
            'orderOption'.tr(),
            style: AppTheme.normalTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Space(10),
          Row(
            children: [
              Expanded(
                child: ScaleTap(
                  onPressed: () async {
                    await showOrderOptionDialogue();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kWhiteColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isHaveOrderOption ? kPrimaryColor : kTextGray,
                        width: isHaveOrderOption ? 2 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(FontAwesomeIcons.truckFast),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isHaveOrderOption
                                ? receiptState.selectedOrderOption!
                                : 'selectOrderOption'.tr(),
                            style: AppTheme.normalTextStyle(
                              color:
                                  isHaveOrderOption ? kBlackColor : kTextGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: isHaveOrderOption ? 5 : 0),
              isHaveOrderOption
                  ? IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40, // Minimum width of the clickable area
                      minHeight: 40, // Minimum height of the clickable area
                    ),
                    splashRadius: 20,
                    onPressed: () {
                      ref
                          .read(receiptProvider.notifier)
                          .setTempOrderOption(null, null);

                      setState(() {});
                    },
                    icon: const Icon(FontAwesomeIcons.xmark),
                  )
                  : const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }
}
