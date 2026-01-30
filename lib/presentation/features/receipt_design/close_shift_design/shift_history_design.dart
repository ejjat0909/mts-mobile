import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/data/services/receipt_printer_service.dart';
import 'package:mts/plugins/flutter_thermal_printer/utils/printer.dart';
import 'package:mts/presentation/features/receipt_design/footer_design.dart';
import 'package:mts/providers/outlet/outlet_providers.dart';
import 'package:mts/providers/staff/staff_providers.dart';

class ShiftHistoryDesign {
  static Future<void> shiftHistoryDesign({
    required String paperWidth,
    required PrinterModel printer,
    required ShiftModel shiftModel,
    required Map<String, dynamic> dataCloseShift,
    required Function(String message, String ipAddress) onError,
    required Ref ref,
    bool isOpenCashDrawer = false,
  }) async {
    final receiptPrinterService = ReceiptPrinterService(
      printer: printer,
      paperWidth: paperWidth,
    );
    await receiptPrinterService.init();

    // Add drawer open command if needed
    if (isOpenCashDrawer) {
      await receiptPrinterService.drawer(activityFrom: 'Shift History', ref:ref);
    }

    final outletNotifier = ref.read(outletProvider.notifier);
    final staffNotifier = ref.read(staffProvider.notifier);

    OutletModel? outletModel = await outletNotifier.getOutletModelById(
      shiftModel.outletId!,
    );

    UserModel? userOpenShiftModel = await staffNotifier.getUserModelByStaffId(
      shiftModel.openedBy!,
    );

    UserModel? userCloseShiftModel = await staffNotifier.getUserModelByStaffId(
      shiftModel.closedBy!,
    );

    List<dynamic> rawList = dataCloseShift['payment_type'] ?? [];

    // Convert to List<Map<String, double>>
    List<Map<String, double>> listPaymentType =
        rawList.map((item) {
          return (item as Map<String, dynamic>).map((key, value) {
            return MapEntry(
              key,
              (value is double) ? value : (value as num).toDouble(),
            );
          });
        }).toList();

    // Print title
    await receiptPrinterService.printTitle('[${"shiftReport".tr()}]');

    await receiptPrinterService.feed();

    // Add store and POS info
    await receiptPrinterService.printTextWithWrap(
      '${"store".tr()}: ${outletModel?.name ?? ""}',
    );

    await receiptPrinterService.printTextWithWrap(
      '${"pos".tr()}: ${shiftModel.posDeviceName}',
    );

    await receiptPrinterService.feed();

    // Add shift open info
    await receiptPrinterService.printTextWithWrap(
      '${"shiftOpen".tr()} ${userOpenShiftModel?.name ?? ""}',
    );

    await receiptPrinterService.printTextWithWrap(
      receiptPrinterService.formatDateTime(
        receivedDateTime: shiftModel.createdAt,
      ),
    );

    await receiptPrinterService.feed();

    // Add shift close info
    await receiptPrinterService.printTextWithWrap(
      '${"shiftClose".tr()} ${userCloseShiftModel?.name ?? ""}',
    );

    await receiptPrinterService.printTextWithWrap(
      receiptPrinterService.formatDateTime(
        receivedDateTime: shiftModel.closedAt,
      ),
    );

    // Add dashed line
    await receiptPrinterService.printDashedLine();

    await receiptPrinterService.feed();

    // Add cash drawer section
    await receiptPrinterService.printTextWithWrap('cashDrawer'.tr());

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
      rightText: dataCloseShift['pay_in'].toStringAsFixed(2),
    );

    await receiptPrinterService.printTextWithWrap(
      'payOut'.tr(),
      rightText: dataCloseShift['pay_out'].toStringAsFixed(2),
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
    await receiptPrinterService.printTextWithWrap('salesSummary'.tr());

    await receiptPrinterService.feed();

    await receiptPrinterService.printTextWithWrap(
      'grossSales'.tr(),
      rightText: dataCloseShift['gross_sales'].toStringAsFixed(2),
    );

    await receiptPrinterService.printTextWithWrap(
      '(${"afterMinusAdjustment".tr()})',
    );

    await receiptPrinterService.feed();

    await receiptPrinterService.printTextWithWrap(
      'refunds'.tr(),
      rightText: dataCloseShift['refunds'].toStringAsFixed(2),
    );

    await receiptPrinterService.printTextWithWrap(
      'discounts'.tr(),
      rightText: dataCloseShift['discounts'].toStringAsFixed(2),
    );

    await receiptPrinterService.printTextWithWrap(
      'tax'.tr(),
      rightText: dataCloseShift['taxes'].toStringAsFixed(2),
    );

    await receiptPrinterService.printTextWithWrap(
      'adjustment'.tr(),
      rightText: dataCloseShift['adjustment'].toStringAsFixed(2),
    );

    await receiptPrinterService.printTextWithWrap(
      'rounding'.tr(),
      rightText: dataCloseShift['rounding'].toStringAsFixed(2),
    );

    await receiptPrinterService.feed();

    await receiptPrinterService.printTextWithWrap(
      'netSales'.tr(),
      rightText: dataCloseShift['net_sales'].toStringAsFixed(2),
    );

    await receiptPrinterService.feed();

    // Add payment types
    if (listPaymentType.isNotEmpty) {
      for (Map<String, double> paymentType in listPaymentType) {
        String name = paymentType.keys.first;
        double amount = paymentType.values.first;

        await receiptPrinterService.printTextWithWrap(
          name,
          rightText: amount.toStringAsFixed(2),
        );
      }
    }

    // Add dashed line
    await receiptPrinterService.printDashedLine();

    // Footer
    await FooterDesign.footer(receiptPrinterService, ref);

    // Send print data
    bool printSuccess = await receiptPrinterService.sendPrintData(onError);
    if (!printSuccess) {
      throw Exception('Failed to send print data to printer');
    }

    return;
  }
}
