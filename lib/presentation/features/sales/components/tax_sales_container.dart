import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/presentation/features/sales/components/discount_dialogue.dart';

class TaxSalesContainer extends ConsumerStatefulWidget {
  const TaxSalesContainer({super.key});

  @override
  ConsumerState<TaxSalesContainer> createState() => _TaxSalesContainerState();
}

class _TaxSalesContainerState extends ConsumerState<TaxSalesContainer> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: const BoxDecoration(color: white),
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return const DiscountDialogue();
              },
            );
          },
          splashColor: kPrimaryLightColor,
          highlightColor: kPrimaryLightColor,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'tax'.tr(),
                  style: AppTheme.normalTextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
