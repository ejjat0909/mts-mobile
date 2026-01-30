import 'package:flutter/material.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';

/// UI utility functions
class UIUtils {
  /// Create a themed input decoration
  static InputDecoration createInputDecoration({
    required String labelText,
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      isDense: true,
      errorStyle: AppTheme.normalTextStyle(color: kTextRed),
      errorText: errorText,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: kTextRed),
        gapPadding: 10,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: kTextGray),
        gapPadding: 10,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kPrimaryColor),
        gapPadding: 10,
      ),
      contentPadding: const EdgeInsets.fromLTRB(15, 18, 15, 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: kTextGray),
        gapPadding: 10,
      ),
      fillColor: Colors.white,
      filled: true,
      labelStyle: AppTheme.normalTextStyle(color: kTextGray),
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon: suffixIcon,
    );
  }

  /// Create a highlighted text span
  static TextSpan createHighlightedTextSpan(
    String content, {
    TextStyle style = const TextStyle(
      color: kPrimaryColor,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
  }) {
    return TextSpan(text: content, style: style);
  }

  /// Create a normal text span
  static TextSpan createNormalTextSpan(
    String content, {
    TextStyle style = const TextStyle(
      color: kPrimaryColor,
      fontSize: 14,
      fontWeight: FontWeight.normal,
    ),
  }) {
    return TextSpan(text: content, style: style);
  }

  /// Get text with highlighted search term
  static Text getHighlightedText(String text, String highlight) {
    if (highlight.isEmpty) {
      return Text(text);
    }

    int start = 0;
    List<TextSpan> spans = [];
    int indexOfHighlight;
    final String tempText = text.toLowerCase();
    final String tempHighlight = highlight.toLowerCase();

    do {
      indexOfHighlight = tempText.indexOf(tempHighlight, start);
      if (indexOfHighlight < 0) {
        // no highlight
        spans.add(createNormalTextSpan(text.substring(start, text.length)));
        break;
      }
      if (indexOfHighlight == start) {
        // start with highlight.
        spans.add(
          createHighlightedTextSpan(
            text.substring(start, start + highlight.length),
          ),
        );
        start += highlight.length;
      } else {
        // normal + highlight
        spans.add(
          createNormalTextSpan(text.substring(start, indexOfHighlight)),
        );
        spans.add(
          createHighlightedTextSpan(
            text.substring(
              indexOfHighlight,
              indexOfHighlight + highlight.length,
            ),
          ),
        );
        start = indexOfHighlight + highlight.length;
      }
    } while (true);

    return Text.rich(TextSpan(children: spans));
  }

  /// Create a responsive padding based on screen size
  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    double factor = 0.05,
  }) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * factor;
    return EdgeInsets.symmetric(horizontal: padding);
  }

  /// Create a responsive sized box based on screen size
  static SizedBox getResponsiveSizedBox(
    BuildContext context, {
    double heightFactor = 0.02,
    double widthFactor = 0.0,
  }) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height * heightFactor,
      width: widthFactor > 0 ? size.width * widthFactor : null,
    );
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Create a box shadow
  static BoxShadow createBoxShadow({
    Color color = const Color.fromRGBO(0, 0, 0, 0.1),
    Offset offset = const Offset(0, 2),
    double blurRadius = 4.0,
    double spreadRadius = 0.0,
  }) {
    return BoxShadow(
      color: color,
      offset: offset,
      blurRadius: blurRadius,
      spreadRadius: spreadRadius,
    );
  }

  /// Item shadows
  static List<BoxShadow> get itemShadows {
    return [
      BoxShadow(
        offset: const Offset(0, 2),
        blurRadius: 8,
        spreadRadius: 0,
        color: kBlackColor.withValues(alpha: 0.1),
      ),
    ];
  }

  static BoxShadow itemShadow() {
    return const BoxShadow(
      color: Color.fromRGBO(136, 136, 136, 0.1),
      offset: Offset(0, 1),
      blurRadius: 12.0,
    );
  }
}
