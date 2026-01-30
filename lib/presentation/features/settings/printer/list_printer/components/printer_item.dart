import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/printer_setting_enum.dart';
import 'package:mts/core/enums/permission_enum.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/ui_utils.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';

class PrinterItem extends ConsumerStatefulWidget {
  final PrinterSettingModel printerSettingModel;
  final PosDeviceModel currentPosDevice;
  final bool hasSettingPermission;

  const PrinterItem({
    super.key,
    required this.printerSettingModel,
    required this.currentPosDevice,
    required this.hasSettingPermission,
  });

  @override
  ConsumerState<PrinterItem> createState() => _PrinterItemState();
}

class _PrinterItemState extends ConsumerState<PrinterItem> {
  bool isPosDeviceSame = false;

  @override
  void initState() {
    isPosDeviceSame = widget.printerSettingModel.isPosDeviceSame ?? false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onPressed:
          isPosDeviceSame
              ? () async {
                await onPressPrinterItem(context, widget.hasSettingPermission);
              }
              : null,
      child: Container(
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.only(top: 10, right: 10, left: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: isPosDeviceSame ? [UIUtils.itemShadow()] : null,
          color: isPosDeviceSame ? white : kDisabledBg,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              getInterfaceIcon(),
              color: isPosDeviceSame ? kPrimaryColor : kTextGrayOpaque,
            ),
            SizedBox(width: 20.w),
            printerDetails(),
            posDeviceRegisterInfo(),
          ],
        ),
      ),
    );
  }

  Future<void> onPressPrinterItem(
    BuildContext context,
    bool hasPermissionSettings,
  ) async {
    if (!hasPermissionSettings) {
      await DialogUtils.showPinDialog(
        context,
        permission: PermissionEnum.CHANGE_SETTINGS,
        onSuccess: () async {
          ref
              .read(myNavigatorProvider.notifier)
              .setSelectedTab(
                4220,
                'editPrinter'.tr(),
                data: widget.printerSettingModel,
              );
        },
        onError: (error) {
          ThemeSnackBar.showSnackBar(context, error);
          return;
        },
      );
    }
    if (hasPermissionSettings) {
      ref
          .read(myNavigatorProvider.notifier)
          .setSelectedTab(
            4220,
            'editPrinter'.tr(),
            data: widget.printerSettingModel,
          );
    }
  }

  Widget posDeviceRegisterInfo() {
    if (isPosDeviceSame) {
      return const SizedBox.shrink();
    }
    return Expanded(
      child: Text(
        'registerUnder'.tr(
          args: [
            widget.printerSettingModel.posDeviceName ?? 'Different Device',
          ],
        ),
        //  'Registered under ${posFromPrinter.name}',
        style: textStyleItalic(),
      ),
    );
  }

  Widget printerDetails() {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.printerSettingModel.name!,
            style: AppTheme.mediumTextStyle(color: kBlackColor),
          ),
          SizedBox(height: 10.h),
          Text(
            widget.printerSettingModel.model!,
            style: AppTheme.grayTextStyle(),
          ),
          SizedBox(height: 5.h),
          Text(
            widget.printerSettingModel.identifierAddress!,
            style: AppTheme.italicTextStyle(),
          ),
        ],
      ),
    );
  }

  IconData getInterfaceIcon() {
    prints(widget.printerSettingModel.interface);
    switch (widget.printerSettingModel.interface) {
      case PrinterSettingEnum.bluetooth:
        return FontAwesomeIcons.bluetoothB;

      case PrinterSettingEnum.ethernet:
        return FontAwesomeIcons.wifi;

      default:
        return FontAwesomeIcons.usb;
    }
  }
}
