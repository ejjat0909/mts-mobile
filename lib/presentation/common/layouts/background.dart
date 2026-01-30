import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/core/config/constants.dart';
import 'package:proste_bezier_curve/proste_bezier_curve.dart';

class Background extends StatefulWidget {
  const Background({super.key});

  @override
  State<Background> createState() => _BackgroundState();
}

class _BackgroundState extends State<Background> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        ClipPath(
          clipper: ProsteThirdOrderBezierCurve(
            position: ClipPosition.bottom,
            list: [
              ThirdOrderBezierCurveSection(
                p1: const Offset(0, 0),
                p2: Offset(200.w, 600.h),
                p3: Offset(screenWidth * 0.85, 50.h),
                p4: Offset(screenWidth * 1.15, screenHeight * 1.42),
                //1.59375
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(gradient: kPrimaryGradientRed),
            height: screenHeight,
            width: screenWidth,
          ),
        ),
        ClipPath(
          clipper: ProsteThirdOrderBezierCurve(
            position: ClipPosition.bottom,
            list: [
              ThirdOrderBezierCurveSection(
                p1: const Offset(0, 0),
                p2: Offset(200.w, 600.h),
                p3: Offset(screenWidth, -100.h),
                p4: Offset(screenWidth * 1.1, screenHeight * 1.55625),
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(gradient: kPrimaryGradientColor),
            height: screenHeight,
            width: screenWidth,
          ),
        ),
      ],
    );
  }
}
