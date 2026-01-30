import 'package:flutter/material.dart';
import 'package:mts/core/config/constants.dart';

class CustomSwitch extends StatelessWidget {
  final bool value;
  final Function(bool)? onChanged;
  final bool isDisabled;

  const CustomSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      activeColor: kPrimaryColor,
      activeTrackColor: kWhiteColor,
      inactiveTrackColor: kBg,
      inactiveThumbColor:
          isDisabled ? kTextGray.withValues(alpha: 0.2) : canvasColor,
      trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        return states.contains(WidgetState.selected)
            ? kPrimaryColor
            : (isDisabled ? kTextGray.withValues(alpha: 0.2) : canvasColor);
      }),
      value: isDisabled ? false : value,
      onChanged: onChanged,
      padding: EdgeInsets.all(0),
    );
  }
}
