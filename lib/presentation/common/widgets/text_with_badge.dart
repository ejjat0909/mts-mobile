import 'package:flutter/material.dart';

class TextWithBadge extends StatelessWidget {
  final String? text;
  final Color textColor;
  final Color backgroundColor;
  final bool? isIcon;
  final IconData? icon;
  const TextWithBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.isIcon,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isIcon == true && icon != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(2.0),
        ),
        child: Icon(icon, color: textColor, size: 12.0),
      );
    }

    // If text is null or empty, return an empty padded badge
    if (text == null || text!.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(2.0),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        text!,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 11.0,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
