import 'package:flutter/material.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:mts/core/config/constants.dart';

class DrawerItem extends StatelessWidget {
  final Function() onTapped;
  final bool isSelected;
  final String title;
  final IconData iconData;

  const DrawerItem({
    super.key,
    required this.onTapped,
    required this.isSelected,
    required this.title,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onPressed: () {
        onTapped();
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: isSelected ? kItemColor : white),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15, top: 15, bottom: 15),
              child: Icon(
                iconData,
                size: 25,
                color: isSelected ? kPrimaryColor : canvasColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 15, top: 15, bottom: 15),
                child: Text(title),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 2.5,
                vertical: 26,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: isSelected ? kPrimaryColor : white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
