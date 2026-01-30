import 'package:flutter/material.dart';
import 'hive_list_page.dart';

/// Navigation helper for Hive Inspector feature
class HiveInspectorNavigation {
  /// Navigate to Hive Inspector list page
  /// 
  /// Usage:
  /// ```dart
  /// HiveInspectorNavigation.navigateToHiveList(context);
  /// ```
  static Future<void> navigateToHiveList(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HiveListPage(),
      ),
    );
  }

  /// Push and replace current page with Hive Inspector list
  /// 
  /// Usage:
  /// ```dart
  /// HiveInspectorNavigation.pushAndReplaceHiveList(context);
  /// ```
  static Future<void> pushAndReplaceHiveList(BuildContext context) async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HiveListPage(),
      ),
    );
  }
}