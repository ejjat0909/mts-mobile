import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/enum/department_type_enum.dart';
import 'package:mts/core/enum/printer_setting_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/services/receipt_printer_service.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';

class PrinterJobService {
  // ✅ Simple static tracking to prevent conflicts
  static final Map<String, bool> _printerBusy = {};

  Future<void> processJobsForPrinter(
    String printerIp,
    List<Map<String, dynamic>> jobs,
    List<String> errorIps,
    String printType, {

    required PrintReceiptCacheModel printCacheModel,
    required Function(List<PrintReceiptCacheModel>) onSuccessPrintReceiptCache,
  }) async {
    // ✅ Create unique key for printer + interface combination
    String printerKey =
        '${printerIp}_${jobs.isNotEmpty ? jobs.first['psm'].interface : 'unknown'}';

    // ✅ Wait if printer is currently busy
    while (_printerBusy[printerKey] == true) {
      prints('⏳ Printer $printerKey is busy, waiting 500ms...');
      await Future.delayed(Duration(milliseconds: 100));
    }

    // ✅ Mark printer as busy
    _printerBusy[printerKey] = true;

    try {
      prints(
        '🖨️ Processing ${jobs.length} $printType jobs for printer $printerIp',
      );

      for (int i = 0; i < jobs.length; i++) {
        Map<String, dynamic> job = jobs[i];
        // data dapat dari printer setting facade impl dalam method _processPrinterJobs()
        try {
          PrinterSettingModel psm = job['psm'];
          DepartmentPrinterModel dpm = job['dpm'];
          PredefinedOrderModel? pom = job['pom'];
          List<SaleItemModel> filteredList = job['filteredList'];
          List<SaleModifierModel> listSM = job['listSM'];
          List<SaleModifierOptionModel> listSMO = job['listSMO'];
          OrderOptionModel? orderOptionModel = job['orderOptionModel'];
          SaleModel saleModel = job['saleModel'];
          Ref ref = job['ref'];

          final receiptNotifier = ref.read(receiptProvider.notifier);

          prints(
            '📄 Job ${i + 1}/${jobs.length} - Printing ${filteredList.length} $printType items to ${dpm.name}',
          );

          // ✅ Create the print task with timeout
          Future<void> printTask;

          if (psm.interface == PrinterSettingEnum.bluetooth) {
            if (printType == DepartmentTypeEnum.printVoid) {
              printTask = receiptNotifier.printVoidReceipt(
                printCacheModel: printCacheModel,
                saleModel,
                isInterfaceBluetooth: true,
                ipAddress: psm.identifierAddress ?? '',
                listSaleItems: filteredList,
                listSM: listSM,
                listSMO: listSMO,
                receivingOrderOption: orderOptionModel,
                onSuccessPrintReceiptCache: onSuccessPrintReceiptCache,
                paperWidth: ReceiptPrinterService.getPaperWidth(psm.paperWidth),
                pom: pom,
                dpm: dpm,
                onError: (message, ipAd) {
                  prints('❌ Error from ${dpm.name}: $message');
                  if (!errorIps.contains(ipAd)) {
                    errorIps.add(ipAd);
                  }
                },
              );
            } else {
              printTask = receiptNotifier.printKitchenReceipt(
                printCacheModel: printCacheModel,
                saleModel,
                listSaleItem: filteredList,
                listSM: listSM,
                listSMO: listSMO,
                receivingOrderOption: orderOptionModel,
                isinterfaceBluetooth: true,
                ipAddress: psm.identifierAddress ?? '',
                paperWidth: ReceiptPrinterService.getPaperWidth(psm.paperWidth),
                pom: pom,
                dpm: dpm,
                printerSetting: psm,
                onSuccessPrintReceiptCache: onSuccessPrintReceiptCache,
                onError: (message, ipAd) {
                  if (!errorIps.contains(ipAd)) {
                    errorIps.add(ipAd);
                  }
                },
              );
            }
          } else if (psm.interface == PrinterSettingEnum.ethernet &&
              psm.identifierAddress != null) {
            if (printType == DepartmentTypeEnum.printVoid) {
              printTask = receiptNotifier.printVoidReceipt(
                printCacheModel: printCacheModel,
                saleModel,
                listSaleItems: filteredList,
                listSM: listSM,
                listSMO: listSMO,
                receivingOrderOption: orderOptionModel,
                isInterfaceBluetooth: false,
                ipAddress: psm.identifierAddress!,
                onSuccessPrintReceiptCache: onSuccessPrintReceiptCache,
                paperWidth: ReceiptPrinterService.getPaperWidth(psm.paperWidth),
                pom: pom,
                dpm: dpm,
                onError: (message, ipAd) {
                  prints('❌ Error from ${dpm.name}: $message');
                  if (!errorIps.contains(ipAd)) {
                    errorIps.add(ipAd);
                  }
                },
              );
            } else {
              printTask = receiptNotifier.printKitchenReceipt(
                saleModel,
                printCacheModel: printCacheModel,
                listSaleItem: filteredList,
                listSM: listSM,
                listSMO: listSMO,
                receivingOrderOption: orderOptionModel,
                isinterfaceBluetooth: false,
                ipAddress: psm.identifierAddress!,
                paperWidth: ReceiptPrinterService.getPaperWidth(psm.paperWidth),
                pom: pom,
                dpm: dpm,
                printerSetting: psm,

                onSuccessPrintReceiptCache: onSuccessPrintReceiptCache,
                onError: (message, ipAd) {
                  if (!errorIps.contains(ipAd)) {
                    errorIps.add(ipAd);
                  }
                },
              );
            }
          } else {
            throw Exception('Invalid printer interface: ${psm.interface}');
          }

          // ✅ Calculate timeout dynamically based on print data size
          int itemCount = filteredList.length;
          int baseTimeoutSeconds = 5;
          int additionalSecondsPerItem = 10;
          int finalTimeout =
              baseTimeoutSeconds + (itemCount * additionalSecondsPerItem);

          prints(
            '📊 Calculated timeout: ${finalTimeout}s for $itemCount items',
          );

          // ✅ Execute with dynamic timeout
          await printTask.timeout(
            Duration(seconds: finalTimeout),
            onTimeout: () {
              String timeoutMsg = 'Print timeout after $finalTimeout seconds';
              prints('⏰ $timeoutMsg for ${dpm.name}');
              if (!errorIps.contains(printerIp)) {
                errorIps.add(printerIp);
              }
              throw TimeoutException(
                timeoutMsg,
                Duration(seconds: finalTimeout),
              );
            },
          );

          prints('✅ Completed job ${i + 1} for ${dpm.name}');

          // ✅ CRITICAL: Add delay between jobs for same printer IP
          if (i < jobs.length - 1) {
            Duration delay = getPrinterDelay(psm, dpm);
            prints(
              '⏳ Waiting ${delay.inMilliseconds}ms before next job for same printer...',
            );
            await Future.delayed(delay);
          }
        } catch (e) {
          prints('❌ Job ${i + 1} failed for printer $printerIp: $e');
          if (!errorIps.contains(printerIp)) {
            errorIps.add(printerIp);
          }
          // Continue with next job even if this one fails
        }
      }

      prints('🏁 Completed all $printType jobs for printer $printerIp');
    } finally {
      // ✅ Always mark printer as free, even if error occurs
      _printerBusy[printerKey] = false;
      prints('🔓 Released printer $printerKey');
    }
  }

  Duration getPrinterDelay(
    PrinterSettingModel psm,
    DepartmentPrinterModel dpm,
  ) {
    // Adjust based on interface type
    if (psm.interface == PrinterSettingEnum.bluetooth) {
      return Duration(milliseconds: 1500); // Bluetooth is slower
    } else if (psm.interface == PrinterSettingEnum.ethernet) {
      return Duration(milliseconds: 800); // Network is faster
    } else {
      return Duration(milliseconds: 1000); // Default
    }
  }
}
