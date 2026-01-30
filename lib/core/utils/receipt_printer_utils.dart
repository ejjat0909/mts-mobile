import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:mts/plugins/flutter_thermal_printer/utils/printer.dart';

class ReceiptPrinterUtils {
  static bool isIminPrinter(dynamic input) {
    String name = '';
    if (input is PrinterModel) {
      name = input.name?.toLowerCase() ?? '';
    } else if (input is String) {
      name = input.toLowerCase();
    }

    return name.contains('inner') || name.contains('imin');
  }

  static int getFontSize(PosTextSize size) {
    const fontSizes = {
      PosTextSize.size1: 24,
      PosTextSize.size2: 40,
      PosTextSize.size3: 72,
      PosTextSize.size4: 96,
      PosTextSize.size5: 120,
      PosTextSize.size6: 144,
      PosTextSize.size7: 168,
      PosTextSize.size8: 192,
    };

    return fontSizes[size] ?? 24; // Default to size1 if not matched
  }

  static List<int> convertToListInt(String cashDrawerCommand) {
    // received String = 10,12,13,14,15,16,17,18,19,20
    // expected output = [49, 48, 44, 49, 50 ... ]
    List<int> bytes = [];

    // Convert each character in the string to its ASCII value
    for (int i = 0; i < cashDrawerCommand.length; i++) {
      bytes.add(cashDrawerCommand.codeUnitAt(i));
    }

    return bytes;
  }
}
