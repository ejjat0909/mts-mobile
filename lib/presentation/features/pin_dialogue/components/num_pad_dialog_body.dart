import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/pin_dialogue/components/pin_input_field_dialogue.dart';
import 'package:mts/presentation/features/pin_lock/components/number_button.dart';

class NumPadDialogBody extends ConsumerStatefulWidget {
  final String permission;
  final Function() onSuccess;
  const NumPadDialogBody({
    super.key,
    required this.permission,
    required this.onSuccess,
  });

  @override
  ConsumerState<NumPadDialogBody> createState() => _NumPadDialogBodyState();
}

class _NumPadDialogBodyState extends ConsumerState<NumPadDialogBody> {
  final TextEditingController pinController = TextEditingController();
  bool isPinValid = false;
  String errorMessage = '';

  void setNumber(String number) {
    setState(() {
      if (pinController.text.length < 6) {
        pinController.text += number;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAppBarAndLogo(context),
        10.heightBox,
        Text('enterPinPermission'.tr(), style: textStyleMedium()),
        10.heightBox,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.w),
          child: Column(
            children: [
              PinInputFieldDialogue(
                permission: widget.permission,
                pinController: pinController,
                isPinValid: (isValid) {
                  isPinValid = isValid;
                  setState(() {});
                  if (isPinValid) {
                    widget.onSuccess();
                  }
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
      ],
    );
  }

  Widget _buildAppBarAndLogo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
              ),
            ],
          ),
          Positioned(
            top: -10,
            right: 10,
            child: ScaleTap(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: const Icon(Icons.close, color: canvasColor, size: 35),
              ),
              onPressed: () {
                NavigationUtils.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
