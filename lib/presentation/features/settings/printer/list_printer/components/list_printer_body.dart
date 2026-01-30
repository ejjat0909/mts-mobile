import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/core/enum/printer_setting_enum.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/services/receipt_printer_service.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';
import 'package:mts/providers/device/device_providers.dart';
import 'package:mts/presentation/common/dialogs/theme_spinner.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/settings/printer/list_printer/components/empty_printer.dart';
import 'package:mts/presentation/features/settings/printer/list_printer/components/printer_item.dart';
import 'package:mts/providers/permission/permission_providers.dart';

class ListPrinterBody extends ConsumerStatefulWidget {
  const ListPrinterBody({super.key});

  @override
  ConsumerState<ListPrinterBody> createState() => _ListPrinterBodyState();
}

class _ListPrinterBodyState extends ConsumerState<ListPrinterBody> {
  PosDeviceModel _posDeviceModel = PosDeviceModel();

  // Future to store the printer data
  Future<List<PrinterSettingModel>?> _printersFuture = Future.value(null);

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    final device =
        await ref.read(deviceProvider.notifier).getLatestDeviceModel();
    _posDeviceModel = device ?? PosDeviceModel();

    _refreshPrinterList(_posDeviceModel);
  }

  // Method to refresh the printer list
  Future<void> _refreshPrinterList(PosDeviceModel posDeviceModel) async {
    setState(() {
      _printersFuture = ref
          .read(printerSettingProvider.notifier)
          .uiGetAllPrinter(posDeviceModel);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasPermissionSettings =
        ref.read(permissionProvider.notifier).hasChangeSettingsPermission();

    // Check if the user has permission to change settings (you need to implement this logic)
    return FutureBuilder(
      future: _printersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: ThemeSpinner.spinner());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('has error'));
        }

        if (snapshot.hasData) {
          final listPrinter = snapshot.data;

          if (listPrinter!.isNotEmpty) {
            return Column(
              children: [
                ButtonTertiary(
                  onPressed: () {
                    // filter list printer just isDeviceSame
                    final filteredListPrinter =
                        listPrinter
                            .where(
                              (element) =>
                                  element.isPosDeviceSame != null &&
                                  element.isPosDeviceSame!,
                            )
                            .toList();
                    testAllPrinter(filteredListPrinter);
                  },
                  text: 'Test All Printers',
                ),
                Space(20.h),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: RefreshIndicator(
                      onRefresh: () {
                        return _refreshPrinterList(_posDeviceModel);
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount:
                            listPrinter.isNotEmpty ? listPrinter.length : 0,
                        itemBuilder: (BuildContext context, int index) {
                          return PrinterItem(
                            printerSettingModel: listPrinter[index],
                            currentPosDevice: _posDeviceModel,
                            hasSettingPermission: hasPermissionSettings,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return RefreshIndicator(
              onRefresh: () {
                return _refreshPrinterList(_posDeviceModel);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const Center(child: EmptyPrinter()),
                  ),
                ],
              ),
            );
          }
        }
        return const Center(child: Text('error'));
      },
    );
  }

  Future<void> testAllPrinter(List<PrinterSettingModel> listPrinter) async {
    if (kDebugMode) {
      prints('PRINTINGG...........');
    }

    if (listPrinter.isNotEmpty) {
      List<String> errorIps = []; // Store all error IPs
      int completedRequests = 0; // Track number of completed requests

      for (int i = 0; i < listPrinter.length; i++) {
        Future<void> printTask;
        PrinterSettingModel psm = listPrinter[i];

        printTask = ref
            .read(printerSettingProvider.notifier)
            .printTest(
              ipAddress: psm.identifierAddress!,
              isInterfaceBluetooth:
                  psm.interface == PrinterSettingEnum.bluetooth,
              paperWidth: ReceiptPrinterService.getPaperWidth(psm.paperWidth!),
           
              onError: (message, ip) {
                prints('IP ADDRESS ERROR $ip');
                if (!errorIps.contains(ip)) {
                  errorIps.add(ip);
                }
              },
            );

        // Increment completed requests
        await printTask;
        completedRequests++;
      }
      if (completedRequests == listPrinter.length) {
        if (errorIps.isNotEmpty) {
          if (kDebugMode) {
            prints(
              'TEST ALL PRINTER.All printers have been attempted save order dialogue, but some failed.',
            );
          }

          DialogUtils.printerErrorDialogue(
            context,
            'connectionTimeout'.tr(),
            errorIps.join(', '),
            null,
          );
        } else {
          prints(
            'TEST ALL PRINTER. All printers have been attempted successfully',
          );
        }
      }
    } else {}
  }
}
