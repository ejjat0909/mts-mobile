import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/core/config/constants.dart';

/// Text style normal
TextStyle textStyleNormal({
  Color color = Colors.black,
  double? fontSize,
  FontWeight? fontWeight,
  TextDecoration? decoration,
}) {
  return TextStyle(
    color: color,
    fontSize: fontSize ?? 14,
    fontFamily: 'Poppins',
    fontWeight: fontWeight ?? FontWeight.normal,
    decoration: decoration,
  );
}

/// Text style medium
TextStyle textStyleMedium({Color color = kTextGray}) {
  return TextStyle(
    color: color,
    fontSize: 14,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w500,
  );
}

/// Text style H1
TextStyle textStyleH1({Color color = kTextColor}) {
  return TextStyle(
    fontSize: 20.sp,
    color: color,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w500,
  );
}

/// Text style gray
TextStyle textStyleGray() {
  return const TextStyle(
    color: kTextGray,
    fontSize: 16,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold,
    decoration: TextDecoration.none,
  );
}

/// Text style italic
TextStyle textStyleItalic({Color color = kTextGray}) {
  return TextStyle(fontStyle: FontStyle.italic, color: color);
}
