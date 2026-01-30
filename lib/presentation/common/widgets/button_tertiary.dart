import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/core/config/constants.dart';

class ButtonTertiary extends StatelessWidget {
  final Function()? onPressed;
  final Color? textColor;
  final String text;
  final IconData? icon;
  final Size? size;
  final Color? shadowColor;

  const ButtonTertiary({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.shadowColor = kPrimaryColor,
    this.size,
    this.textColor = kPrimaryColor,
  });

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        fixedSize: size,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            5,
          ), // Adjust the value to change the border radius
        ),
        backgroundColor: Colors.white,
        foregroundColor: textColor ?? kPrimaryColor,
        //text,icon & overlay, use surface for disabled state
        side: BorderSide(
          color: onPressed != null ? (textColor ?? kPrimaryColor) : kTextGray,
        ),
      ),
      onPressed: onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: screenHeight / 55),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon == null ? const SizedBox() : Icon(icon, size: 16),
            icon != null ? SizedBox(width: 10.w) : const SizedBox(),
            Flexible(
              child: AutoSizeText(
                text,
                textAlign: TextAlign.center,
                maxFontSize: 12,
                minFontSize: 10,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
