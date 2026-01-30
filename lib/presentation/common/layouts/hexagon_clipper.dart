import 'package:flutter/material.dart';

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double width = size.width;
    double height = size.height;

    Path path = Path();
    path.moveTo(width / 2, 0); // Top middle point
    path.lineTo(width, height / 4); // Top right point
    path.lineTo(width, 3 * height / 4); // Bottom right point
    path.lineTo(width / 2, height); // Bottom middle point
    path.lineTo(0, 3 * height / 4); // Bottom left point
    path.lineTo(0, height / 4); // Top left point
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class HexagonContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double? width;
  final double? height;
  final BoxDecoration? decoration;
  final EdgeInsets? padding;
  final List<BoxShadow>? boxShadow;

  const HexagonContainer({
    super.key,
    required this.child,
    this.color,
    this.width,
    this.height,
    this.decoration,
    this.padding,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipPath(
          clipper: HexagonClipper(),
          child: DecoratedBox(
            decoration: BoxDecoration(boxShadow: boxShadow),
            child: Container(
              width: width,
              height: height,
              color: Colors.transparent, // Transparent to show shadow
            ),
          ),
        ),
        ClipPath(
          clipper: HexagonClipper(),
          child: Container(
            decoration:
                decoration?.copyWith(color: color) ??
                BoxDecoration(color: color),
            padding: padding,
            width: width,
            height: height,
            child: child,
          ),
        ),
      ],
    );
  }
}
