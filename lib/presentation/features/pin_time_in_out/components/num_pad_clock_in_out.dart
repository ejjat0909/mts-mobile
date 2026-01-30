import 'package:analog_clock/analog_clock.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/core/utils/network_utils.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/dialogs/loading_dialogue.dart';
import 'package:mts/presentation/common/widgets/button_bottom.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/features/pin_lock/components/number_button.dart';
import 'package:mts/presentation/features/pin_lock/components/pin_input_field.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/timecard/timecard_providers.dart';

class NumPadClockInOut extends ConsumerStatefulWidget {
  final int currentIndex;
  final bool? isFromHome;

  const NumPadClockInOut({
    super.key,
    required this.currentIndex,
    this.isFromHome = false,
  });

  @override
  ConsumerState<NumPadClockInOut> createState() => _NumPadClockInOutState();
}

class _NumPadClockInOutState extends ConsumerState<NumPadClockInOut> {
  final TextEditingController pinController = TextEditingController();
  bool isPinValid = false;

  @override
  Widget build(BuildContext context) {
    final featureCompNotifier = ref.watch(featureCompanyProvider.notifier);
    final isActiveFeature = featureCompNotifier.isTimeClockActive();
    double screenWidth = MediaQuery.of(context).size.width;
    final dialogNav = ref.watch(myNavigatorProvider.notifier);

    final currentIndex = dialogNav.pageIndex;

    return Container(
      //height: 800.h,
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth / 3.5,
        vertical: 0.h,
      ),
      padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            offset: const Offset(8, 20),
            blurRadius: 25,
            color: Colors.black.withValues(alpha: 0.02),
          ),
          BoxShadow(
            offset: const Offset(0, 10),
            blurRadius: 10,
            color: Colors.black.withValues(alpha: 0.02),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // CLOCK
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      // to make the arrow at the left
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        backButton(dialogNav, currentIndex),
                        SizedBox(height: 39.h),
                        clockOutButton(context, isActiveFeature),
                      ],
                    ),
                  ),
                  analogClock(),
                  clockInButton(context, isActiveFeature),
                ],
              ),
              SizedBox(height: 25.h),

              PinInputField(
                pinController,
                isFromMainLoginPinPage: false,
                isPinValid: (isValid) {
                  if (kDebugMode) {
                    prints('IS VALID PIN: $isValid');
                  }

                  isPinValid = isValid;
                  setState(() {});
                },
              ),

              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: NumberButton(
                      number: 1,
                      press: () {
                        setNumber('1');
                      },
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 1,
                    child: NumberButton(
                      number: 2,
                      press: () {
                        setNumber('2');
                      },
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 1,
                    child: NumberButton(
                      number: 3,
                      press: () {
                        setNumber('3');
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: NumberButton(
                      number: 4,
                      press: () {
                        setNumber('4');
                      },
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 1,
                    child: NumberButton(
                      number: 5,
                      press: () {
                        setNumber('5');
                      },
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 1,
                    child: NumberButton(
                      number: 6,
                      press: () {
                        setNumber('6');
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: NumberButton(
                      number: 7,
                      press: () {
                        setNumber('7');
                      },
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 1,
                    child: NumberButton(
                      number: 8,
                      press: () {
                        setNumber('8');
                      },
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 1,
                    child: NumberButton(
                      number: 9,
                      press: () {
                        setNumber('9');
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: NumberButton(
                      number: 0,
                      press: () {
                        setNumber('0');
                      },
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 1,
                    child: NumberButton(
                      press: () {
                        if (pinController.text.isNotEmpty) {
                          pinController.text = pinController.text.substring(
                            0,
                            pinController.text.length - 1,
                          );
                          pinController.selection = TextSelection.fromPosition(
                            TextPosition(offset: pinController.text.length - 1),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconButton backButton(MyNavigatorNotifier dialogNav, int currentIndex) {
    return IconButton(
      onPressed: () {
        dialogNav.setPageIndex(currentIndex - 1, 'pinLock'.tr());
      },
      icon: Icon(FontAwesomeIcons.arrowLeft, color: canvasColor),
    );
  }

  Expanded clockInButton(BuildContext context, bool isFeatureActive) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(left: 30.w),
        child: ButtonBottom(
          press: () async {
            if (!isFeatureActive) {
              DialogUtils.showFeatureNotAvailable(context);
              return;
            }
            if (isPinValid) {
              await ref
                  .read(timecardProvider.notifier)
                  .staffClockIn(
                    onSuccess: () {
                      ref
                          .read(myNavigatorProvider.notifier)
                          .setPageIndex(
                            widget.currentIndex + 1,
                            'clockIn'.tr(),
                          );
                    },
                    onError: (message) {
                      CustomDialog.show(
                        context,
                        dialogType: DialogType.danger,
                        icon: Icons.error_outline,
                        title: 'somethingWrong'.tr(),
                        description: message,
                        btnOkText: 'ok'.tr(),
                        btnOkOnPress: () {
                          NavigationUtils.pop(context);
                        },
                      );
                    },
                  );
            } else {
              CustomDialog.show(
                context,
                icon: Icons.error_outline,
                title: 'invalidPin'.tr(),
                description: 'pleaseTryAgain'.tr(),
                btnOkText: 'ok'.tr(),
                btnOkOnPress: () {
                  NavigationUtils.pop(context);
                },
              );
            }
          },
          'clockIn'.tr(),
        ),
      ),
    );
  }

  AnalogClock analogClock() {
    return AnalogClock(
      decoration: BoxDecoration(
        border: Border.all(width: 1.0, color: canvasColor),
        color: Colors.transparent,
        shape: BoxShape.circle,
      ),
      width: 120,
      height: 120,
      isLive: true,
      hourHandColor: Colors.black,
      minuteHandColor: canvasColor,
      secondHandColor: kPrimaryColor,
      tickColor: kPrimaryColor,
      showSecondHand: true,
      numberColor: Colors.black87,
      showNumbers: true,
      showAllNumbers: false,
      textScaleFactor: 1.4,
      showTicks: false,
      showDigitalClock: true,
      datetime: DateTime.now(),
    );
  }

  Widget clockOutButton(BuildContext context, bool isFeatureActive) {
    return Padding(
      padding: EdgeInsets.only(right: 30.w),
      child: ButtonTertiary(
        onPressed: () async {
          if (!isFeatureActive) {
            DialogUtils.showFeatureNotAvailable(context);
            return;
          }
          if (isPinValid) {
            if (await NetworkUtils.hasInternetConnection()) {
              LoadingDialog.show(context);
              await ref
                  .read(timecardProvider.notifier)
                  .staffClockOut(
                    onSuccess: () {
                      // close loading dialogue
                      LoadingDialog.hide(context);
                      ref
                          .read(myNavigatorProvider.notifier)
                          .setPageIndex(
                            widget.currentIndex + 2,
                            'clockOut'.tr(),
                          );
                    },
                    onError: (message) {
                      // close loading dialogue
                      LoadingDialog.hide(context);
                      CustomDialog.show(
                        context,
                        dialogType: DialogType.danger,
                        icon: FontAwesomeIcons.solidIdBadge,
                        title: 'fail'.tr(),
                        description: message,
                        btnOkText: 'ok'.tr(),
                        btnOkOnPress: () {
                          NavigationUtils.pop(context);
                        },
                      );
                    },
                  );
            } else {
              CustomDialog.show(
                context,
                icon: Icons.error_outline,
                title: 'noInternet'.tr(),
                description: 'pleaseTryAgain'.tr(),
                btnOkText: 'ok'.tr(),
                btnOkOnPress: () {
                  NavigationUtils.pop(context);
                },
              );
            }
          } else {
            CustomDialog.show(
              context,
              icon: Icons.error_outline,
              title: 'invalidPin'.tr(),
              description: 'pleaseTryAgain'.tr(),
              btnOkText: 'ok'.tr(),
              btnOkOnPress: () {
                NavigationUtils.pop(context);
              },
            );
          }
        },
        text: 'clockOut'.tr(),
      ),
    );
  }

  void setNumber(String number) {
    setState(() {
      if (pinController.text.length < 6) {
        pinController.text += number;
      }
    });
  }
}
