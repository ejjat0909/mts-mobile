import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/core/utils/network_utils.dart';
import 'package:mts/core/utils/string_utils.dart';
import 'package:mts/data/models/user/user_response_model.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/providers/staff/staff_providers.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class PinInputFieldDialogue extends ConsumerStatefulWidget {
  final TextEditingController pinController;
  final Function(bool) isPinValid;
  final String permission;
  const PinInputFieldDialogue({
    super.key,
    required this.pinController,
    required this.isPinValid,
    required this.permission,
  });

  @override
  ConsumerState<PinInputFieldDialogue> createState() =>
      _PinInputFieldDialogueState();
}

class _PinInputFieldDialogueState extends ConsumerState<PinInputFieldDialogue> {
  late StreamController<ErrorAnimationType> errorController;

  bool hasError = false;
  bool isValidPin = false;
  String errorMessage = '';
  UserResponseModel? responseModel;

  @override
  void initState() {
    errorController = StreamController<ErrorAnimationType>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PinCodeTextField(
          appContext: context,
          pastedTextStyle: const TextStyle(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
          errorAnimationController: errorController,
          controller: widget.pinController,
          length: 6,
          obscureText: true,
          obscuringCharacter: '*',
          animationType: AnimationType.scale,
          // validator: (v) {
          //   if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) {
          //     return translations
          //         .text("pages.register.validator.otp_invalid");
          //   } else {
          //     return null;
          //   }
          // },
          pinTheme: PinTheme(
            activeColor: isValidPin ? kSuccessColor : kPrimaryColor,
            errorBorderColor: kTextRed,
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(5),
            borderWidth: 1,
            fieldHeight: 60,
            fieldWidth: 50,
            // color for each field
            activeFillColor: Colors.white,
            // color for empty field
            inactiveFillColor: Colors.white,
            // color for border empty field
            inactiveColor: kDisabledText,
            selectedFillColor: Colors.white,
          ),

          cursorColor: Colors.black,
          animationDuration: const Duration(milliseconds: 300),
          textStyle: const TextStyle(fontSize: 20, height: 1.6),
          backgroundColor: Colors.transparent,
          enableActiveFill: true,
          // errorAnimationController: errorController,
          // controller: textEditingController,
          keyboardType: TextInputType.none,
          boxShadows: const [
            // BoxShadow(
            //   offset: Offset(0, 0),
            //   blurRadius: 2,
            //   spreadRadius: 0,
            //   color: Colors.black.withValues(alpha: 0.1),
            // )
          ],

          onCompleted: (pin) async {
            /// [check pin exist or not in staff table]
            /// [if the pin exist, then use the userId from table staff to find user from user table]
            /// [if found that user, then check the pos permission has this permission or not]

            if (!await NetworkUtils.hasInternetConnection()) {
              hasError = true;
              errorMessage = 'noInternet'.tr();
              setState(() {});
              widget.isPinValid(false);
              await Future.delayed(const Duration(seconds: 1));
              widget.pinController.clear();
              return;
            } else {
              prints("Have Internet");
            }

            // LoadingDialog.show(context);

            await ref
                .read(staffProvider.notifier)
                .unlockPermission(
                  permission: widget.permission,
                  pin: pin,
                  onSuccess: () {
                    // LoadingDialog.hide(context);
                    isValidPin = true;
                    widget.isPinValid(true);
                    NavigationUtils.pop(context);
                  },
                  onError: (errMsg) async {
                    // LoadingDialog.hide(context);
                    isValidPin = false;
                    hasError = true;
                    errorMessage = errMsg;
                    errorController.add(ErrorAnimationType.shake);
                    widget.isPinValid(false);
                    setState(() {});
                    await Future.delayed(const Duration(seconds: 1));
                    widget.pinController.clear();
                    return;
                  },
                );

            // LoadingDialog.show(context);
            // UserModel userModel = UserModel();

            // if (await NetworkUtils.hasInternetConnection()) {
            //   userModel = await _staffFacade.isStaffPinValid(pin, (message) {
            //     errorMessage = message;
            //     setState(() {});
            //   });
            // } else {
            //   userModel = await _staffFacade.isStaffPinValid(pin, (message) {
            //     errorMessage = message;
            //     setState(() {});
            //   }, hasInternet: false);
            // }

            // LoadingDialog.hide(context);

            // if (userModel.id != null) {
            //   // PIN CORRECT
            //
            //   _userFacade.setGetIt(userModel);
            //   _permissionNotifier.assignStaffPermission(userModel, false);
            //   StaffModel? staffModel = await _staffFacade.getStaffModelByUserId(
            //     userModel.id!.toString(),
            //   );

            //   isValidPin = true;
            //   widget.isPinValid(true);
            //   if (mounted) {
            //     // get all data from local db because want to set all the data to notifier
            //     await _generalFacade.getAllDataFromLocalDb(
            //       null, // because no need to download images

            //       (loading) {},
            //       isDownloadData: (isDownloading) {
            //         if (isDownloading) {
            //           //show loading
            //           LoadingDialog.show(context);
            //         } else {
            //           LoadingDialog.hide(context);
            //         }
            //       },
            //       needDownloadImages: false,
            //     );
            //   }

            //   bool isOpenShift = await _shiftFacade.hasShift();
            //   ShiftModel shiftModel = await _shiftFacade.getLatestShift();
            //   if (isOpenShift) {
            //     prints('OPEN SHIFTTTT');

            //     final deviceModel = await _deviceFacade.getLatestDeviceModel();

            //     // await generalFacade.subscribePusher();

            //     // update staff model to assign current shift id
            //     await _staffFacade.assignCurrentShift(shiftModel.id ?? '');

            //     // update device
            //     if (deviceModel.id != null) {
            //       PosDeviceModel updatedDeviceModel = deviceModel.copyWith(
            //         isActive: true,
            //       );
            //       await _deviceFacade.update(updatedDeviceModel);
            //     }
            //     context.read<ShiftNotifier>().setOpenShift();
            //   } else {
            //     LogUtils.log('close shift');
            //     context.read<ShiftNotifier>().setCloseShift();
            //   }

            //   // setState(() {});
            // } else {
            //   // WRONG PIN
            //   if (errorMessage.isNotEmpty) {
            //     showErrorDialogueFromResponse();
            //   }

            //   if (await Vibration.hasVibrator()) {
            //     Vibration.vibrate(preset: VibrationPreset.dramaticNotification);
            //   }
            //   //Failed to verified
            //   hasError = true;
            //   isValidPin = false;

            //   setState(() {});
            //   //set error
            //   errorController.add(ErrorAnimationType.shake);
            //   widget.isPinValid(false);

            //   await Future.delayed(const Duration(seconds: 1));
            //   widget.pinController.clear();
            // }
            //}
          },
          onChanged: (value) async {
            // if (value.length == 6) {
            //   prints("sama dengan 6");
            //   String? token = await _secureStorage.read(
            //     key: 'staff_access_token',
            //   );
            //   if (token.isNotEmpty == true) {
            //     await _secureStorage.delete(key: 'staff_access_token');
            //   }
            // }
            // setState(() {
            //   hasError = false;
            //   isValidPin = false;
            // });
          },
          beforeTextPaste: (text) {
            if (text != null &&
                text.trim().length == 6 &&
                StringUtils.isNumeric(text)) {
              return true;
            }
            return false;
            //if you return true then it will show the paste confirmation dialog. Otherwise if false, then nothing will happen.
            //but you can show anything you want here, like your pop up saying wrong paste format or etc
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Text(
            hasError
                ? (errorMessage.isNotEmpty ? errorMessage : 'invalidPin'.tr())
                : '',
            style: textStyleNormal(color: kTextRed, fontSize: 12),
          ),
        ),
      ],
    );
  }

  void showErrorDialogueFromResponse() {
    if (mounted) {
      CustomDialog.show(
        context,
        title: 'error'.tr(),
        description: errorMessage,
        icon: Icons.error_outline_rounded,
        btnOkText: 'ok'.tr(),
        btnOkOnPress: () => NavigationUtils.pop(context),
      );
    }
  }
}
