import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';

class ModifierOptionItem extends StatelessWidget {
  final bool isSelected;
  final Function() onPressed;
  final ModifierOptionModel element;

  const ModifierOptionItem({
    super.key,
    required this.isSelected,
    required this.onPressed,
    required this.element,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withValues(alpha: 0.2) : white,
          borderRadius: BorderRadius.circular(7.5),
          border: Border.all(
            width: isSelected ? 2 : 1,
            color: isSelected ? kPrimaryColor : kTextGray,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              element.name!,
              style: AppTheme.normalTextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'RM'.tr(
                args: [
                  element.price?.toStringAsFixed(2) ?? 0.toStringAsFixed(2),
                ],
              ),
              style: AppTheme.mediumTextStyle(color: kBlackColor),
            ),
          ],
        ),
      ),
    );
  }
}
