import 'package:flutter/material.dart';
import 'package:mts/core/config/constants.dart';

class ColoredSafeArea extends StatelessWidget {
  final Widget child;
  final Color color;
  final double width;

  const ColoredSafeArea({
    super.key,
    required this.child,
    this.color = kHeader,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: color, child: SafeArea(child: child));
  }
}
