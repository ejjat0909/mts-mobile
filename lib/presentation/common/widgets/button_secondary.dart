import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/core/config/constants.dart';

class ButtonSecondary extends StatelessWidget {
  final Function()? onPressed;
  final String text;
  final TextStyle? textStyle;
  final IconData? icon;
  final Size? size;

  const ButtonSecondary({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.size,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimaryColor,
        fixedSize: size,
        backgroundColor:
            Colors.white, //text,icon & overlay, use surface for disabled state
        side: const BorderSide(color: kPrimaryColor),
      ),
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon == null ? const SizedBox() : Icon(icon),
            SizedBox(width: 10.w),
            Text(text, style: textStyle),
          ],
        ),
      ),
    );
  }
}
