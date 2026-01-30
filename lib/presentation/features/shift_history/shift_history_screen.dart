import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/core/enum/printer_setting_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/services/receipt_printer_service.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/features/home/components/custom_appbar.dart';
import 'package:mts/presentation/features/shift_history/components/body.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';
import 'package:mts/providers/shift/shift_providers.dart';

class ShiftHistoryScreen extends ConsumerStatefulWidget {
  const ShiftHistoryScreen({super.key});

  @override
  ConsumerState<ShiftHistoryScreen> createState() => _ShiftHistoryScreenState();
}

class _ShiftHistoryScreenState extends ConsumerState<ShiftHistoryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        leftSidePress: () => NavigationUtils.pop(context),
        leftSideIcon: FontAwesomeIcons.arrowLeft,
        leftSideTitle: 'shiftHistory'.tr(),
        rightSideTitle: ref.watch(shiftProvider).shiftHistoryTitle,
        action: FontAwesomeIcons.print,
        actionPress: () async {
          await handlePrintShiftHistory(context);
        },
      ),
      body: const Body(),
    );
  }

  Future<void> handlePrintShiftHistory(BuildContext context) async {
    ShiftModel? shiftModel = ref.read(shiftProvider).currShiftModel;

    if (shiftModel == null) {
      prints('ERROR shiftModel is null');
      return;
    }

    Map<String, dynamic> data = {};

    if (shiftModel.saleSummaryJson != null &&
        shiftModel.saleSummaryJson!.isNotEmpty) {
      try {
        dynamic decodedData = jsonDecode(shiftModel.saleSummaryJson!);
        if (decodedData is String) {
          decodedData = jsonDecode(decodedData);
        }
        if (decodedData is Map<String, dynamic>) {
          data = decodedData;
          await printShiftHistory(
            shiftModel,
            data,
            onSuccess: () {
              ThemeSnackBar.showSnackBar(context, 'success'.tr());
            },
            onError: (message) {
              ThemeSnackBar.showSnackBar(context, message);
            },
          );
        } else {
          prints('ERROR decodedData bukan Map<String, dynamic>');
        }
      } catch (e) {
        prints('ERROR Failed to decode JSON: $e');
        ThemeSnackBar.showSnackBar(context, e.toString());
      }
    } else {
      prints('ERROR saleSummaryJson is null or empty');
    }
  }

  Future<void> printShiftHistory(
    ShiftModel shiftModel,
    Map<String, dynamic> dataMap, {
    required Function(String message) onError,
    required Function() onSuccess,
  }) async {
    /// [PRINT CLOSE SHIFT]
    List<PrinterSettingModel> listPsm =
        await ref.read(printerSettingProvider.notifier).getListPrinterSetting();

    // filter printer
    listPsm = listPsm.where((element) => element.printReceiptBills!).toList();
    if (listPsm.isNotEmpty) {
      List<String> errorIps = []; // Store all error IPs
      int completedRequests = 0; // Track number of completed requests

      for (PrinterSettingModel psm in listPsm) {
        if (psm.printReceiptBills!) {
          Future<void> printTask;

          if (psm.interface == PrinterSettingEnum.bluetooth) {
            printTask = ref
                .read(printerSettingProvider.notifier)
                .printShiftHistoryDesign(
                  dataCloseShift: dataMap,
                  isInterfaceBluetooth: true,
                  ipAddress: psm.identifierAddress ?? '',
                  paperWidth: ReceiptPrinterService.getPaperWidth(
                    psm.paperWidth,
                  ),
                  shiftModel: shiftModel,
                  onError: (message, ipAd) {
                    errorIps.add(ipAd);
                  },
                );
          } else if (psm.interface == PrinterSettingEnum.ethernet &&
              psm.identifierAddress != null) {
            printTask = ref
                .read(printerSettingProvider.notifier)
                .printShiftHistoryDesign(
                  dataCloseShift: dataMap,
                  isInterfaceBluetooth: false,
                  ipAddress: psm.identifierAddress!,
                  paperWidth: ReceiptPrinterService.getPaperWidth(
                    psm.paperWidth,
                  ),
                  shiftModel: shiftModel,
                  onError: (message, ipAd) {
                    errorIps.add(ipAd);
                  },
                );
          } else {
            continue;
          }

          await printTask; // Wait for each prints task before proceeding
          completedRequests++; // Increment after completion
        }
      }
      if (kDebugMode) {
        prints('completedRequests: $completedRequests');
        prints('Total Printers: ${listPsm.length}');
        prints('Error IPs: $errorIps');
      }
      if (completedRequests == listPsm.length && errorIps.isNotEmpty) {
        onError(errorIps.join(', '));
        return;
      }
    } else {
      onError('noPrinterFound'.tr());
      return;
    }

    onSuccess();
    return;
  }
}
