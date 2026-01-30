import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed ServiceLocator usage; prefer Riverpod providers for data access
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/data/services/receipt_printer_service.dart';
import 'package:mts/plugins/flutter_thermal_printer/utils/printer.dart';
import 'package:mts/presentation/features/receipt_design/footer_design.dart';
import 'package:mts/presentation/features/receipt_design/header_design.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';
import 'package:mts/providers/device/device_providers.dart';
import 'package:mts/providers/user/user_providers.dart';

/// Enum to identify which printer implementation to use
enum PrinterImplementation { flutterThermalPrinter, iminPrinter }

class TestPrint {
  /// Implementation for Flutter Thermal Printer
  static Future<void> testingDesign(
    PrinterModel printer,
    String paperWidth,
    Function(String message, String ipAddress) onError,
    Ref ref,
  ) async {
    // Prefer provider-sourced data
    final userNotifier = ref.read(userProvider.notifier);
    final deviceNotifier = ref.read(deviceProvider.notifier);
    final printerSettingNotifier = ref.read(printerSettingProvider.notifier);

    // Resolve current user and device via providers
    final UserModel userModel = userNotifier.currentUser ?? UserModel();
    final PosDeviceModel deviceModel =
        (await deviceNotifier.getLatestDeviceModel()) ?? PosDeviceModel();
    bool isIminPrinter = ReceiptPrinterService.isIminPrinter(printer);

    final ReceiptPrinterService receiptPrinterService = ReceiptPrinterService(
      printer: printer,
      paperWidth: paperWidth,
    );
    await receiptPrinterService.init();

    // Current logged-in user and device model are sourced via providers

    // Get custom drawer command from printer settings
    // String? customCommand;
    try {
      final printerSettings =
          await printerSettingNotifier.getListPrinterSettingModel();
      for (var setting in printerSettings) {
        if (setting.identifierAddress == printer.address) {
          setting.customCdCommand;
          // customCommand = setting.customCdCommand;
          break;
        }
      }
    } catch (e) {
      prints('Error fetching printer settings: $e');
    }
    // Queue drawer command before sending prints data
    if (!isIminPrinter) {
      await receiptPrinterService.drawer(
        // customCommand: "10,14,0,0,0",
        activityFrom: 'Test Print',
        ref: ref,
      );
    }
    // Header
    await HeaderDesign.headerDesign(receiptPrinterService, ref);

    // Cashier and POS
    await receiptPrinterService.printTextWithWrap(
      "Cashier: ${userModel.name ?? ""}",
    );

    await receiptPrinterService.printTextWithWrap('Paper: $paperWidth');

    await receiptPrinterService.printTextWithWrap(
      "POS: ${deviceModel.name ?? ''}",
    );

    // Add dashed line
    await receiptPrinterService.printDashedLine();

    await receiptPrinterService.feed();

    // Test receipt
    await receiptPrinterService.printTitle('Test Receipt');

    await receiptPrinterService.feed();

    // Add another dashed line
    await receiptPrinterService.printDashedLine();

    // Footer
    await FooterDesign.footer(receiptPrinterService, ref);

    // Print the receipt if printer is provided
    bool printSuccess = await receiptPrinterService.sendPrintData(onError);
    if (!printSuccess) {
      throw Exception('Failed to send prints data to printer');
    }
    if (isIminPrinter) {
      await receiptPrinterService.drawer(
        // customCommand: "10,14,0,0,0",
        activityFrom: 'Test Print',
        ref: ref,
      );

      await receiptPrinterService.sendPrintData(onError, haveCut: false);
    }
  }
}
