import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/features/pin_lock/components/number_button.dart';
import 'package:mts/presentation/features/pin_lock/components/pin_input_field.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/pending_changes/pending_changes_providers.dart';
import 'package:sqlite_viewer2/sqlite_viewer.dart';

class NumPad extends ConsumerStatefulWidget {
  final int currentIndex;

  const NumPad({super.key, required this.currentIndex});

  @override
  ConsumerState<NumPad> createState() => _NumPadState();
}

class _NumPadState extends ConsumerState<NumPad> {
  final TextEditingController pinController = TextEditingController();
  bool isPinValid = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    final featureCompNotifier = ref.watch(featureCompanyProvider.notifier);
    final isFeatureActive = featureCompNotifier.isTimeClockActive();
    double screenWidth = MediaQuery.of(context).size.width;

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(flex: 1, child: SizedBox()),
                // Flexible(
                //   child: Padding(
                //     padding: EdgeInsets.only(left: 30.w),
                //     child: ButtonTertiary(
                //       icon: FontAwesomeIcons.clock,
                //       onPressed: () {
                //         Navigator.push(
                //             context,
                //             MaterialPageRoute(
                //                 builder: (_) => const DatabaseList()));
                //       },
                //       text: "DB LIST",
                //     ),
                //   ),
                // ),
                Container(
                  width: 130,
                  height: 130,
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
                kDebugMode
                    ? Flexible(
                      child: Column(
                        children: [
                          isFeatureActive
                              ? ButtonTertiary(
                                icon: FontAwesomeIcons.clock,
                                onPressed: () {
                                  if (!isFeatureActive) {
                                    DialogUtils.showFeatureNotAvailable(
                                      context,
                                    );
                                    return;
                                  }
                                  ref
                                      .read(myNavigatorProvider.notifier)
                                      .setPageIndex(
                                        widget.currentIndex + 1,
                                        'timeInOut'.tr(),
                                      );
                                },
                                text: 'timeClock'.tr(),
                              )
                              : SizedBox.shrink(),
                          ButtonTertiary(
                            icon: FontAwesomeIcons.clock,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DatabaseList(),
                                ),
                              );
                            },
                            text: 'DB LIST',
                          ),
                          ButtonTertiary(
                            icon: FontAwesomeIcons.clock,
                            onPressed: () async {
                              await handleDeletePendingChanges();
                            },
                            text: 'DELETE PENDING',
                          ),
                        ],
                      ),
                    )
                    : Flexible(
                      child:
                          isFeatureActive
                              ? Padding(
                                padding: EdgeInsets.only(left: 30.w),
                                child: ButtonTertiary(
                                  icon: FontAwesomeIcons.clock,
                                  onPressed: () {
                                    if (!isFeatureActive) {
                                      DialogUtils.showFeatureNotAvailable(
                                        context,
                                      );
                                      return;
                                    }
                                    ref
                                        .read(myNavigatorProvider.notifier)
                                        .setPageIndex(
                                          widget.currentIndex + 1,
                                          'timeInOut'.tr(),
                                        );
                                  },
                                  text: 'timeClock'.tr(),
                                ),
                              )
                              : SizedBox.shrink(),
                    ),
              ],
            ),
            SizedBox(height: 25.h),
            PinInputField(
              pinController,
              isFromMainLoginPinPage: true,
              isPinValid: (isValid) {
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
    );
  }

  void setNumber(String number) {
    setState(() {
      if (pinController.text.length < 6) {
        pinController.text += number;
      }
    });
  }

  Future<void> handleDeletePendingChanges() async {
    final pendingChangesNotifier = ref.read(pendingChangesProvider.notifier);
    // final saleFacade = ServiceLocator.get<SaleFacade>();
    // final saleItemFacade = ServiceLocator.get<SaleItemFacade>();
    // final saleModifierFacade = ServiceLocator.get<SaleModifierFacade>();

    // final saleModifierOptionFacade =
    //     ServiceLocator.get<SaleModifierOptionFacade>();

    // final localPredefinedOrder =
    //     ServiceLocator.get<LocalPredefinedOrderRepository>();

    // await saleFacade.deleteAll();
    // await saleItemFacade.deleteAll();
    // await saleModifierFacade.deleteAll();
    // await saleModifierOptionFacade.deleteAll();
    // await localPredefinedOrder.unOccupiedAllNotCustom();
    // return;
    await pendingChangesNotifier.deleteAll();
  }
}
