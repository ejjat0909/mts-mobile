import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/discount_type_enum.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/presentation/common/widgets/bordered_icon.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/providers/discount/discount_providers.dart';

class TaxItem extends ConsumerWidget {
  final TaxModel taxModel;

  final bool isSelected;

  const TaxItem({super.key, required this.taxModel, this.isSelected = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discountNotifier = ref.read(discountProvider.notifier);
    bool isWithinRange = discountNotifier.isNowWithinRange(
      taxModel.createdAt,
      taxModel.updatedAt,
    );

    if (isWithinRange) {
      return selectedDiscount();
    }
    return notSelected();
  }

  Widget selectedDiscount() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7.5),
        border: Border.all(width: 0.5, color: Colors.transparent),
      ),
      child: Stack(
        children: [
          // call this double to initiate the container height
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: selectedColor,
              borderRadius: BorderRadius.all(Radius.circular(7.5)),
            ),
            child: discountDetails(Colors.transparent),
          ),

          const Positioned(
            top: -25,
            right: -25,
            child: BorderedIcon(
              strokeColor: white,
              strokeWidth: 10,
              icon: Icon(FontAwesomeIcons.tag, size: 100, color: selectedColor),
            ),
          ),
          SizedBox(width: double.infinity, child: discountDetails(kBlackColor)),
        ],
      ),
    );
  }

  Column discountDetails(Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(FontAwesomeIcons.tag, color: color),
        const Space(10),
        Text(
          taxModel.name ?? 'noName'.tr(),
          style: AppTheme.normalTextStyle(color: color),
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
        const Space(5),
        taxModel.type == DiscountTypeEnum.amount
            ? Text(
              'RM'.tr(
                args: [
                  taxModel.rate?.toStringAsFixed(2) ?? 0.toStringAsFixed(2),
                ],
              ),
              style: AppTheme.normalTextStyle(color: color),
            )
            : Text(
              '${taxModel.rate?.toStringAsFixed(0)}%',
              style: AppTheme.normalTextStyle(color: color),
            ),
      ],
    );
  }

  Container notSelected() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kDisabledBg,
        borderRadius: BorderRadius.circular(7.5),
        border: Border.all(width: 0.5, color: white),
      ),
      child: discountDetails(kTextGray),
    );
  }
}
