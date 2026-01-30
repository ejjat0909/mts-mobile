import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/core/enum/tax_type_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/modifier/modifier_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';
import 'package:mts/data/services/receipt_printer_service.dart';
import 'package:mts/plugins/flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:mts/plugins/flutter_thermal_printer/utils/printer.dart';
import 'package:mts/presentation/features/receipt_design/footer_design.dart';
import 'package:mts/presentation/features/receipt_design/header_design.dart';
import 'package:mts/providers/receipt_item/receipt_item_providers.dart';

/// Class responsible for generating sales receipt designs
class SalesDesignPrint {
  /*
  =================================================================
                              Design
  =================================================================
  */

  /// Prints a sales receipt
  static Future<void> salesDesign({
    required String paperWidth,
    required PrinterModel printer,
    required ReceiptModel receiptModel,
    required List<ReceiptItemModel> receiptItems,
    required Function(String message, String ipAddress) onError,
    required List<PrinterSettingModel> listPrinterSettings,
    required bool isAutomaticPrint,
    required String activityFrom,
    required Ref ref,
    bool isOpenCashDrawer = false,
  }) async {
    final receiptItemNotifier = ref.read(receiptItemProvider.notifier);
    bool isRefund = receiptModel.refundedReceiptId != null;
    bool isIminPrinter = ReceiptPrinterService.isIminPrinter(printer);

    // Create a receipt printer service instance
    final receiptPrinterService = ReceiptPrinterService(
      printer: printer,
      paperWidth: paperWidth,
    );
    await receiptPrinterService.init();
    // Find the printer setting that matches the current printer
    PrinterSettingModel? currentPrinterSetting =
        listPrinterSettings
            .where((ps) => ps.identifierAddress == printer.address)
            .firstOrNull;

    if (currentPrinterSetting == null) {
      prints("❌❌❌❌❌❌❌❌❌No printer setting found for ${printer.address}");
      return;
    }

    // Check if THIS specific printer should prints
    bool shouldPrint = false;
    if (isAutomaticPrint) {
      shouldPrint = currentPrinterSetting.automaticallyPrintReceipt == true;
    } else {
      shouldPrint = currentPrinterSetting.printReceiptBills == true;
    }
    // Note: drawer command is now sent AFTER receipt prints via openCashDrawer function
    // This ensures better compatibility with various printer types
    if (!shouldPrint) {
      // Not printing receipt, but still need to open drawer if requested
      if (isOpenCashDrawer) {
        await receiptPrinterService.drawer(
          activityFrom: activityFrom,
          ref: ref,
        );
        await receiptPrinterService.sendPrintData(onError, haveCut: false);
      }
      receiptPrinterService.resetBytes();
      return; // Exit early since we're not printing
    }
    // only prints if printer setting not empty. the filter has been made above
    if (shouldPrint) {
      if (isRefund) {
        await receiptPrinterService.printTitle('refund'.tr());
      }

      // Add the store header with logo and store information
      await HeaderDesign.headerDesign(receiptPrinterService, ref);

      // Add receipt refund ID
      if (isRefund) {
        await receiptPrinterService.printTextWithWrap(
          "${'refundedReceipt'.tr()}: ${receiptModel.refundedReceiptId}",
        );
      }
      // Add receipt UUID (unique identifier) if available
      if (receiptModel.showUUID != null) {
        await receiptPrinterService.printTextWithWrap(
          "${'receiptId'.tr()}: ${receiptModel.showUUID}",
        );
      }

      // Add receipt number (sequential number for tracking)
      await receiptPrinterService.printTextWithWrap(
        '${isRefund ? "originalReceipt".tr() : "orderNumber".tr()}: ${receiptModel.runningNumber}',
      );

      // for remarks, can be null because remarks get from custom predefined order model
      if (receiptModel.remarks != null && receiptModel.remarks!.isNotEmpty) {
        await receiptPrinterService.printTextWithWrap(
          "${'remarks'.tr()}: ${receiptModel.remarks}",
        );
      }

      // Add cashier information (staff who processed the transaction)
      await receiptPrinterService.printTextWithWrap(
        "${'cashier'.tr()}: ${receiptModel.staffName}",
      );

      // ordered by, the waiter who take the order
      await receiptPrinterService.printTextWithWrap(
        "${'orderBy'.tr()}: ${receiptModel.orderedByStaffName}",
      );

      // Add customer name if available (for customer identification)
      await receiptPrinterService.printTextWithWrap(
        '${"customer".tr()}: ${receiptModel.customerName ?? '-'}',
      );

      // Add payment type if available (cash, credit card, etc.)
      await receiptPrinterService.printTextWithWrap(
        "${'paymentType'.tr()}: ${receiptModel.paymentType}",
      );

      // Add transaction date and time
      await receiptPrinterService.printTextWithWrap(
        '${"dateGenerated".tr()}: ${receiptPrinterService.formatDateTime(receivedDateTime: receiptModel.updatedAt)}',
      );

      // Add order option if available (dine-in, takeaway, delivery, etc.)
      if (receiptModel.orderOption != null &&
          receiptModel.orderOption!.isNotEmpty) {
        await receiptPrinterService.printTextWithWrap(
          '${"orderOption".tr()}: ${receiptModel.orderOption}',
        );
      }

      if (receiptModel.tableName != null &&
          receiptModel.tableName!.isNotEmpty) {
        await receiptPrinterService.printTextWithWrap(
          '${receiptModel.tableName}',
          // '${"table".tr()}: ${receiptModel.tableName}',
        );
      }

      // Add dashed line
      await receiptPrinterService.printDashedLine();

      // Add items
      for (var entry in receiptItems.asMap().entries) {
        int index = entry.key;
        String numbering = "${index + 1} - ";
        String spacingLength = getItemSpacing(index);
        ReceiptItemModel receiptItem = entry.value;
        String itemName = receiptItem.name ?? '';
        //String itemName = "dskjbfsdhkfbdhjksbfs dhfjbdshjfbvdhsjf";

        // Parse modifiers and variant option
        List<ModifierModel> modifiers = [];
        VariantOptionModel variantOption = VariantOptionModel();

        if (receiptItem.modifiers != null &&
            receiptItem.modifiers!.isNotEmpty) {
          List<dynamic> modifierJson = jsonDecode(receiptItem.modifiers!);
          modifiers = List.generate(
            modifierJson.length,
            (index) => ModifierModel.fromJsonReceiptItem(modifierJson[index]),
          );
        }

        if (receiptItem.variants != null) {
          dynamic variantOptionJson = jsonDecode(receiptItem.variants!);
          variantOption = VariantOptionModel.fromJson(variantOptionJson);
        }
        // Print unit price and quantity
        String? qty =
            receiptItem.soldBy == ItemSoldByEnum.item
                ? receiptItem.quantity?.toStringAsFixed(0)
                : receiptItem.quantity?.toStringAsFixed(3);

        double unitPrice = 0;
        if (receiptItem.grossAmount != null &&
            receiptItem.quantity != null &&
            receiptItem.quantity! > 0) {
          unitPrice = receiptItem.grossAmount! / receiptItem.quantity!;
        }
        // Print the item name and price
        await receiptPrinterService.printTextThreeColumn(
          "$numbering$itemName",
          '$qty x ${unitPrice.toStringAsFixed(2)}',
          receiptItem.grossAmount?.toStringAsFixed(2) ?? '0.00',
        );

        // Print variant option if exists
        if (variantOption.id != null) {
          await receiptPrinterService.printTextWithWrap(
            "$spacingLength${variantOption.name ?? ''}",
          );
        }

        // Group and prints modifiers
        Map<String, List<ModifierOptionModel>> groupedModifiers = {};
        for (ModifierModel modifier in modifiers) {
          if (modifier.id != null) {
            groupedModifiers.putIfAbsent(modifier.id!, () => []);
            groupedModifiers[modifier.id!]!.addAll(
              modifier.modifierOptions ?? [],
            );
          }
        }

        // Print each modifier and its options
        for (String modifierId in groupedModifiers.keys) {
          String modifierOptionText = groupedModifiers[modifierId]!
              .map((e) => e.name)
              .join(', ');

          await receiptPrinterService.printTextWithWrap(
            "$spacingLength$modifierOptionText",
          );
        }
        // await receiptPrinterService.printTextWithWrap(
        //   '$spacingLength$qty x ${unitPrice.toStringAsFixed(2)}',
        // );

        // Only add spacing if not the last item
        if (index < receiptItems.length - 1) {
          await receiptPrinterService.feed();
        }
      }

      // Add dashed line
      await receiptPrinterService.printDashedLine();

      // Add subtotal
      await receiptPrinterService.printTextWithWrap(
        'subtotal'.tr(),
        rightText: receiptModel.grossSale?.toStringAsFixed(2) ?? '0.00',
      );
      await receiptPrinterService.feed();

      // Add adjustment
      await receiptPrinterService.printTextWithWrap(
        'adjustment'.tr(),
        rightText:
            '-${receiptModel.adjustedPrice?.toStringAsFixed(2) ?? '0.00'}',
      );

      // Add discount
      await receiptPrinterService.printTextWithWrap(
        'discount'.tr(),
        rightText:
            '-${receiptModel.totalDiscount?.toStringAsFixed(2) ?? '0.00'}',
      );

      // Add tax
      // await receiptPrinterService.printTextWithWrap(
      //   'tax'.tr(),
      //   rightText: receiptModel.totalTaxes?.toStringAsFixed(2) ?? '0.00',
      // );

      // list of tax
      final taxAmountsMap = await receiptItemNotifier
          .getAllTaxesWithAmountsByReceiptId(receiptModel.id!);

      for (MapEntry<String, double> entry in taxAmountsMap.entries) {
        String taxKey = entry.key;
        double amount = entry.value;

        List<String> parts = taxKey.split('|');
        String taxName = parts[0];
        String taxType = parts.length > 2 ? parts[2] : '';

        // Format tax name based on type
        String displayName = taxName;
        if (taxType == TaxTypeEnum.Included) {
          displayName = '$taxName (included)';
        }

        await receiptPrinterService.printTextWithWrap(
          displayName,
          rightText: amount.toStringAsFixed(2),
        );
      }

      // Add dashed line
      await receiptPrinterService.printDashedLine();

      // Add total
      await receiptPrinterService.printTextWithWrap(
        'total'.tr(),
        rightText: receiptModel.netSale?.toStringAsFixed(2) ?? '0.00',
      );

      // Add rounding
      await receiptPrinterService.printTextWithWrap(
        'rounding'.tr(),
        rightText: receiptModel.totalCashRounding?.toStringAsFixed(2) ?? '0.00',
      );

      // Add cash and change if payment type is cash
      if (receiptModel.paymentType != null &&
          receiptModel.paymentType!.toLowerCase().contains('cash')) {
        double change =
            (receiptModel.cash ?? 0) - (receiptModel.payableAmount ?? 0);
        await receiptPrinterService.printTextWithWrap(
          'cash'.tr(),
          rightText: receiptModel.cash?.toStringAsFixed(2) ?? '0.00',
        );
        await receiptPrinterService.printTextWithWrap(
          'change'.tr(),
          rightText: change.toStringAsFixed(2),
        );
        await receiptPrinterService.feed();
      }
      await receiptPrinterService.feed();
      // Add grand total
      await receiptPrinterService.printTextWithWrap(
        isRefund ? 'Refund Total' : 'grandTotal'.tr(),
        rightText: receiptModel.payableAmount?.toStringAsFixed(2) ?? '0.00',
        isBoldLeft: true,
        isBoldRight: true,
        textSizeLeft: PosTextSize.size2,
        textSizeRight: PosTextSize.size2,
      );

      // Add dashed line
      await receiptPrinterService.printDashedLine();

      await receiptPrinterService.printQRCode('$qrLink${receiptModel.id}');
      await receiptPrinterService.feed();
      await receiptPrinterService.printTextCenter('eInvoiceDesc'.tr());
      await receiptPrinterService.feed();

      // Add footer
      await FooterDesign.footer(receiptPrinterService, ref);

      // Print the receipt

      bool printSuccess = await receiptPrinterService.sendPrintData(
        onError,
        haveCut: true,
      );
      if (!printSuccess) {
        prints('❌❌❌❌❌Failed to send prints data to printer SHOULD PRINT');
      }
      await openCashDrawer(
        isIminPrinter,
        isOpenCashDrawer,
        receiptPrinterService,
        activityFrom,
        ref
      );
      return;
    }
    bool printSuccess = await receiptPrinterService.sendPrintData(
      onError,
      haveCut: false,
    );
    if (!printSuccess) {
      prints('❌❌❌❌❌Failed to send prints data to printer SHOULD NOT PRINT');
    }
    await openCashDrawer(
      isIminPrinter,
      isOpenCashDrawer,
      receiptPrinterService,
      activityFrom,
      ref
    );
    return;
  }

  static Future<void> openCashDrawer(
    bool isIminPrinter,
    bool isOpenCashDrawer,
    ReceiptPrinterService receiptPrinterService,
    String activityFrom,
    Ref ref,
  ) async {
    if (isOpenCashDrawer) {
      prints('🖨️ 🖨️ 🖨️ 🖨️ 🖨️  OPENING CASH DRAWER');
      // Reset the buffer first to avoid resending any previous data
      receiptPrinterService.resetBytes();

      // Small delay to ensure previous connection is properly closed
      // This is important for network printers that may need time between connections
      await Future.delayed(const Duration(milliseconds: 500));

      await receiptPrinterService.drawer(activityFrom: activityFrom, ref: ref);

      // Send the drawer command to the printer
      await receiptPrinterService.sendPrintData(
        (message, ipAddress) {},
        haveCut: false,
      );
    }
  }

  static String getItemSpacing(int index) {
    String numbering = "${index + 1} - ";
    int numberingLength = numbering.length;

    // Dynamic spacing: 1 base space + 3 for each additional digit
    int indexLength = (index + 1).toString().length;
    // this means every +1 index length, will add 2 more spaces
    int dynamicSpaces = 1 + ((indexLength - 1) * 2);

    return ' ' * (numberingLength + dynamicSpaces);
  }
}
