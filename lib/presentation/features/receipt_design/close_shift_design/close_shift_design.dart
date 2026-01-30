import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/core/enum/cash_management_type_enum.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/data/models/cash_management/cash_management_model.dart';
import 'package:mts/data/models/modifier/modifier_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';
import 'package:mts/data/services/receipt_printer_service.dart';
import 'package:mts/plugins/flutter_thermal_printer/utils/printer.dart';
import 'package:mts/providers/cash_management/cash_management_providers.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/shift/shift_providers.dart';

/// Class responsible for generating close shift receipt designs
class CloseShiftDesign {
  /// Generate a close shift receipt design.
  ///
  /// This design includes the following sections:
  /// 1. Shift open and close information
  /// 2. Cash drawer section
  /// 3. Sales summary section
  /// 4. Payment types
  /// 5. Items sold by item
  /// 6. Items sold by measurement
  /// 7. Pay in Pay out
  ///
  /// The design is generated based on the provided `ShiftModel` and
  /// `Map<String, dynamic>` of data.
  ///
  /// The generated design is a list of bytes that can be sent to the printer.
  ///
  static Future<void> closeShiftDesign({
    required String paperWidth,
    required PrinterModel printer,
    required ShiftModel shiftModel,
    required Map<String, dynamic> dataCloseShift,
    required Function(String message, String ipAddress) onError,
    required Ref ref,
    bool isOpenCashDrawer = false,
  }) async {
    final cashManagementNotifier = ref.read(cashManagementProvider.notifier);
    final permissionNotifier = ref.read(permissionProvider.notifier);
    final hasPermission = permissionNotifier.hasViewShiftReportsPermission();
    final shiftState = ref.read(shiftProvider);
    final isPrintItem = shiftState.isPrintItem;
    List<CashManagementModel> listCMM =
        await cashManagementNotifier.getCashManagementListByShift();
    final receiptPrinterService = ReceiptPrinterService(
      printer: printer,
      paperWidth: paperWidth,
    );
    await receiptPrinterService.init();

    // Add drawer open command if needed
    if (isOpenCashDrawer) {
      await receiptPrinterService.drawer(activityFrom: 'Close Shift', ref: ref);
    }

    OutletModel outletModel = GetIt.instance<OutletModel>();
    PosDeviceModel deviceModel = GetIt.instance<PosDeviceModel>();
    UserModel userModel = GetIt.instance<UserModel>();
    List<PaymentTypeModel> listPaymentType =
        dataCloseShift['listPaymentTypeModels'] as List<PaymentTypeModel>;

    List<ReceiptModel> listReceiptModel =
        dataCloseShift['listReceiptModels'] as List<ReceiptModel>;

    List<ReceiptItemModel> listReceiptItemModelNotRefunded =
        dataCloseShift['listReceiptItemModelsNotRefunded']
            as List<ReceiptItemModel>;

    // Add title
    await receiptPrinterService.printTitle('[${"shiftReport".tr()}]');

    await receiptPrinterService.feed();

    // Add store and POS info
    await receiptPrinterService.printTextWithWrap(
      '${"store".tr()}: ${outletModel.name}',
    );
    await receiptPrinterService.printTextWithWrap(
      '${"pos".tr()}: ${deviceModel.name}',
    );

    await receiptPrinterService.feed();

    // Add shift open info
    await receiptPrinterService.printTextWithWrap(
      '${"shiftOpen".tr()} ${userModel.name}',
    );
    await receiptPrinterService.printTextWithWrap(
      receiptPrinterService.formatDateTime(
        receivedDateTime: shiftModel.createdAt,
      ),
    );

    await receiptPrinterService.feed();

    // Add shift close info
    await receiptPrinterService.printTextWithWrap(
      '${"shiftClose".tr()} ${userModel.name}',
    );
    await receiptPrinterService.printTextWithWrap(
      receiptPrinterService.formatDateTime(),
    );

    // Add dashed line
    await receiptPrinterService.printDashedLine();

    await receiptPrinterService.feed();

    // Add cash drawer section
    await receiptPrinterService.printTextWithWrap(
      'cashDrawer'.tr(),
      isBoldLeft: true,
    );
    await receiptPrinterService.feed();

    await receiptPrinterService.printTextWithWrap(
      'startingCash'.tr(),
      rightText: shiftModel.startingCash!.toStringAsFixed(2),
    );
    await receiptPrinterService.feed();

    await receiptPrinterService.printTextWithWrap(
      'cashPayment'.tr(),
      rightText:
          shiftModel.cashPayments?.toStringAsFixed(2) ?? 0.toStringAsFixed(2),
    );
    await receiptPrinterService.printTextWithWrap(
      'cashRefund'.tr(),
      rightText:
          shiftModel.cashRefunds?.toStringAsFixed(2) ?? 0.toStringAsFixed(2),
    );
    await receiptPrinterService.printTextWithWrap(
      'payIn'.tr(),
      rightText: dataCloseShift['totalPayIn'],
    );
    await receiptPrinterService.printTextWithWrap(
      'payOut'.tr(),
      rightText: dataCloseShift['totalPayOut'],
    );
    await receiptPrinterService.printTextWithWrap(
      'actualCashAmount'.tr(),
      rightText: shiftModel.actualCash!.toStringAsFixed(2),
    );
    await receiptPrinterService.printTextWithWrap(
      'difference'.tr(),
      rightText: shiftModel.shortCash!.toStringAsFixed(2),
    );
    // Add dashed line
    await receiptPrinterService.printDashedLine();

    await receiptPrinterService.feed();

    // Add sales summary section
    await receiptPrinterService.printTextWithWrap(
      'salesSummary'.tr(),
      isBoldLeft: true,
    );
    await receiptPrinterService.feed();

    await receiptPrinterService.printTextWithWrap(
      'grossSales'.tr(),
      rightText: hasPermission ? dataCloseShift['totalGrossSales'] : '---',
    );
    await receiptPrinterService.printTextWithWrap(
      '(${"afterMinusAdjustment".tr()})',
    );
    await receiptPrinterService.feed();

    await receiptPrinterService.printTextWithWrap(
      'refunds'.tr(),
      rightText: hasPermission ? dataCloseShift['totalRefunds'] : '---',
    );
    await receiptPrinterService.printTextWithWrap(
      'discounts'.tr(),
      rightText: hasPermission ? dataCloseShift['totalDiscount'] : '---',
    );
    await receiptPrinterService.printTextWithWrap(
      'tax'.tr(),
      rightText: hasPermission ? dataCloseShift['totalTaxes'] : '---',
    );
    await receiptPrinterService.printTextWithWrap(
      'adjustment'.tr(),
      rightText: hasPermission ? dataCloseShift['totalAdjustment'] : '---',
    );
    await receiptPrinterService.printTextWithWrap(
      'rounding'.tr(),
      rightText: dataCloseShift['totalCashRounding'],
    );

    await receiptPrinterService.feed();

    await receiptPrinterService.printTextWithWrap(
      'netSales'.tr(),
      rightText: hasPermission ? dataCloseShift['totalNetSales'] : '---',
    );
    await receiptPrinterService.feed();

    // loop for payment method
    Map<String, dynamic> paymentTypeAmounts = {};
    for (PaymentTypeModel paymentType in listPaymentType) {
      paymentTypeAmounts[paymentType.name ?? ''] = 0.00;
    }

    // Sum the netsales amounts for each payment type from the receipts
    for (ReceiptModel receipt in listReceiptModel) {
      if (receipt.paymentType != null &&
          paymentTypeAmounts.containsKey(receipt.paymentType)) {
        paymentTypeAmounts[receipt.paymentType ?? ''] =
            (paymentTypeAmounts[receipt.paymentType] ?? 0.0) +
            (receipt.netSale ?? 0.0);
      }
    }

    // Add payment types
    if (listPaymentType.isNotEmpty) {
      for (PaymentTypeModel paymentType in listPaymentType) {
        final paymentName = paymentType.name ?? '';
        double amount = paymentTypeAmounts[paymentName] ?? 0.00;

        final isCashPayment = paymentName.toLowerCase().contains('cash');
        // Determine if we should show the amount (always for cash, or if has permission)
        final shouldShowAmount = isCashPayment || hasPermission;

        await receiptPrinterService.printTextWithWrap(
          paymentType.name ?? '',
          rightText: shouldShowAmount ? amount.toStringAsFixed(2) : '---',
        );
      }
    }

    // Add dashed line
    await receiptPrinterService.printDashedLine();

    /// [payment methods until here]
    ///
    /// [start of items sold by item and measurement]

    if (hasPermission) {
      if (isPrintItem) {
        await receiptPrinterService.feed();

        final listItemSoldByItem =
            listReceiptItemModelNotRefunded
                .where((element) => element.soldBy == ItemSoldByEnum.item)
                .toList();

        final listItemSoldByMeasurement =
            listReceiptItemModelNotRefunded
                .where(
                  (element) => element.soldBy == ItemSoldByEnum.measurement,
                )
                .toList();

        // for item sold by item
        if (listItemSoldByItem.isNotEmpty) {
          await receiptPrinterService.printTextWithWrap(
            '${"itemSoldByItem".tr()} (${dataCloseShift['totalReceiptItemsNotRefundedSoldByItem']})',
            isBoldLeft: true,
          );
          await receiptPrinterService.feed();

          /// loop for [items sold by item]
          await printConsolidatedReceiptItems(
            receiptPrinterService,
            listItemSoldByItem,
          );
        }

        // Add dashed line
        await receiptPrinterService.printDashedLine();
        await receiptPrinterService.feed();

        // for item sold by measurement
        if (listItemSoldByMeasurement.isNotEmpty) {
          await receiptPrinterService.printTextWithWrap(
            '${"itemSoldByMeasurement".tr()} (${dataCloseShift['totalReceiptItemsNotRefundedSoldByMeasurement']})',
            isBoldLeft: true,
          );
          await receiptPrinterService.feed();

          /// loop for [items sold by measurement]
          await printConsolidatedReceiptItems(
            receiptPrinterService,
            listItemSoldByMeasurement,
          );
        }
      }
    }

    // Add dashed line
    await receiptPrinterService.printDashedLine();
    await receiptPrinterService.feed();

    if (listCMM.isNotEmpty) {
      await receiptPrinterService.printTextWithWrap(
        "cashManagement".tr(),
        isBoldLeft: true,
      );
      await receiptPrinterService.feed();
      await printConsolidatedCashManagement(listCMM, receiptPrinterService);
      // Add dashed line
      await receiptPrinterService.printDashedLine();
      await receiptPrinterService.feed();
    }

    // Footer
    await receiptPrinterService.printTextCenter(
      receiptPrinterService.formatDateTime(),
    );

    // Print the receipt if printer is provided
    bool printSuccess = await receiptPrinterService.sendPrintData(onError);
    if (!printSuccess) {
      throw Exception('Failed to send print data to printer');
    }

    return;
  }

  static Future<void> printConsolidatedCashManagement(
    List<CashManagementModel> listCMM,
    ReceiptPrinterService receiptPrinterService,
  ) async {
    if (listCMM.isEmpty) return;

    for (CashManagementModel cmm in listCMM) {
      String date = receiptPrinterService.formatDateTime(
        receivedDateTime: cmm.createdAt,
      );

      double totalAmount = cmm.amount ?? 0;
      String comment =
          cmm.comment != null
              ? (cmm.comment!.isEmpty ? 'No Comment' : cmm.comment!)
              : 'No Comment';

      String rightText =
          cmm.type == CashManagementTypeEnum.payIn
              ? "+${'RM'.tr(args: [totalAmount.toStringAsFixed(2)])}"
              : "-${'RM'.tr(args: [totalAmount.toStringAsFixed(2)])}";

      await receiptPrinterService.printTextWithWrap(date, rightText: rightText);
      await receiptPrinterService.printTextWithWrap(comment);

      await receiptPrinterService.feed();
    }
  }

  /// Prints a list of consolidated receipt items
  ///
  /// This function takes a list of receipt items and groups them by name, variant,
  /// and modifier. It then prints the main item with consolidated quantity,
  /// followed by the variant option and modifiers if they exist. The printout is
  /// formatted into a table with left and right aligned columns.
  static Future<void> printConsolidatedReceiptItems(
    ReceiptPrinterService receiptPrinterService,
    List<ReceiptItemModel> listReceiptItemModel,
  ) async {
    if (listReceiptItemModel.isEmpty) return;

    // Step 1: Group items by name, variant, and modifier
    Map<String, ReceiptItemModel> groupedItems = {};

    for (ReceiptItemModel receiptItem in listReceiptItemModel) {
      // Parse modifiers and variant option
      List<ModifierModel> modifiers = [];
      VariantOptionModel variantOption = VariantOptionModel();

      if (receiptItem.modifiers != null && receiptItem.modifiers!.isNotEmpty) {
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

      // Generate a unique key for grouping based on name, variant, and modifiers
      String key =
          '${receiptItem.name}_${variantOption.id}_${modifiers.map((mod) => mod.id).join("_")}';

      // If key already exists, increment the quantity
      if (groupedItems.containsKey(key)) {
        groupedItems[key]!.quantity =
            (groupedItems[key]!.quantity ?? 0) + (receiptItem.quantity ?? 0);
      } else {
        groupedItems[key] = receiptItem;
      }
    }

    // Step 2: Sort grouped items by name in alphabetical order
    List<ReceiptItemModel> sortedItems =
        groupedItems.values.toList()
          ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));

    // Step 3: Print consolidated items
    for (ReceiptItemModel receiptItem in sortedItems) {
      List<ModifierModel> modifiers = [];
      VariantOptionModel variantOption = VariantOptionModel();

      // Parse modifiers and variant option for printing
      if (receiptItem.modifiers != null && receiptItem.modifiers!.isNotEmpty) {
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

      // Print the main item with consolidated quantity
      String? qty =
          receiptItem.soldBy == ItemSoldByEnum.item
              ? receiptItem.quantity?.toStringAsFixed(0)
              : receiptItem.quantity?.toStringAsFixed(3);
      await receiptPrinterService.printTextWithWrap(
        '${receiptItem.name ?? ""} x ${qty ?? ""}',
        rightText: receiptItem.price?.toStringAsFixed(2) ?? '0.00',
      );

      // Print variant option if exists
      if (variantOption.id != null) {
        await receiptPrinterService.printTextWithWrap(variantOption.name ?? '');
      }

      // Group and print modifiers
      Map<String, List<ModifierOptionModel>> groupedModifiers = {};

      // The options are already loaded by the fromJsonReceiptItem method
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
        String modifierOptionsText = groupedModifiers[modifierId]!
            .map((option) => option.name)
            .join(',');

        await receiptPrinterService.printTextWithWrap(modifierOptionsText);
      }

      await receiptPrinterService.feed();
    }
  }
}
