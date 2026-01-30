import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formatting utility functions
class FormatUtils {
  /// Format double value with thousand separator
  static String formatDouble(double value, {int decimalPlaces = 2}) {
    final formatter = NumberFormat(
      '#,##0.${decimalPlaces > 0 ? '0' * decimalPlaces : ''}',
      'en_US',
    );
    return formatter.format(value);
  }

  /// Format int value with thousand separator
  static String formatInt(int value) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(value);
  }

  /// Format string to number with thousand separator
  static String formatNumber(String input, {int decimalPlaces = 2}) {
    /**
     * 
      "RM 1000.50" → "RM 1,000.50"
      "$ 2500" → "$ 2,500.00"
      "USD 1234.56" → "USD 1,234.56"
      "MYR1000" → "MYR 1,000.00"
      "1000,500.25" → "1,000,500.25"
      "abc123" → "Invalid number"
      "RM abc" → "Invalid number"
     */
    try {
      // Remove whitespace
      String cleanInput = input.trim();

      // Check if input is empty
      if (cleanInput.isEmpty) {
        return 'Invalid number';
      }

      // Detect currency prefix
      String currencyPrefix = '';
      if (RegExp(r'^RM\s*', caseSensitive: false).hasMatch(cleanInput)) {
        currencyPrefix = 'RM ';
        cleanInput = cleanInput.replaceAll(
          RegExp(r'^RM\s*', caseSensitive: false),
          '',
        );
      } else if (RegExp(r'^\$\s*').hasMatch(cleanInput)) {
        currencyPrefix = '\$ ';
        cleanInput = cleanInput.replaceAll(RegExp(r'^\$\s*'), '');
      } else if (RegExp(
        r'^USD\s*',
        caseSensitive: false,
      ).hasMatch(cleanInput)) {
        currencyPrefix = 'USD ';
        cleanInput = cleanInput.replaceAll(
          RegExp(r'^USD\s*', caseSensitive: false),
          '',
        );
      } else if (RegExp(
        r'^MYR\s*',
        caseSensitive: false,
      ).hasMatch(cleanInput)) {
        currencyPrefix = 'MYR ';
        cleanInput = cleanInput.replaceAll(
          RegExp(r'^MYR\s*', caseSensitive: false),
          '',
        );
      }

      // Remove existing commas and trim
      cleanInput = cleanInput.replaceAll(',', '').trim();

      // Check if the cleaned string contains only valid number characters
      if (!RegExp(r'^-?\d*\.?\d+$').hasMatch(cleanInput)) {
        return 'Invalid number';
      }

      // Parse the string into a double
      double number = double.parse(cleanInput);

      // Format the number with commas
      final formatter = NumberFormat(
        '#,##0.${decimalPlaces > 0 ? '0' * decimalPlaces : ''}',
        'en_US',
      );

      // Return with currency prefix if it was detected
      return currencyPrefix + formatter.format(number);
    } catch (e) {
      return 'Invalid number'; // Return a fallback message if parsing fails
    }
  }

  /// Format speed in bytes per second to a human-readable format
  static String formatSpeed(double speedInBytesPerSecond) {
    if (!speedInBytesPerSecond.isFinite) {
      return '0 B/s';
    }
    if (speedInBytesPerSecond >= 1e9) {
      return '${(speedInBytesPerSecond / 1e9).toStringAsFixed(2)} GB/s';
    } else if (speedInBytesPerSecond >= 1e6) {
      return '${(speedInBytesPerSecond / 1e6).toStringAsFixed(2)} MB/s';
    } else if (speedInBytesPerSecond >= 1e3) {
      return '${(speedInBytesPerSecond / 1e3).toStringAsFixed(2)} KB/s';
    } else {
      return '${speedInBytesPerSecond.toStringAsFixed(2)} B/s';
    }
  }

  /// Get initials from name
  static String getInitials(String name) {
    List<String> nameSplit = name.split(' ');
    String initials = '';

    if (nameSplit.length > 1) {
      initials = nameSplit[0][0] + nameSplit[1][0];
    } else if (nameSplit.length == 1 && nameSplit[0].isNotEmpty) {
      initials = nameSplit[0][0];
    }

    return initials.toUpperCase();
  }

  /// Convert text to uppercase
  static String toUpperCase(String text) {
    return text.toUpperCase();
  }

  /// Convert text to lowercase
  static String toLowerCase(String text) {
    return text.toLowerCase();
  }

  /// Upper case text formatter for text input fields
  static TextInputFormatter upperCaseFormatter() {
    return TextInputFormatter.withFunction(
      (oldValue, newValue) => TextEditingValue(
        text: newValue.text.toUpperCase(),
        selection: newValue.selection,
      ),
    );
  }

  /// Lower case text formatter for text input fields
  static TextInputFormatter lowerCaseFormatter() {
    return TextInputFormatter.withFunction(
      (oldValue, newValue) => TextEditingValue(
        text: newValue.text.toLowerCase(),
        selection: newValue.selection,
      ),
    );
  }

  /// Parse a dynamic value to double
  /// Handles null, double, int, and String types
  static double? parseToDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static String? parseToString(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    return value.toString();
  }

  static int? parseToInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// Parse a dynamic value to boolean
  /// Handles null, bool, int (0/1), and String ('true'/'false') types
  static bool? parseToBool(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }
    if (value is int) {
      return value == 1;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return null;
  }

  /// Convert boolean to int (1/0)
  static int boolToInt(bool? value) {
    return value == true ? 1 : 0;
  }

  static String getFileNameFromUrl(String url) {
    return url.split('/').last;

    // String url =
    //     'https://mts.mahirandigital.com/img/item-rep/serve/01JRY9DNP8X4AYSH1YY6MN81FH.png';
    // String fileName = getFileNameFromUrl(url);
    // prints(fileName); // Output: 01JRY9DNP8X4AYSH1YY6MN81FH.png
  }
}
