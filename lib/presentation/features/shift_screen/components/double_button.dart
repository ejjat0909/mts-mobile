import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/button_bottom.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/cash_management/cash_management_screen.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';
import 'package:mts/providers/app/app_providers.dart';
import 'package:mts/providers/shift/shift_providers.dart';
import 'package:mts/providers/user/user_providers.dart';

class DoubleButton extends ConsumerStatefulWidget {
  final BuildContext shiftBodyContext;
  const DoubleButton({super.key, required this.shiftBodyContext});

  @override
  ConsumerState<DoubleButton> createState() => _DoubleButtonState();
}

class _DoubleButtonState extends ConsumerState<DoubleButton> {
  UserModel userModel = ServiceLocator.get<UserModel>();
  UserModel? staffOpenShift;
  ShiftModel shiftModel = ShiftModel();
  String openingShiftTime = '';
  StaffModel staffModel = ServiceLocator.get<StaffModel>();

  Future<void> getUserModel() async {
    UserModel? user = await ref
        .read(userProvider.notifier)
        .getUserModelByIdUser(staffModel.userId!);

    userModel = user?.copyWith() ?? UserModel();
  }

  @override
  void initState() {
    super.initState();
    getUserModel();
    getShiftModel();
  }

  Future<void> getShiftModel() async {
    shiftModel = await ref.read(shiftProvider.notifier).getLatestShift();
    if (shiftModel.id != null) {
      DateTime createdAt = shiftModel.createdAt!;
      openingShiftTime = DateFormat(
        'hh.mm a | d MMMM yyyy',
        'en_US',
      ).format(createdAt);

      await getShiftOpenedBy(shiftModel);
    }
    setState(() {});
  }

  Future<void> getShiftOpenedBy(ShiftModel shiftModel) async {
    String? staffId = shiftModel.openedBy;
    if (staffId == null || staffId.isEmpty) {
      return;
    } else {
      staffOpenShift = await ref
          .read(userProvider.notifier)
          .getUserModelFromStaffId(staffId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appContextState = ref.watch(appProvider);
    final isSyncing = appContextState.isSyncing;
    return Container(
      // to make the container at the center of the screen
      margin: const EdgeInsets.only(top: 50, left: 200, right: 200, bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(10.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ButtonBottom(
                  //icon: FontAwesomeIcons.moneyBill1,
                  press: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) {
                          return CashManagementScreen(onBackPress: () {});
                        },
                      ),
                    );
                  },
                  'cashManagement'.tr(),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ButtonTertiary(
                  icon: FontAwesomeIcons.rightFromBracket,
                  onPressed: () async {
                    await onPressCloseShiftButton(isSyncing);
                  },
                  text: 'closeShift'.tr(),
                ),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${"shiftOpen".tr()} ${staffOpenShift?.name ?? userModel.name}',
                  style: AppTheme.mediumTextStyle(color: kBlackColor),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  openingShiftTime,
                  style: AppTheme.mediumTextStyle(color: kBlackColor),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          5.heightBox,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${"currentUser".tr()} ${userModel.name}',
                  style: AppTheme.mediumTextStyle(color: kBlackColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> onPressCloseShiftButton(bool isSyncing) async {
    final dialogueNav = ref.read(myNavigatorProvider.notifier);
    final shiftModel = await ref.read(shiftProvider.notifier).getLatestShift();
    final expectedCash =
        shiftModel.id != null && shiftModel.expectedCash != null
            ? shiftModel.expectedCash!
            : 0;

    if (isSyncing) {
      ThemeSnackBar.showSnackBar(context, 'synchronizingInProgress'.tr());
      return;
    }
    CustomDialog.show(
      context,
      icon: FontAwesomeIcons.rightFromBracket,
      isDissmissable: true,
      dialogType: DialogType.warning,
      title: 'closeShiftDialog'.tr(),
      description: 'closeShiftDialogText'.tr(),
      btnCancelText: 'cancel'.tr(),
      btnCancelOnPress: () {
        NavigationUtils.pop(context);
      },
      btnOkText: 'closeShift'.tr(),
      btnOkOnPress: () async {
        // close dialogue
        NavigationUtils.pop(context);
        // go to close shift screen
        dialogueNav.setSelectedTab(3300, 'closeShift'.tr());
        dialogueNav.setIsCloseShiftScreen(true);
        // open cash drawer
        if (expectedCash > 0) {
          await ref
              .read(printerSettingProvider.notifier)
              .openCashDrawerManually((errorMessage) {
                ThemeSnackBar.showSnackBar(
                  widget.shiftBodyContext,
                  errorMessage,
                );
              }, activityFrom: 'When press close shift button in shift page');
        }
      },
    );
  }
}
