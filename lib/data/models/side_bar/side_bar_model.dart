import 'package:flutter/material.dart';

class SideBarModel {
  final String title;
  final IconData icon;
  final bool haveNestedSideBar;
  final int index;

  SideBarModel({
    required this.title,
    required this.icon,
    required this.haveNestedSideBar,
    required this.index,
  });
}
