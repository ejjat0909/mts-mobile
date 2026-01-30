import 'package:flutter/material.dart';

class BorderedIcon extends StatelessWidget {
  const BorderedIcon({
    super.key,
    required this.icon,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.strokeWidth = 6.0,
    this.strokeColor = const Color.fromRGBO(53, 0, 71, 1),
  });

  /// the stroke cap style
  final StrokeCap strokeCap;

  /// the stroke joint style
  final StrokeJoin strokeJoin;

  /// the stroke width
  final double strokeWidth;

  /// the stroke color
  final Color strokeColor;

  /// the [Icon] widget to apply stroke on
  final Icon icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // Icon(
        //   icon.icon,
        //   size: icon.size,
        //   color: Colors
        //       .transparent, // The inner color of the icon should be transparent
        //   textDirection: icon.textDirection,
        //   semanticLabel: icon.semanticLabel,
        // ),
        Icon(
          icon.icon,
          size: icon.size! + strokeWidth,
          color: strokeColor,
          textDirection: icon.textDirection,
          semanticLabel: icon.semanticLabel,
        ),
        icon,
      ],
    );
  }
}
