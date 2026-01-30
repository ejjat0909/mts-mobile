// import 'dart:convert';

// import 'package:easy_localization/easy_localization.dart';
// import 'package:get_it/get_it.dart';
// import 'package:mts/core/config/constants.dart';
// import 'package:mts/core/enum/item_sold_by_enum.dart';
// import 'package:mts/core/utils/log_utils.dart';
// import 'package:mts/data/models/modifier/modifier_model.dart';
// import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
// import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
// import 'package:mts/data/models/receipt/receipt_model.dart';
// import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
// import 'package:mts/data/models/user/user_model.dart';
// import 'package:mts/data/models/variant_option/variant_option_model.dart';
// import 'package:mts/data/services/receipt_printer_service.dart';
// import 'package:mts/plugins/flutter_thermal_printer/utils/printer.dart';
// import 'package:mts/presentation/features/receipt_design/footer_design.dart';
// import 'package:mts/presentation/features/receipt_design/header_design.dart';

// class RefundDesign {
//   static Future<void> refundDesign({
//     required String paperWidth,
//     required PrinterModel printer,
//     required ReceiptModel receiptModel,
//     required List<ReceiptItemModel> receiptItems,
//     required bool isOpenCashDrawer,
//     required Function(String message, String ipAdd) onError,
//     required List<PrinterSettingModel> listPrinterSettings,
//     required bool isAutomaticPrint,
//   }) async {
//     UserModel userModel =  ServiceLocator.get<UserModel>();
//     bool isIminPrinter = ReceiptPrinterService.isIminPrinter(printer);

//     final receiptPrinterService = ReceiptPrinterService(
//       printer: printer,
//       paperWidth: paperWidth,
//     );
//     await receiptPrinterService.init();

//     PrinterSettingModel? currentPrinterSetting =
//         listPrinterSettings
//             .where((ps) => ps.identifierAddress == printer.address)
//             .firstOrNull;

//     if (currentPrinterSetting == null) {
//       prints("No printer setting found for ${printer.address}");
//       return;
//     }

//     // Check if THIS specific printer should print
//     bool shouldPrint = false;
//     if (isAutomaticPrint) {
//       shouldPrint = currentPrinterSetting.automaticallyPrintReceipt == true;
//     } else {
//       shouldPrint = currentPrinterSetting.printReceiptBills == true;
//     }
//     // Open cash drawer if needed
//     if (isOpenCashDrawer) {
//       await receiptPrinterService.drawer();
//       await receiptPrinterService.sendPrintData(onError, haveCut: false);
//     }

//     if (!shouldPrint) {
//       // this means it will exit the printing service
//       if (isIminPrinter) {
//         await receiptPrinterService.resetIminPrinter();
//       } else {
//         receiptPrinterService.resetBytes();
//       }
//     }

//     // Add refund title
//     if (shouldPrint) {
//       await receiptPrinterService.printTitle('refund'.tr());

//       // Add header
//       await HeaderDesign.headerDesign(receiptPrinterService);

//       // Add receipt refund ID
//       await receiptPrinterService.printTextWithWrap(
//         "${'refundedReceipt'.tr()}: ${receiptModel.refundedReceiptId}",
//       );
//       // Add original receipt ID
//       await receiptPrinterService.printTextWithWrap(
//         "${'originalReceipt'.tr()}: ${receiptModel.showUUID}",
//       );

//       // Add order number
//       await receiptPrinterService.printTextWithWrap(
//         "${'orderNumber'.tr()}: ${receiptModel.runningNumber}",
//       );

//       // Add remarks if available
//       if (receiptModel.remarks != null) {
//         await receiptPrinterService.printTextWithWrap(
//           "${'remarks'.tr()}: ${receiptModel.remarks}",
//         );
//       }

//       // Add cashier
//       await receiptPrinterService.printTextWithWrap(
//         "${'cashier'.tr()}: ${userModel.name}",
//       );

//       // Add customer
//       await receiptPrinterService.printTextWithWrap(
//         "${'customer'.tr()}: ${receiptModel.customerName}",
//       );

//       // Add payment type
//       await receiptPrinterService.printTextWithWrap(
//         "${'paymentType'.tr()}: ${receiptModel.paymentType}",
//       );

//       // Add order option and date time
//       await receiptPrinterService.printTextWithWrap(
//         '${receiptModel.orderOption}',
//         rightText: receiptPrinterService.formatDateTime(),
//       );

//       // Add dashed line
//       await receiptPrinterService.printDashedLine();

//       await receiptPrinterService.feed();

//       /// [ receipt item here]
//       for (ReceiptItemModel receiptItem in receiptItems) {
//         List<ModifierModel> modifiers = [];
//         VariantOptionModel variantOption = VariantOptionModel();
//         List<dynamic> modifierJson = jsonDecode(receiptItem.modifiers ?? '[]');

//         if (modifierJson.isNotEmpty) {
//           modifiers = List.generate(
//             modifierJson.length,
//             (index) => ModifierModel.fromJsonReceiptItem(modifierJson[index]),
//           );
//         }

//         if (receiptItem.variants != null) {
//           dynamic variantOptionJson = jsonDecode(receiptItem.variants!);
//           variantOption = VariantOptionModel.fromJson(variantOptionJson);
//         }

//         // Add item name and price
//         await receiptPrinterService.printTextWithWrap(
//           receiptItem.name ?? '',
//           rightText: receiptItem.price!.toStringAsFixed(2),
//         );

//         // Add price and quantity
//         String? qty =
//             receiptItem.soldBy == ItemSoldByEnum.ITEM
//                 ? receiptItem.quantity?.toStringAsFixed(0)
//                 : receiptItem.quantity?.toStringAsFixed(3);

//         await receiptPrinterService.printTextWithWrap(
//           '${(receiptItem.price! / receiptItem.quantity!).toStringAsFixed(2)} x $qty',
//         );

//         // Add variants if available
//         if (variantOption.id != null) {
//           await receiptPrinterService.printTextWithWrap(
//             variantOption.name ?? '',
//           );
//         }

//         // Add modifiers if available
//         Map<String, List<ModifierOptionModel>> groupedModifiers = {};
//         for (ModifierModel modifier in modifiers) {
//           if (modifier.id != null) {
//             groupedModifiers.putIfAbsent(modifier.id!, () => []);
//             groupedModifiers[modifier.id!]!.addAll(
//               modifier.modifierOptions ?? [],
//             );
//           }
//         }

//         for (String modifierId in groupedModifiers.keys) {
//           String modifierOptionText = groupedModifiers[modifierId]!
//               .map((e) => e.name)
//               .join(', ');

//           await receiptPrinterService.printTextWithWrap(modifierOptionText);
//         }

//         // Add line feed
//         await receiptPrinterService.feed();
//       }

//       /// [receipt item until here]

//       // Add dashed line
//       await receiptPrinterService.printDashedLine();

//       // Add subtotal
//       await receiptPrinterService.printTextWithWrap(
//         'subtotal'.tr(),
//         rightText: receiptModel.grossSale!.toStringAsFixed(2),
//       );

//       // Add line feed
//       await receiptPrinterService.feed();

//       // Add adjustment
//       await receiptPrinterService.printTextWithWrap(
//         'adjustment'.tr(),
//         rightText: '-${receiptModel.adjustedPrice!.toStringAsFixed(2)}',
//       );

//       // Add discount
//       await receiptPrinterService.printTextWithWrap(
//         'discount'.tr(),
//         rightText: '-${receiptModel.totalDiscount!.toStringAsFixed(2)}',
//       );

//       // Add tax
//       await receiptPrinterService.printTextWithWrap(
//         'tax'.tr(),
//         rightText: receiptModel.totalTaxes!.toStringAsFixed(2),
//       );

//       // Add dashed line
//       await receiptPrinterService.printDashedLine();

//       // Add total
//       await receiptPrinterService.printTextWithWrap(
//         'total'.tr(),
//         rightText: receiptModel.netSale!.toStringAsFixed(2),
//       );

//       // Add line feed
//       await receiptPrinterService.feed();

//       // Add rounding
//       await receiptPrinterService.printTextWithWrap(
//         'rounding'.tr(),
//         rightText: receiptModel.totalCashRounding!.toStringAsFixed(2),
//       );

//       // Add cash and change if payment type is cash
//       if (receiptModel.paymentType!.toLowerCase().contains('cash')) {
//         double change = receiptModel.cash! - receiptModel.payableAmount!;

//         await receiptPrinterService.printTextWithWrap(
//           'cash'.tr(),
//           rightText: receiptModel.cash!.toStringAsFixed(2),
//         );

//         await receiptPrinterService.printTextWithWrap(
//           'change'.tr(),
//           rightText: change.toStringAsFixed(2),
//         );

//         // Add line feed
//         await receiptPrinterService.feed();
//       }

//       // Add grand total
//       await receiptPrinterService.printTextWithWrap(
//         'grandTotal'.tr(),
//         rightText: receiptModel.payableAmount!.toStringAsFixed(2),
//         isBoldLeft: true,
//         isBoldRight: true,
//       );

//       // Add dashed line
//       await receiptPrinterService.printDashedLine();

//       await receiptPrinterService.printQRCode('$qrLink${receiptModel.id}');
//       await receiptPrinterService.feed();
//       await receiptPrinterService.printTextCenter('eInvoiceDesc'.tr());
//       await receiptPrinterService.feed();

//       // Add footer
//       await FooterDesign.footer(receiptPrinterService);

//       // Print the receipt
//       await receiptPrinterService.sendPrintData(onError, haveCut: true);
//       return;
//     }
//     await receiptPrinterService.sendPrintData(onError, haveCut: false);
//     return;
//   }
// }
