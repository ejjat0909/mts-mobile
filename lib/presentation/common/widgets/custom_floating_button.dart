import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/core/config/constants.dart';

class CustomFloatingButton extends StatelessWidget {
  final Function onPressed;
  final String? tooltip;

  const CustomFloatingButton({
    super.key,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: tooltip,
      onPressed: () {
        onPressed();
      },
      backgroundColor: canvasColor,
      child: const Icon(FontAwesomeIcons.plus, color: white),
    );
  }
}
