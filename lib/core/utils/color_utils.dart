import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/table_status_enum.dart';
import 'package:mts/data/models/table/table_model.dart';

/// Color utility functions
class ColorUtils {
  /// Convert hex string to color

  static Color hexToColor(String? hex) {
    if (hex == null) return Colors.white;

    try {
      final cleaned = hex.trim().replaceAll('#', '').toUpperCase();

      // Must match 6 or 8 hex digits exactly
      final isValidHex = RegExp(
        r'^[0-9A-F]{6}$|^[0-9A-F]{8}$',
      ).hasMatch(cleaned);
      if (!isValidHex) return Colors.white;

      final fullHex = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
      final intValue = int.parse(fullHex, radix: 16);
      return Color(intValue);
    } catch (e) {
      // Catch any unexpected parsing issues
      return Colors.white;
    }
  }

  /// Check if a color is dark
  static bool isColorDark(String hexColor) {
    hexColor = hexColor.trim().replaceAll('#', '').toUpperCase();

    // Handle shorthand hex color (e.g. #CCC -> CCCCCC)
    if (hexColor.length == 3) {
      hexColor = hexColor.split('').map((char) => char * 2).join();
    }

    // Validate the hex format (must be exactly 6 hex digits)
    final isValidHex = RegExp(r'^[0-9A-F]{6}$').hasMatch(hexColor);
    if (!isValidHex) {
      hexColor = 'FFFFFF'; // fallback to white
    }

    try {
      int r = int.parse(hexColor.substring(0, 2), radix: 16);
      int g = int.parse(hexColor.substring(2, 4), radix: 16);
      int b = int.parse(hexColor.substring(4, 6), radix: 16);

      double luminance = 0.299 * r + 0.587 * g + 0.114 * b;
      return luminance < 128; // true = dark, false = light
    } catch (e) {
      // In case parsing somehow fails, fallback to white
      return false;
    }
  }

  /// Get a random color
  static Color getRandomColor() {
    Random random = Random();
    return Color.fromARGB(
      255, // Fully opaque
      random.nextInt(256), // Red value
      random.nextInt(256), // Green value
      random.nextInt(256), // Blue value
    );
  }

  /// Get a deterministic color based on a string
  static Color getColorFromString(String text) {
    final List<Color> colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    int index = 0;
    for (int i = 0; i < text.length; i++) {
      index += text.codeUnitAt(i);
    }

    return colors[index % colors.length];
  }

  /// Create a box shadow for items
  static BoxShadow createBoxShadow({
    Color color = const Color.fromRGBO(136, 136, 136, 0.1),
    Offset offset = const Offset(0, 1),
    double blurRadius = 12.0,
  }) {
    return BoxShadow(color: color, offset: offset, blurRadius: blurRadius);
  }

  /// Get table color based on status
  static Color getTableStatusColor(TableModel tableModel) {
    // Using the values from Helper class
    return tableModel.status == TableStatusEnum.OCCUPIED
        ? Colors.blue
        : tableModel.status == TableStatusEnum.UNOCCUPIED
        ? Colors.white
        : kTextGray; // disabled
  }
}
