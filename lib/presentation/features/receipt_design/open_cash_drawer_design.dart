import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/services/receipt_printer_service.dart';
import 'package:mts/plugins/flutter_thermal_printer/utils/printer.dart';

class OpenCashDrawerDesign {
  // only use just to open cash drawer out
  //
  static Future<void> openCashDrawer({
    required PrinterModel printer,
    required Function(String message, String ipAdd) onError,
    required String activityFrom,
    required Ref ref,
    String? customCommand,
  }) async {
    final ReceiptPrinterService printerService = ReceiptPrinterService(
      printer: printer,
      paperWidth: 'mm58',
    );

    await printerService.init();
    prints('OPENINGGGGGG CASH DRAWER');

    try {
      await printerService.drawer(
        activityFrom: activityFrom,
        ref: ref
      );
      
      await printerService.sendPrintData(onError, haveCut: false);
    } catch (e) {
      prints('Error opening cash drawer: $e');
      onError('Error opening cash drawer: $e', printer.address!);
    }
  }
}
