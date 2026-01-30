import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/config/constants.dart';

class ButtonPrimary extends StatelessWidget {
  final Function()? onPressed;
  final String text;
  final TextStyle? textStyle;
  final IconData? icon;
  final Color? primaryColor;
  final Color? shadowColor;
  final Color? textColor;
  final Size? size;

  const ButtonPrimary({
    super.key,
    required this.onPressed,
    required this.text,
    this.textStyle,
    this.icon,
    this.primaryColor = kPrimaryColor,
    this.shadowColor = kPrimaryColor,
    this.textColor = kWhiteColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    bool isSingleWord = !text.contains(' ');

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: textColor,
        backgroundColor: primaryColor,
        fixedSize: size,
        shadowColor:
            shadowColor, //text,icon & overlay, use surface for disabled state
      ),
      onPressed: onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: screenHeight / 55),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate available width for text
            double availableWidth = constraints.maxWidth;
            if (icon != null) {
              availableWidth -= 16 + 10.w; // icon size + spacing
            }

            // Measure text to detect overflow
            final textPainter = TextPainter(
              text: TextSpan(
                text: text,
                style:
                    textStyle ??
                    textStyleNormal(
                      color: kWhiteColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              maxLines: 1,
              textDirection: TextDirection.ltr,
            );
            textPainter.layout(maxWidth: availableWidth);

            // If single word text overflows, use column layout
            bool textOverflows =
                isSingleWord && icon != null && textPainter.didExceedMaxLines;

            return textOverflows
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16),
                    SizedBox(height: 8.h),
                    Flexible(
                      child: AutoSizeText(
                        text,
                        style:
                            textStyle ??
                            textStyleNormal(
                              color: kWhiteColor,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        maxFontSize: textStyle == null ? 12 : double.infinity,
                        minFontSize: 10,
                      ),
                    ),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon == null ? const SizedBox() : Icon(icon, size: 16),
                    icon != null ? SizedBox(width: 10.w) : const SizedBox(),
                    Flexible(
                      child: AutoSizeText(
                        text,
                        style:
                            textStyle ??
                            textStyleNormal(
                              color: kWhiteColor,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        maxFontSize: textStyle == null ? 12 : double.infinity,
                        minFontSize: 10,
                      ),
                    ),
                  ],
                );
          },
        ),
      ),
    );
  }
}
