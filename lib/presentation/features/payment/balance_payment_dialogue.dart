import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/presentation/common/widgets/button_primary.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class BalancePaymentDialogue extends StatefulWidget {
  final double change;

  const BalancePaymentDialogue({super.key, required this.change});

  @override
  State<BalancePaymentDialogue> createState() => _BalancePaymentDialogueState();
}

class _BalancePaymentDialogueState extends State<BalancePaymentDialogue> {
  @override
  Widget build(BuildContext context) {
    double availableHeight = MediaQuery.of(context).size.height;
    double availableWidth = MediaQuery.of(context).size.width;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: availableHeight / 2,
          maxWidth: availableWidth / 5,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Space(20),
            Container(
              height: 50,
              decoration: const BoxDecoration(
                color: white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Center(
                child: Text(
                  'change'.tr(),
                  style: AppTheme.h1TextStyle(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const Space(10),
            Text(
              FormatUtils.formatNumber('RM'.tr(args: [widget.change.toStringAsFixed(2)])),
              style: AppTheme.h1TextStyle(),
            ),
            const Space(10),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ButtonPrimary(
                text: 'ok'.tr(),
                onPressed: () {
                  NavigationUtils.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
