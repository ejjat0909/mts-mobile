import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/core/utils/network_utils.dart';
import 'package:mts/core/utils/string_utils.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/core/sync/app_sync_service.dart';
import 'package:mts/core/sync/sync_reason.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/dialogs/loading_dialogue.dart';
import 'package:mts/providers/device/device_providers.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/shift/shift_providers.dart';
import 'package:mts/providers/staff/staff_providers.dart';
import 'package:mts/providers/user/user_providers.dart';
import 'package:mts/providers/timecard/timecard_providers.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:vibration/vibration.dart';
import 'package:vibration/vibration_presets.dart';

class PinInputField extends ConsumerStatefulWidget {
  final TextEditingController pinController;
  final Function(bool) isPinValid;

  final bool isFromMainLoginPinPage;

  const PinInputField(
    this.pinController, {
    super.key,
    required this.isPinValid,
    required this.isFromMainLoginPinPage,
  });

  @override
  ConsumerState<PinInputField> createState() => _PinInputFieldState();
}

class _PinInputFieldState extends ConsumerState<PinInputField> {
  late StreamController<ErrorAnimationType> errorController;
  final SecureStorageApi _secureStorage =
      ServiceLocator.get<SecureStorageApi>();

  bool hasError = false;
  bool isValidPin = false;
  String errorMessage = '';

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
            final dialogNav = ref.read(myNavigatorProvider.notifier);
            // if (!await NetworkUtils.hasInternetConnection()) {
            //   prints('NO INTERNERT');
            //   hasError = true;
            //   errorMessage = 'noInternet'.tr();
            //   setState(() {});
            //   //set error

            //   widget.isPinValid(false);

            //   await Future.delayed(const Duration(seconds: 1));
            //   widget.pinController.clear();
            //   return;
            // } else {
            //   prints('HAVE INTERNET');
            // }
            LoadingDialog.show(context);
            UserModel userModel = UserModel();

            if (await NetworkUtils.hasInternetConnection()) {
              userModel = await ref
                  .read(staffProvider.notifier)
                  .isStaffPinValid(pin, (message) {
                    errorMessage = message;
                    setState(() {});
                  });
            } else {
              userModel = await ref
                  .read(staffProvider.notifier)
                  .isStaffPinValid(pin, (message) {
                    errorMessage = message;
                    setState(() {});
                  }, hasInternet: false);
            }

            LoadingDialog.hide(context);

            if (userModel.id != null) {
              // PIN CORRECT

              ref.read(userProvider.notifier).setCurrentUser(userModel);
              ref
                  .read(permissionProvider.notifier)
                  .assignStaffPermission(userModel, false);
              StaffModel? staffModel = await ref
                  .read(staffProvider.notifier)
                  .getStaffModelByUserId(userModel.id!.toString());

              isValidPin = true;
              widget.isPinValid(true);
              if (mounted) {
                // Sync with PIN success reason (loads local data based on policy)
                await ref
                    .read(appSyncServiceProvider.notifier)
                    .syncAll(
                      reason: SyncReason.pinSuccess,
                      context: context,
                      needToDownloadImage: false,
                    );
              }

              bool isOpenShift =
                  await ref.read(shiftProvider.notifier).hasShift();
              ShiftModel shiftModel =
                  await ref.read(shiftProvider.notifier).getLatestShift();
              if (isOpenShift) {
                prints('OPEN SHIFTTTT');

                final deviceModel =
                    await ref
                        .read(deviceProvider.notifier)
                        .getLatestDeviceModel();

                // await generalFacade.subscribePusher();

                // update staff model to assign current shift id
                if (staffModel?.id != null && shiftModel.id != null) {
                  await ref
                      .read(staffProvider.notifier)
                      .assignCurrentShift(staffModel!.id!, shiftModel.id!);
                }

                // update device
                if (deviceModel != null && deviceModel.id != null) {
                  PosDeviceModel updatedDeviceModel = deviceModel.copyWith(
                    isActive: true,
                  );
                  await ref
                      .read(deviceProvider.notifier)
                      .update(updatedDeviceModel);
                }
                ref.read(shiftProvider.notifier).setOpenShift();
              } else {
                LogUtils.log('close shift');
                ref.read(shiftProvider.notifier).setCloseShift();
              }

              if (widget.isFromMainLoginPinPage) {
                if (mounted) {
                  if (staffModel?.id != null) {
                    final currentPageIndex = dialogNav.pageIndex;
                    await ref
                        .read(timecardProvider.notifier)
                        .checkCurrentTimecard(
                          context,
                          staffModel!.id!,
                          mounted,
                          currentPageIndex,
                        );
                  }
                }
              }

              // setState(() {});
            } else {
              // WRONG PIN
              if (errorMessage.isNotEmpty) {
                showErrorDialogueFromResponse();
              }

              if (await Vibration.hasVibrator()) {
                Vibration.vibrate(preset: VibrationPreset.dramaticNotification);
              }
              //Failed to verified
              hasError = true;
              isValidPin = false;

              setState(() {});
              //set error
              errorController.add(ErrorAnimationType.shake);
              widget.isPinValid(false);

              await Future.delayed(const Duration(seconds: 1));
              widget.pinController.clear();
            }
            //}
          },
          onChanged: (value) async {
            if (value.length == 6) {
              prints("sama dengan 6");
              String? token = await _secureStorage.read(
                key: 'staff_access_token',
              );
              if (token.isNotEmpty == true) {
                // delete sebab nak refresh token when api pin return success
                // rewrite the token in the staff facade impl in method _processStafPinValidation
                await _secureStorage.delete(key: 'staff_access_token');
              }
            }
            setState(() {
              hasError = false;
              isValidPin = false;
            });
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
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
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
