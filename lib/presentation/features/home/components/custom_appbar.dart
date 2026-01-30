import 'package:flutter/material.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/core/config/constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String leftSideTitle;
  final String rightSideTitle;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Function() leftSidePress;
  final IconData leftSideIcon;
  final IconData? action;
  final Function()? actionPress;

  const CustomAppBar({
    super.key,
    required this.leftSideTitle,
    required this.rightSideTitle,
    required this.scaffoldKey,
    required this.leftSidePress,
    required this.leftSideIcon,
    this.action,
    this.actionPress,
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
          // Left side of the app bar
          Expanded(
            flex: 2,
            child: Container(
              height: kToolbarHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topRight: Radius.circular(25)),
              ),
              child: Row(
                children: [
                  SizedBox(width: 10.w),
                  IconButton(
                    onPressed: leftSidePress,
                    icon: Icon(leftSideIcon, color: canvasColor),
                  ),
                  Expanded(
                    child: Text(
                      leftSideTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: canvasColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 7.5),
                    child: Icon(Icons.menu_rounded, color: white),
                  ),
                ],
              ),
            ),
          ),
          // Right side of the app bar
          Expanded(
            flex: 5,
            child: Container(
              alignment: Alignment.center,
              child: Row(
                children: [
                  Expanded(
                    flex: 11,
                    child: Text(
                      rightSideTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kWhiteColor,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: action != null && actionPress != null,
                    child: Expanded(
                      flex: 1,
                      child: ScaleTap(
                        onPressed: actionPress,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: kWhiteColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(action, color: canvasColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
