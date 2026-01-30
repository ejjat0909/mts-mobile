import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/downloaded_file/downloaded_file_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/receipt_setting/receipt_settings_model.dart';
import 'package:mts/data/services/receipt_printer_service.dart';
import 'package:mts/providers/downloaded_file/downloaded_file_providers.dart';
import 'package:mts/providers/outlet/outlet_providers.dart';
import 'package:mts/providers/receipt_settings/receipt_settings_providers.dart';

class HeaderDesign {
  /*
  =================================================================
                              HEADER
  =================================================================
  */

  static Future<void> headerDesign(
    ReceiptPrinterService printerService,
    Ref ref,
  ) async {
    final downloadedFileNotifier = ref.read(downloadedFileProvider.notifier);
    final receiptSettingsNotifier = ref.read(receiptSettingsProvider.notifier);
    final outletState = ref.read(outletProvider);
    final outletModel =
        outletState.items.isNotEmpty ? outletState.items.first : OutletModel();

    DownloadedFileModel dfm = await downloadedFileNotifier.getPrintedLogoPath();
    List<ReceiptSettingsModel> listRSM =
        await receiptSettingsNotifier.getListReceiptSettings();

    ReceiptSettingsModel rsm =
        listRSM.isNotEmpty ? listRSM.first : ReceiptSettingsModel();

    // Generate commands for printing
    prints("DFMMMMMM");
    prints("HEADER DESIGN");
    prints(dfm.toJson());
    if (dfm.id != null) {
      // check if printed logo is not null
      if (dfm.path != null && dfm.path!.isNotEmpty) {
        prints('Loading logo from path: ${dfm.path}');
        final File imageFile = File(dfm.path!);
        if (await imageFile.exists()) {
          final Uint8List imageBytes = await imageFile.readAsBytes();
          prints('Logo file size: ${imageBytes.length} bytes');

          // Add the image to the print bytes
          await printerService.printImage(imageBytes);
        } else {
          prints('LOGO FILE DOES NOT EXIST: ${dfm.path}');
        }
      } else {
        prints('LOGO PATH IS NULL OR EMPTY');
      }
    }
    if (rsm.id != null) {
      if (rsm.companyName != null) {
        await printerService.printTextCenter(rsm.companyName!, isBold: true);
      }

      if (rsm.outletName != null) {
        await printerService.printTextCenter(rsm.outletName!, isBold: true);
      }

      if (outletModel.id != null && outletModel.fullAddress != null) {
        await printerService.printTextCenter(outletModel.fullAddress!);
      }

      if (rsm.header != null && rsm.header!.isNotEmpty) {
        List<String> headerLines = rsm.header!.split('\n');
        for (String line in headerLines) {
          await printerService.printTextCenter(line);
        }
        await printerService.feed();
      }
    }
  }
}
