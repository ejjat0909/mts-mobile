import 'package:easy_localization/easy_localization.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/services/receipt_printer_service.dart';
import 'package:mts/plugins/flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:mts/plugins/flutter_thermal_printer/utils/printer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';
import 'package:mts/providers/printing_log/printing_log_providers.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/modifier_option/modifier_option_providers.dart';

class KitchenOrderDesignOrder {
  // Unified kitchen order design implementation
  static Future<void> kitchenOrderDesign({
    required PrinterModel printer,
    required String paperWidth,
    required int orderNumber,
    required String tableNumber,
    required SaleModel saleModel,
    required List<SaleItemModel> listSaleItems,
    required List<SaleModifierModel> listSM,
    required List<SaleModifierOptionModel> listSMO,
    required OrderOptionModel? orderOptionModel,
    required DepartmentPrinterModel dpm,
    required Function(String message, String ipAdd) onError,
    String reason = 'Print Order',
    required PrinterSettingModel printerSetting,
    required Ref ref,
  }) async {
    // Use Riverpod providers via Ref
    final featureCompNotifier = ref.read(featureCompanyProvider.notifier);
    final isFeatureActive = featureCompNotifier.isDepartmentPrintersActive();

    if (!isFeatureActive) {
      return;
    }
    // Create receipt printer service instance
    final receiptPrinterService = ReceiptPrinterService(
      printer: printer,
      paperWidth: paperWidth,
    );
    await receiptPrinterService.init();

    // Add kitchen name
    await receiptPrinterService.printTitle(dpm.name ?? ''.tr());

    await receiptPrinterService.feed();
    // Add order number
    await receiptPrinterService.printTitle('orderNumber'.tr(), bold: false);
    await receiptPrinterService.feed();
    // Add order number value
    await receiptPrinterService.printTitle(
      orderNumber.toString(),
      textSize: PosTextSize.size3,
    );

    // Add dashed line
    await receiptPrinterService.printDashedLine();

    // Add order option if available
    if (orderOptionModel != null) {
      await receiptPrinterService.printTextWithWrap(
        orderOptionModel.name ?? '',
      );
    }

    // add table name if available
    if (saleModel.tableId != null &&
        saleModel.tableName != null &&
        saleModel.tableName!.isNotEmpty) {
      await receiptPrinterService.printTextWithWrap(
        '${saleModel.tableName}',
        // '${'table'.tr()}: ${saleModel.tableName}',
      );
    }

    await receiptPrinterService.printTextWithWrap(
      "${'orderFor'.tr()}: $tableNumber",
    );
    if (saleModel.remarks != null && saleModel.remarks!.isNotEmpty) {
      await receiptPrinterService.printTextWithWrap(
        "${'remarks'.tr()}: ${saleModel.remarks}",
      );
    }

    // Add dashed line and spacing
    await receiptPrinterService.printDashedLine();
    await receiptPrinterService.feed();

    // Process sale items
    for (SaleItemModel saleItem in listSaleItems) {
      final saleItemMap = await getItem(
        saleItem,
        listSaleItems,
        listSM,
        listSMO,
        ref,
      );

      final itemModel = saleItemMap['itemModel'] as ItemModel?;
      final allModifierOptionName =
          saleItemMap['allModifierOptionName'] as String;
      final variantOptionName = saleItemMap['variantOptionName'] as String?;
      final siModel = saleItemMap['saleItemModel'] as SaleItemModel;

      // Format quantity based on sold by type
      final quantity =
          siModel.soldBy == ItemSoldByEnum.item
              ? siModel.quantity?.toStringAsFixed(0)
              : siModel.quantity?.toStringAsFixed(3);

      await receiptPrinterService.printTextWithWrap(
        '$quantity x ${itemModel?.name}',
        textSizeLeft: PosTextSize.size2,
      );

      // Add variant if available
      if (variantOptionName != null) {
        await receiptPrinterService.printTextWithWrap(
          variantOptionName,
          textSizeLeft: PosTextSize.size2,
        );
      }

      // Add modifier options if available
      if (allModifierOptionName.isNotEmpty) {
        await receiptPrinterService.printTextWithWrap(
          allModifierOptionName,
          textSizeLeft: PosTextSize.size2,
        );
      }

      // Add comments if available
      if (saleItem.comments != null && saleItem.comments!.isNotEmpty) {
        await receiptPrinterService.printTextWithWrap(saleItem.comments!);
      }

      // Add spacing between items
      await receiptPrinterService.feed();
    }

    // Add footer

    await receiptPrinterService.printDashedLine();
    await receiptPrinterService.printTextCenter(
      receiptPrinterService.formatDateTime(),
    );

    // Print the receipt
    bool printSuccess = await receiptPrinterService.sendPrintData(onError);
    if (!printSuccess) {
      throw Exception('Failed to send print data to printer');
    }

    // update print log
    String logReason =
        'Print Order ${saleModel.name} | Order Number: $orderNumber ';
    await ref
        .read(printingLogProvider.notifier)
        .createAndInsertPrintingLogModel(printerSetting, logReason);
    return;
  }

  static Future<Map<String, dynamic>> getItem(
    SaleItemModel saleItemModel,
    List<SaleItemModel> listSaleItems,
    List<SaleModifierModel> listSM,
    List<SaleModifierOptionModel> listSMO,
    Ref ref,
  ) async {
    // Get all modifier IDs for this sale item
    final listSMId =
        listSM
            .where((element) => element.saleItemId == saleItemModel.id)
            .map((e) => e.id!)
            .toList();

    // Get all modifier option IDs
    final modifierOptionIds =
        listSMO
            .where((element) => listSMId.contains(element.saleModifierId))
            .map((e) => e.modifierOptionId!)
            .toList();

    // Find the matching sale item model
    final usedSaleItemModel = listSaleItems.firstWhere(
      (e) =>
          e.id == saleItemModel.id &&
          e.variantOptionId == saleItemModel.variantOptionId &&
          e.comments == saleItemModel.comments &&
          e.updatedAt == saleItemModel.updatedAt &&
          e.isVoided == saleItemModel.isVoided,
      orElse: () => SaleItemModel(),
    );

    // Get item details
    final itemId = usedSaleItemModel.itemId!;
    final variantOptionId = usedSaleItemModel.variantOptionId;

    // Fetch related data via providers
    final itemNotifier = ref.read(itemProvider.notifier);
    final modifierOptionNotifier = ref.read(modifierOptionProvider.notifier);

    final itemModel = await itemNotifier.getItemModelById(itemId);
    final allModifierOptionName = modifierOptionNotifier
        .getModifierOptionNameFromListIds(modifierOptionIds);
    final variantOptionModel = itemNotifier.getVariantOptionModelById(
      variantOptionId,
      itemId,
    );

    return {
      'itemModel': itemModel,
      'allModifierOptionName': allModifierOptionName,
      'variantOptionName': variantOptionModel?.name,
      'saleItemModel': usedSaleItemModel,
    };
  }
}
