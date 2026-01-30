import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog2.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/rolling_text.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/providers/outlet/outlet_providers.dart';

class RowResetOrderNumber extends ConsumerStatefulWidget {
  final OutletModel outletModel;
  const RowResetOrderNumber({super.key, required this.outletModel});

  @override
  ConsumerState<RowResetOrderNumber> createState() =>
      _RowResetOrderNumberState();
}

class _RowResetOrderNumberState extends ConsumerState<RowResetOrderNumber> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final outletModel = ref
        .watch(outletProvider.notifier)
        .getOutletById(widget.outletModel.id ?? '');
    int latestSaleNumber =
        outletModel?.nextOrderNumber != null
            ? outletModel!.nextOrderNumber!
            : -1;
    return Row(
      children: [
        // Replace the Text widget with RollingNumber
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Text(
                'nextOrderNumber'.tr(),
                style: AppTheme.mediumTextStyle(color: kBlackColor),
              ),
              5.widthBox,
              RollingNumber(
                value: latestSaleNumber,
                decimalPlaces: 0,
                useThousandsSeparator: false,
                style: AppTheme.mediumTextStyle(color: kBlackColor),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack, // Now this works
                widthCurve: Curves.easeInOut, // Specify compatible width curve
                animate: latestSaleNumber > 0,
              ),
            ],
          ),
        ),

        Expanded(
          child: ButtonTertiary(
            text: 'reset'.tr(),
            icon: FontAwesomeIcons.arrowsRotate,
            onPressed: () async {
              if (outletModel != null) {
                await onPressResetButton(outletModel);
              }
            },
          ),
        ),
      ],
    );
  }

  Future<void> onPressResetButton(OutletModel outletModel) async {
    if (outletModel.id == null && outletModel.nextOrderNumber == null) {
      ThemeSnackBar.showSnackBar(context, "Error: Device is null");
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return CustomDialog2(
          icon: FontAwesomeIcons.arrowsRotate,
          title: 'resetNextOrderNumberTo1'.tr(),
          description: 'areYouSureYouWantToResetNextOrderNumber'.tr(),
          btnCancelText: 'cancel'.tr(),
          btnCancelOnPress: () {
            NavigationUtils.pop(context);
          },
          btnOkText: 'ok'.tr(),
          btnOkOnPress: () async {
            NavigationUtils.pop(context);
            await Future.delayed(const Duration(milliseconds: 200));
            await ref.read(outletProvider.notifier).resetNextOrderNumber();
          },
        );
      },
    );
  }
}
