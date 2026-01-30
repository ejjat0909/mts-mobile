import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/core/config/constants.dart';

class CustomAppBarTables extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final Widget? action;
  final Function() onPressBack;

  const CustomAppBarTables({
    super.key,
    required this.title,
    this.action,
    required this.onPressBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,

      // Disable the default leading icon
      backgroundColor: canvasColor,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // left side of the app bar
          Expanded(
            flex: 5,
            child: Container(
              alignment: Alignment.center,
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      onPressed: onPressBack,
                      icon: const Icon(
                        FontAwesomeIcons.arrowLeft,
                        color: kWhiteColor,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 11,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kWhiteColor,
                      ),
                    ),
                  ),
                  Expanded(flex: 1, child: action ?? Container()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
