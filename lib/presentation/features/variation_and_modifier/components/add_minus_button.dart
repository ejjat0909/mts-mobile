import 'package:flutter/material.dart';
import 'package:mts/core/config/constants.dart';

class AddMinusButton extends StatelessWidget {
  final Function() press;
  final IconData icon;

  const AddMinusButton({super.key, required this.press, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: const BoxDecoration(color: white, shape: BoxShape.circle),
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: press,
          splashColor: kPrimaryBgColor,
          highlightColor: kPrimaryBgColor,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kPrimaryColor),
            ),
            padding: const EdgeInsets.all(15),
            child: Center(child: Icon(icon, color: kPrimaryColor)),
          ),
        ),
      ),
    );
  }
}
