import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/core/config/constants.dart';

class EmptyDottedContainer extends StatelessWidget {
  const EmptyDottedContainer({
    super.key,
    required this.isEditMode,
    this.isSquare = false,
  });

  final bool isEditMode;
  final bool isSquare;

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      borderType: BorderType.RRect,

      radius: const Radius.circular(5),
      padding: const EdgeInsets.all(6),
      dashPattern: const <double>[5, 2],
      // [panjang, jarak]
      color: canvasColor,
      child:
          isEditMode
              ? Padding(
                padding: EdgeInsets.symmetric(vertical: isSquare ? 32.0 : 0),
                child: const Center(
                  child: Icon(
                    FontAwesomeIcons.plus,
                    color: kPrimaryColor,
                    size: 30,
                  ),
                ),
              )
              : Container(),
    );
  }
}
