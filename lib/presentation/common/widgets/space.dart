import 'package:flutter/material.dart';

class Space extends StatelessWidget {
  final double height;

  const Space(this.height, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}

// example usage
// 16.heighBox
// 8.widthBox
extension WidgetSizedBoxFromNumExtension on num {
  Widget get widthBox => SizedBox(width: toDouble());
  Widget get heightBox => SizedBox(height: toDouble());
}
