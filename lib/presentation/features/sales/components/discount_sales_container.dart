import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/presentation/features/sales/components/discount_dialogue.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';

class DiscountSalesContainer extends ConsumerWidget {
  const DiscountSalesContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the total discount from Riverpod state
    final saleItemsState = ref.watch(saleItemProvider);
    final totalGrandDiscount = saleItemsState.totalDiscount;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: const BoxDecoration(color: white),
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) {
                return const DiscountDialogue();
              },
            );
          },
          splashColor: kPrimaryLightColor,
          highlightColor: kPrimaryLightColor,
          child: Container(
            padding: const EdgeInsets.only(top: 10, left: 15, right: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'discount'.tr(),
                  style: AppTheme.normalTextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                totalGrandDiscount == 0
                    ? const Icon(
                      FontAwesomeIcons.eye,
                      color: kPrimaryColor,
                      size: 20,
                    )
                    : Text(
                      FormatUtils.formatNumber(
                        totalGrandDiscount.toStringAsFixed(2),
                      ),
                      style: AppTheme.normalTextStyle(
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
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
