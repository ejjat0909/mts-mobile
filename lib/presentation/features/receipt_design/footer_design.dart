import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/models/receipt_setting/receipt_settings_model.dart';
import 'package:mts/data/services/receipt_printer_service.dart';
import 'package:mts/providers/receipt_settings/receipt_settings_providers.dart';

class FooterDesign {
  static Future<void> footer(
    ReceiptPrinterService receiptPrinterService,
    Ref ref,
  ) async {
    final receiptSettingsNotifier = ref.read(receiptSettingsProvider.notifier);
    List<ReceiptSettingsModel> listRSM =
        await receiptSettingsNotifier.getListReceiptSettings();

    ReceiptSettingsModel rsm =
        listRSM.isNotEmpty ? listRSM.first : ReceiptSettingsModel();

    // Generate commands for printing

    if (rsm.id != null) {
      if (rsm.footer != null && rsm.footer!.isNotEmpty) {
        List<String> footerLines = rsm.footer!.split('\n');
        for (String line in footerLines) {
          await receiptPrinterService.printTextCenter(line);
        }
      }
    }
    await receiptPrinterService.printTextCenter(
      receiptPrinterService.formatDateTime(),
    );
  }
}
