import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/enum/department_type_enum.dart';
import 'package:mts/core/enum/print_cache_status_enum.dart';
import 'package:mts/core/enum/printer_setting_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/services/printer_job_service.dart';
// import 'package:mts/data/models/printer_setting/printer_setting_list_response_model.dart';
import 'package:mts/data/services/receipt_printer_service.dart';
import 'package:mts/domain/repositories/local/printer_setting_repository.dart';
import 'package:mts/plugins/flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:mts/plugins/flutter_thermal_printer/utils/printer.dart';
import 'package:mts/presentation/features/receipt_design/close_shift_design/shift_history_design.dart';
import 'package:mts/presentation/features/receipt_design/open_cash_drawer_design.dart';
import 'package:mts/presentation/features/receipt_design/test_print/test_print.dart';
import 'package:mts/providers/department_printer/department_printer_providers.dart';
import 'package:mts/providers/device/device_providers.dart';
import 'package:mts/providers/printer_setting/printer_setting_state.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/receipt_printer_utils.dart';
import 'package:mts/data/models/printer_setting/printer_setting_list_response_model.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:mts/domain/repositories/local/print_receipt_cache_repository.dart';
import 'package:mts/domain/repositories/local/sale_repository.dart';
import 'package:mts/domain/repositories/remote/printer_setting_repository.dart';
import 'package:mts/presentation/features/receipt_design/close_shift_design/close_shift_design.dart';
import 'package:mts/presentation/features/receipt_design/kitchen_order_design/kitchen_order_design.dart';
import 'package:mts/presentation/features/receipt_design/sales_design/sales_design_print.dart';
import 'package:mts/presentation/features/receipt_design/void_design/void_design.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';

/// StateNotifier for PrinterSetting domain
///
/// Migrated from: printer_setting_facade_impl.dart
///
class PrinterSettingNotifier extends StateNotifier<PrinterSettingState> {
  final LocalPrinterSettingRepository _localRepository;
  final PrinterSettingRepository _remoteRepository;
  final IWebService _webService;
  final LocalPrintReceiptCacheRepository _localPrintReceiptCacheRepository;
  final Ref _ref;

  PrinterSettingNotifier({
    required LocalPrinterSettingRepository localRepository,
    required LocalSaleRepository localSaleRepository,
    required PrinterSettingRepository remoteRepository,
    required IWebService webService,
    required LocalPrintReceiptCacheRepository localPrintReceiptCacheRepository,
    required Ref ref,
  }) : _localRepository = localRepository,
       _localPrintReceiptCacheRepository = localPrintReceiptCacheRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _ref = ref,
       super(const PrinterSettingState());

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<PrinterSettingModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Get all items from local storage
  Future<List<PrinterSettingModel>> getListPrinterSettingModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListPrinterSetting();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<PrinterSettingModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete all items from local storage
  Future<bool> deleteAll() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteAll();

      if (result) {
        state = state.copyWith(items: [], itemsFromHive: []);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete a single item by ID
  Future<int> delete(String id, {bool isInsertToPending = true}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.delete(
        id,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Find an item by its ID
  Future<PrinterSettingModel?> getPrinterSettingModelById(String itemId) async {
    try {
      final items = await _localRepository.getListPrinterSetting();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => PrinterSettingModel(),
        );
        return item.id != null ? item : null;
      } catch (e) {
        return null;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<PrinterSettingModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.replaceAllData(
        newData,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        state = state.copyWith(items: newData);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Upsert bulk items to Hive box without replacing all items
  Future<bool> upsertBulk(
    List<PrinterSettingModel> list, {
    bool isInsertToPending = true,
    bool isQueue = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Internal helper to load items and update state
  Future<void> _loadItems() async {
    try {
      final items = await _localRepository.getListPrinterSetting();

      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Get list of printer settings (optionally filtered by outlet)
  Future<List<PrinterSettingModel>> getListPrinterSetting({
    bool isByOutlet = false,
  }) async {
    try {
      return await _localRepository.getListPrinterSetting(
        isByOutlet: isByOutlet,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get all printers with device matching information for UI
  Future<List<PrinterSettingModel>> uiGetAllPrinter(
    PosDeviceModel currentPosDevice,
  ) async {
    final deviceProvider = ServiceLocator.get<DeviceNotifier>();

    List<PrinterSettingModel> listPrinter = await getListPrinterSetting(
      isByOutlet: true,
    );
    if (listPrinter.isNotEmpty) {
      for (PrinterSettingModel printer in listPrinter) {
        PosDeviceModel? posFromPrinter = await deviceProvider
            .getDeviceModelById(printer.posDeviceId ?? '');
        if (posFromPrinter == null || posFromPrinter.id == null) {
          printer.isPosDeviceSame = false;
        } else {
          printer.isPosDeviceSame = currentPosDevice.id == posFromPrinter.id;
          printer.posDeviceName = posFromPrinter.name;
        }
      }
    }
    return listPrinter;
  }

  /// Open cash drawer manually for all configured printers
  Future<void> openCashDrawerManually(
    Function(String) onError, {
    required String activityFrom,
  }) async {
    List<PrinterSettingModel> listPsm = await getListPrinterSetting();

    // loop for all printers
    if (listPsm.isNotEmpty) {
      List<String> errorIps = [];
      int completedTask = 0;
      for (PrinterSettingModel psm in listPsm) {
        Future<void> printTask;
        prints('Current ip ${psm.identifierAddress}');
        if (psm.interface == PrinterSettingEnum.bluetooth) {
          prints('IS BLUETOOTH');
          printTask = _openCashDrawerWithSettings(
            psm,
            isInterfaceBluetooth: true,
            activityFrom: activityFrom,
            onError: (message, ipAd) {
              if (!errorIps.contains(ipAd)) {
                errorIps.add(ipAd);
              }
            },
          );
        } else if (psm.interface == PrinterSettingEnum.ethernet &&
            psm.identifierAddress != null) {
          printTask = _openCashDrawerWithSettings(
            psm,
            isInterfaceBluetooth: false,
            activityFrom: activityFrom,
            onError: (message, ipAd) {
              if (!errorIps.contains(ipAd)) {
                errorIps.add(ipAd);
              }
            },
          );
        } else {
          continue;
        }
        await printTask;
        completedTask++;
      }
      if (completedTask == listPsm.length) {
        if (errorIps.isNotEmpty) {
          prints('All printers have been attempted, but some failed.');
          onError("${errorIps.join(', ')} ${'isOffline'.tr()}");
        } else {
          prints('All printers have been attempted successfully.');
          //  onSuccess();
        }
      } else {
        // onSuccess();
        return;
      }
    } else {
      // use on error because open cash drawer
      onError('Printer not found');
      return;
    }
  }

  /// Helper method to open cash drawer with specific printer settings
  Future<void> _openCashDrawerWithSettings(
    PrinterSettingModel printerSetting, {
    required bool isInterfaceBluetooth,
    required String activityFrom,
    required Function(String message, String ipAddress) onError,
  }) async {
    String ipAddress = printerSetting.identifierAddress!;
    FlutterThermalPrinter thermalPrinter = FlutterThermalPrinter.instance;

    List<PrinterModel> printers = [];

    if (isInterfaceBluetooth) {
      try {
        // Start scanning for printers
        await thermalPrinter.getPrinters(
          connectionTypes: [ConnectionTypeEnum.USB, ConnectionTypeEnum.BLE],
        );

        // Listen for available printers
        thermalPrinter.devicesStream.listen((List<PrinterModel> event) {
          printers = event;
        });

        // Wait for printers to be detected
        await Future.delayed(Duration(milliseconds: 150));

        PrinterModel? targetDevice;
        for (PrinterModel device in printers) {
          if (device.address == ipAddress) {
            targetDevice = device;
            break;
          }
        }

        if (targetDevice == null) {
          prints("Device with Cash DRAWER not found");
          onError(
            'Device with Cash DRAWER not found',
            'Some printers did not connect to cash drawer',
          );
          return;
        }

        bool? isConnected = targetDevice.isConnected;
        bool isIminPrinter = ReceiptPrinterService.isIminPrinter(targetDevice);
        bool isUsbPrinter =
            targetDevice.connectionType == ConnectionTypeEnum.USB;

        prints(
          'OpenCashDrawer - Device: ${targetDevice.name}, Type: ${targetDevice.connectionType}, Connected: $isConnected, IsImin: $isIminPrinter',
        );

        if (isIminPrinter) {
          prints('IS IMIN PRINTER');
          await OpenCashDrawerDesign.openCashDrawer(
            printer: targetDevice,
            onError: onError,
            activityFrom: activityFrom,
            customCommand: printerSetting.customCdCommand,
            ref: _ref,
          );
        } else if (isUsbPrinter) {
          // USB printers - handle connection differently
          prints('IS USB PRINTER FOR CASH DRAWER');
          if (isConnected == true) {
            await OpenCashDrawerDesign.openCashDrawer(
              printer: targetDevice,
              onError: onError,
              activityFrom: activityFrom,
              customCommand: printerSetting.customCdCommand,
              ref: _ref,
            );
          } else {
            try {
              await thermalPrinter.connect(targetDevice);
              await Future.delayed(Duration(milliseconds: 500));
              await OpenCashDrawerDesign.openCashDrawer(
                printer: targetDevice,
                onError: onError,
                activityFrom: activityFrom,
                customCommand: printerSetting.customCdCommand,
                ref: _ref,
              );
            } catch (e) {
              prints("Error connecting to USB printer for cash drawer: $e");
              onError('Error connecting to USB printer', ipAddress);
            }
          }
        } else {
          // Bluetooth printers
          if (isConnected == true) {
            await OpenCashDrawerDesign.openCashDrawer(
              printer: targetDevice,
              onError: onError,
              activityFrom: activityFrom,
              ref: _ref,
              customCommand: printerSetting.customCdCommand,
            );
          } else {
            await thermalPrinter.connect(targetDevice);
            await Future.delayed(Duration(milliseconds: 500));
            await OpenCashDrawerDesign.openCashDrawer(
              printer: targetDevice,
              onError: onError,
              activityFrom: activityFrom,
              customCommand: printerSetting.customCdCommand,
              ref: _ref,
            );
          }
        }
      } catch (e) {
        prints("Error during openCashDrawer execution: $e");
      }
    } else {
      // Create a network printer instance
      final networkPrinter = PrinterModel(
        address: ipAddress,
        name: 'Network PrinterModel',
        connectionType: ConnectionTypeEnum.NETWORK,
      );

      try {
        // Call the unified method which handles the printing internally
        await OpenCashDrawerDesign.openCashDrawer(
          printer: networkPrinter,
          onError: onError,
          activityFrom: activityFrom,
          customCommand: printerSetting.customCdCommand,
          ref: _ref,
        );
      } on Exception catch (e) {
        prints('Error during network printing: $e');
        onError('errorConnectingToDevice'.tr(), ipAddress);
      }
    }
  }

  Future<void> onHandlePrintVoidAndKitchen({
    required Function() onSuccess,
    required Function(String message, String ipAdd) onError,

    required String? departmentType,
    required Function(List<PrintReceiptCacheModel>) onSuccessPrintReceiptCache,
    bool isRePrintPending = false,
  }) async {
    List<PrintReceiptCacheModel> listPRCForCallback = [];
    try {
      final List<PrintReceiptCacheModel> listPrintCache =
          !isRePrintPending
              ? await _localPrintReceiptCacheRepository
                  .getListPrintReceiptCacheWithPendingStatus()
              : await _localPrintReceiptCacheRepository
                  .getListPrintReceiptCacheWithProcessingStatus();
      prints("🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀 ${listPrintCache.length}");
      for (PrintReceiptCacheModel prc in listPrintCache) {
        await _localPrintReceiptCacheRepository.update(
          prc.copyWith(status: PrintCacheStatusEnum.processing),
          false,
        );
      }
      // then separate between void and kitchen
      final listPrintCacheVoid =
          listPrintCache.where((prc) {
            return prc.printType == DepartmentTypeEnum.printVoid;
          }).toList();

      final listPrintCacheKitchen =
          listPrintCache.where((prc) {
            return prc.printType == DepartmentTypeEnum.printKitchen;
          }).toList();

      if (departmentType != null) {
        await onHandlePrintVoidOrKitchen(
          departmentType: departmentType,
          onSuccess: onSuccess,
          onError: onError,
          onSuccessPrintReceiptCache: (listPRC) {
            listPRCForCallback.addAll(listPRC);
          },

          listPrintCache:
              departmentType == DepartmentTypeEnum.printVoid
                  ? listPrintCacheVoid
                  : (departmentType == DepartmentTypeEnum.printKitchen
                      ? listPrintCacheKitchen
                      : []),
        );
      } else {
        // print kitchen and void

        List<String> allErrors = [];
        List<String> allIpsErrors = [];
        prints('⏳ Waiting 200 milliseconds before KITCHEN printing...');
        await Future.delayed(Duration(milliseconds: 200));

        prints('📄 Step 2: Printing KITCHEN receipts...');

        if (listPrintCacheKitchen.isNotEmpty) {
          bool kitchenSuccess = false;
          String kitchenError = '';
          String kitchenIpError = '';
          await onHandlePrintVoidOrKitchen(
            departmentType: DepartmentTypeEnum.printKitchen,
            listPrintCache: listPrintCacheKitchen,
            onSuccess: () {
              prints('✅ KITCHEN printing completed successfully');
              kitchenSuccess = true;
            },
            onSuccessPrintReceiptCache: (listPrcKitchen) {
              for (PrintReceiptCacheModel prc in listPrcKitchen) {
                listPRCForCallback.add(prc);
              }
            },
            onError: (message, ipAdd) {
              prints('❌ KITCHEN printing failed: $message');
              kitchenError = 'KITCHEN: $message';
              kitchenIpError = ipAdd;
            },
          );
          if (!kitchenSuccess && kitchenError.isNotEmpty) {
            allErrors.add(kitchenError);
          }
          if (kitchenIpError.isNotEmpty) {
            allIpsErrors.add(kitchenIpError);
          }
        }

        if (listPrintCacheVoid.isNotEmpty) {
          prints('📄 Step 1: Printing VOID receipts...');

          bool voidSuccess = false;
          String voidError = '';
          String voidIpError = '';
          await onHandlePrintVoidOrKitchen(
            departmentType: DepartmentTypeEnum.printVoid,
            listPrintCache: listPrintCacheVoid,
            onSuccessPrintReceiptCache: (listPrcVoid) {
              for (PrintReceiptCacheModel prc in listPrcVoid) {
                listPRCForCallback.add(prc);
              }
            },
            onSuccess: () {
              prints('✅ VOID printing completed successfully');
              voidSuccess = true;
            },
            onError: (message, ipAdd) {
              prints('❌ VOID printing failed: $message');
              voidError = 'VOID: $message';
              voidIpError = ipAdd;
            },
          );
          if (!voidSuccess && voidError.isNotEmpty) {
            allErrors.add(voidError);
          }
          if (voidIpError.isNotEmpty) {
            allIpsErrors.add(voidIpError);
          }
        }

        if (allIpsErrors.isNotEmpty) {
          String combinedError =
              allErrors.isNotEmpty
                  ? allErrors.join(', ')
                  : "Print Void and Kitchen failed";
          onError(combinedError, allIpsErrors.join(', '));
        } else {
          prints('✅ Both VOID and KITCHEN printing completed successfully');
          onSuccess();
        }
      }
      onSuccessPrintReceiptCache(listPRCForCallback);
    } catch (e) {
      prints('❌ Critical error in sequential printing: $e');
      // dah pass on error dalam onHandlePrintVoidOrKitchen
      onSuccessPrintReceiptCache(listPRCForCallback);
      // onError('Critical error: $e', '');
    }
  }

  Future<void> onHandlePrintVoidOrKitchen({
    required List<PrintReceiptCacheModel> listPrintCache,
    required String departmentType,
    required Function() onSuccess,
    required Function(List<PrintReceiptCacheModel>) onSuccessPrintReceiptCache,
    required Function(String message, String ipAdd) onError,
  }) async {
    PrinterJobService printerJobService = PrinterJobService();
    final PosDeviceModel posDeviceModel = ServiceLocator.get<PosDeviceModel>();

    final departmentPrinterNotifier = _ref.read(
      departmentPrinterProvider.notifier,
    );
    final receiptNotifier = _ref.read(receiptProvider.notifier);

    List<String> errorIps = [];
    // get list print cache then loop

    for (PrintReceiptCacheModel prc in listPrintCache) {
      final SaleModel? saleModel = prc.printData?.saleModel;
      final List<SaleItemModel>? listSI = prc.printData?.listSaleItems;
      final List<SaleModifierModel>? listSM = prc.printData?.listSM;
      final List<SaleModifierOptionModel>? listSMO = prc.printData?.listSMO;
      final OrderOptionModel? orderOptionModel =
          prc.printData?.orderOptionModel;

      final PrinterSettingModel? psm = prc.printData?.printerSettingModel;
      final DepartmentPrinterModel? dpm = prc.printData?.dpm;
      final PredefinedOrderModel? pom = prc.printData?.predefinedOrderModel;
      final PrinterSettingModel? psmFromDB = await getPrinterSettingModelById(
        psm?.id ?? '',
      );

      if (psmFromDB == null) {
        prints('❌ Printer setting not found');
        await _localPrintReceiptCacheRepository.delete(prc.id!, false);
        continue;
      }
      if (prc.posDeviceId != posDeviceModel.id) {
        prints('❌ POS DEVICE NOT SAME');
        await _localPrintReceiptCacheRepository.delete(prc.id!, false);
        continue;
      }
      if (psm == null || psm.identifierAddress == null) {
        prints('❌ Printer setting not found or invalid identifier address');
        await _localPrintReceiptCacheRepository.delete(prc.id!, false);
        continue;
      }
      if (!psm.printOrders!) {
        await _localPrintReceiptCacheRepository.delete(prc.id!, false);
        continue;
      }

      if (saleModel == null) {
        await _localPrintReceiptCacheRepository.delete(prc.id!, false);
        continue;
      }
      if (dpm?.id == null) {
        await _localPrintReceiptCacheRepository.delete(prc.id!, false);
        continue;
      }
      try {
        prints(
          '🖨️ Starting CROSS-DEVICE $departmentType PROCESS for sale: ${saleModel.id}',
        );

        if (saleModel.id == null) {
          prints('❌ Sale model not found for ID: ${saleModel.id}');
          await _localPrintReceiptCacheRepository.delete(prc.id!, false);
          onError('Sale not found', '');
          continue;
        }

        List<SaleItemModel> listSaleItem = List<SaleItemModel>.from(
          listSI ?? [],
        );
        if (listSaleItem.isEmpty) {
          await _localPrintReceiptCacheRepository.delete(prc.id!, false);
          prints('❌ Failed to retrieve sale items for $departmentType');
          onError('Failed to retrieve sale items', '');
          continue;
        }

        // Filter items based on department type
        listSaleItem =
            departmentType == DepartmentTypeEnum.printVoid
                ? listSaleItem
                    .where((element) => element.isVoided == true)
                    .toList()
                : listSaleItem
                    .where((element) => element.isVoided == false)
                    .toList();

        if (listSaleItem.isEmpty) {
          await _localPrintReceiptCacheRepository.delete(prc.id!, false);
          prints('ℹ️ No $departmentType items found for sale: ${saleModel.id}');
          onSuccess();
          continue;
        }

        prints(
          '📄 Found ${listSaleItem.length} $departmentType items to print',
        );

        // ✅ Separate WiFi and Bluetooth printers for better coordination
        Map<String, List<Map<String, dynamic>>> wifiJobs = {};
        Map<String, List<Map<String, dynamic>>> bluetoothJobs = {};

        // Collect and categorize print jobs

        if (saleModel.id != null) {
          try {
            await _processPrinterJobs(
              psmFromDB,
              listSaleItem,
              listSM ?? [],
              listSMO ?? [],
              orderOptionModel,
              pom,
              dpm ?? DepartmentPrinterModel(),
              saleModel,
              wifiJobs,
              bluetoothJobs,
              errorIps,
            );
          } catch (e) {
            prints('❌ Error processing printer ${psm.name}: $e');

            if (psm.identifierAddress != null &&
                !errorIps.contains(psm.identifierAddress)) {
              errorIps.add(psm.identifierAddress!);
            }
          }
        }

        // ✅ Execute print jobs with proper coordination
        await _executePrintJobsCoordinated(
          wifiJobs,
          bluetoothJobs,
          printerJobService,
          errorIps,
          departmentType,

          printReceiptCacheModel: prc,
          onSuccessPrintReceiptCache: onSuccessPrintReceiptCache,
        );

        // ✅ Final result handling
        _handlePrintResults(
          errorIps,
          onSuccess,
          onError,
          listPrintCache,
          onSuccessPrintReceiptCache,
        );
      } catch (e) {
        prints('❌ Critical error in onHandlePrintVoidOrKitchen: $e');
        onSuccessPrintReceiptCache(listPrintCache);
        onError('Critical print error: ', errorIps.join(', '));
      }
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  Future<void> _processPrinterJobs(
    PrinterSettingModel psm,
    List<SaleItemModel> listSaleItem,
    List<SaleModifierModel> listSM,
    List<SaleModifierOptionModel> listSMO,
    OrderOptionModel? orderOptionModel,
    PredefinedOrderModel? pom,
    DepartmentPrinterModel dpm,
    SaleModel saleModel,
    Map<String, List<Map<String, dynamic>>> wifiJobs,
    Map<String, List<Map<String, dynamic>>> bluetoothJobs,
    List<String> errorIps,
  ) async {
    if (listSaleItem.isEmpty) {
      prints('⚠️ No sale items to process for printer: ${psm.name}');
      return;
    }

    if (dpm.id == null) {
      prints('⚠️ No printer for sale: ${saleModel.id}');

      return;
    }

    String printerIp = psm.identifierAddress ?? 'unknown';

    Map<String, List<Map<String, dynamic>>> targetJobs =
        psm.interface == PrinterSettingEnum.bluetooth
            ? bluetoothJobs
            : wifiJobs;

    if (!targetJobs.containsKey(printerIp)) {
      targetJobs[printerIp] = [];
    }

    targetJobs[printerIp]!.add({
      'psm': psm,
      'dpm': dpm,
      'filteredList': listSaleItem,
      'saleModel': saleModel,
      'listSM': listSM,
      'listSMO': listSMO,
      'orderOptionModel': orderOptionModel,
      'ref': _ref,
      'pom': pom,
    });

    prints(
      '📋 Added ${psm.interface} job for printer ${psm.name}: ${listSaleItem.length} items',
    );
  }

  Future<void> _executePrintJobsCoordinated(
    Map<String, List<Map<String, dynamic>>> wifiJobs,
    Map<String, List<Map<String, dynamic>>> bluetoothJobs,
    PrinterJobService printerJobService,
    List<String> errorIps,
    String departmentType, {

    required PrintReceiptCacheModel printReceiptCacheModel,
    required Function(List<PrintReceiptCacheModel>) onSuccessPrintReceiptCache,
  }) async {
    // ✅ Start WiFi jobs first (they're more reliable)
    List<Future<void>> wifiTasks = [];
    for (String printerIp in wifiJobs.keys) {
      List<Map<String, dynamic>> jobsForPrinter = wifiJobs[printerIp]!;
      prints('🌐 Starting WiFi jobs for printer $printerIp');

      Future<void> wifiTask = printerJobService.processJobsForPrinter(
        printCacheModel: printReceiptCacheModel,
        printerIp,
        jobsForPrinter,
        errorIps,
        departmentType,

        onSuccessPrintReceiptCache: onSuccessPrintReceiptCache,
      );
      wifiTasks.add(wifiTask);
    }

    // ✅ Wait for WiFi jobs to complete
    if (wifiTasks.isNotEmpty) {
      prints(
        '⏳ Waiting for ${wifiTasks.length} WiFi printer(s) to complete...',
      );
      await Future.wait(wifiTasks);
      prints('✅ All WiFi jobs completed');
    }

    // ✅ Add delay before starting Bluetooth jobs
    if (wifiTasks.isNotEmpty && bluetoothJobs.isNotEmpty) {
      prints('⏳ Waiting 3 seconds before starting Bluetooth jobs...');
      await Future.delayed(Duration(seconds: 3));
    }

    // globalStopwatch.stop();
    // prints(
    //   '🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡=== PREDEFINED ORDER PRINT TIME: ${globalStopwatch.elapsedMilliseconds} ===',
    // );

    // ✅ Start Bluetooth jobs
    List<Future<void>> bluetoothTasks = [];
    for (String printerIp in bluetoothJobs.keys) {
      List<Map<String, dynamic>> jobsForPrinter = bluetoothJobs[printerIp]!;
      prints('📱 Starting Bluetooth jobs for printer $printerIp');

      Future<void> bluetoothTask = printerJobService.processJobsForPrinter(
        printerIp,
        jobsForPrinter,
        errorIps,
        departmentType,

        printCacheModel: printReceiptCacheModel,
        onSuccessPrintReceiptCache: onSuccessPrintReceiptCache,
      );
      bluetoothTasks.add(bluetoothTask);
    }

    // ✅ Wait for Bluetooth jobs to complete
    if (bluetoothTasks.isNotEmpty) {
      prints(
        '⏳ Waiting for ${bluetoothTasks.length} Bluetooth printer(s) to complete...',
      );

      await Future.wait(bluetoothTasks);

      prints('✅ All Bluetooth jobs completed');
    }
  }

  void _handlePrintResults(
    List<String> errorIps,

    Function() onSuccess,
    Function(String, String) onError,
    List<PrintReceiptCacheModel> listPrintCache,
    Function(List<PrintReceiptCacheModel> listPrintCache)
    onSuccessPrintReceiptCache,
  ) {
    prints('   Error IPs: ${errorIps.length}');

    if (errorIps.isNotEmpty) {
      String errorMessage = 'Print failed for ${errorIps.length} printer(s)';
      prints('❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌ $errorMessage: ${errorIps.join(', ')}');
      onSuccessPrintReceiptCache(listPrintCache);
      onError(errorMessage, errorIps.join(', '));
    } else {
      prints('✅ All print jobs completed successfully');
      onSuccess();
    }
  }

  /// Print shift history/close shift receipt
  Future<void> printShiftHistoryDesign({
    required bool isInterfaceBluetooth,
    required String ipAddress,
    required String paperWidth,
    required ShiftModel shiftModel,
    required Function(String, String) onError,
    required Map<String, dynamic> dataCloseShift,
  }) async {
    if (isInterfaceBluetooth) {
      final bluetooth = FlutterThermalPrinter.instance;
      List<PrinterModel> printers = [];

      try {
        await bluetooth.getPrinters(
          connectionTypes: [ConnectionTypeEnum.USB, ConnectionTypeEnum.BLE],
        );

        bluetooth.devicesStream.listen((List<PrinterModel> event) {
          printers = event;
        });

        await Future.delayed(Duration(milliseconds: 200));

        PrinterModel? targetDevice;
        for (PrinterModel device in printers) {
          if (device.address == ipAddress) {
            targetDevice = device;
            break;
          }
        }

        if (targetDevice == null) {
          prints("Device with IP $ipAddress not found");
          onError('Device not found', ipAddress);
          return;
        }

        bool? isConnected = targetDevice.isConnected;

        if (isConnected == true) {
          await Future.delayed(Duration(milliseconds: 500));
          await ShiftHistoryDesign.shiftHistoryDesign(
            dataCloseShift: dataCloseShift,
            shiftModel: shiftModel,
            paperWidth: paperWidth,
            printer: targetDevice,
            isOpenCashDrawer: false,
            onError: onError,
            ref: _ref,
          );
        } else {
          try {
            await bluetooth.connect(targetDevice);
            await Future.delayed(Duration(milliseconds: 500));
            await ShiftHistoryDesign.shiftHistoryDesign(
              dataCloseShift: dataCloseShift,
              shiftModel: shiftModel,
              paperWidth: paperWidth,
              printer: targetDevice,
              isOpenCashDrawer: false,
              onError: onError,
              ref: _ref,
            );
          } catch (e) {
            prints('Error PRINT SHIFT HISTORY BLUETOOTH: $e');
            onError(e.toString(), ipAddress);
          }
        }
      } catch (e) {
        prints("Error during printShiftHistoryDesign execution: $e");
        onError("Error during execution", ipAddress);
      }
    } else {
      // Create a network printer instance
      final networkPrinter = PrinterModel(
        address: ipAddress,
        name: 'Network PrinterModel',
        connectionType: ConnectionTypeEnum.NETWORK,
      );

      try {
        // Call the unified method which handles the printing internally
        await ShiftHistoryDesign.shiftHistoryDesign(
          printer: networkPrinter,
          shiftModel: shiftModel,
          dataCloseShift: dataCloseShift,
          paperWidth: paperWidth,
          isOpenCashDrawer: false,
          onError: onError,
          ref: _ref,
        );
      } on Exception catch (e) {
        prints('Error during network printing: $e');
        onError('errorConnectingToDevice'.tr(), ipAddress);
      }
    }
  }

  List<PrinterSettingModel> prepareData(List<PrinterSettingModel> list) {
    for (PrinterSettingModel printerSetting in list) {
      // isSynced property removed
      printerSetting.categories = jsonEncode(printerSetting.categories ?? []);
    }
    return list;
  }

  Future<bool> updatePrinterSetting(PrinterSettingModel model) async {
    return await _localRepository.updatePrinterSetting(model);
  }

  Future<bool> checkIpAddressExist(String ipAddress) async {
    return await _localRepository.checkIpAddressExist(ipAddress);
  }

  Future<List<PrinterSettingModel>> getAllPrinterSettings() async {
    return await _localRepository.getAllPrinterSettings();
  }

  Future<List<PrinterSettingModel>> getListPrinterSettingDepartment() async {
    return await _localRepository.getListPrinterSettingDepartment();
  }

  Future<int> insert(
    BuildContext context,
    PrinterSettingModel printerSettingModel,
  ) async {
    return await _localRepository.insert(printerSettingModel, true);
  }

  Future<int> update(PrinterSettingModel printerSettingModel) async {
    return await _localRepository.update(printerSettingModel, true);
  }

  Future<List<PrinterSettingModel>> syncFromRemote() async {
    List<PrinterSettingModel> allPrinterSettings = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching printer settings page $currentPage');
      PrinterSettingListResponseModel responseModel = await _webService.get(
        _remoteRepository.getPrinterSettingWithPagination(
          currentPage.toString(),
        ),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Process printer settings from current page
        List<PrinterSettingModel> pagePrinterSettings = responseModel.data!;

        // Add printer settings from current page to the list
        allPrinterSettings.addAll(pagePrinterSettings);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination PRINTER SETTING: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
          );
        } else {
          // If no paginator info, assume we're done
          break;
        }

        // Move to next page
        currentPage++;
      } else {
        // If request failed, stop pagination
        prints(
          'Failed to fetch printer settings page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allPrinterSettings.length} printer settings from all pages',
    );
    return allPrinterSettings;
  }

  Future<void> printTest({
    required bool isInterfaceBluetooth,
    required String ipAddress,
    required String paperWidth,
    required Function(String, String) onError,
  }) async {
    final bluetooth = FlutterThermalPrinter.instance;
    if (isInterfaceBluetooth) {
      List<PrinterModel> printers = [];
      try {
        await bluetooth.getPrinters(
          connectionTypes: [ConnectionTypeEnum.USB, ConnectionTypeEnum.BLE],
        );

        bluetooth.devicesStream.listen((List<PrinterModel> event) {
          printers = event;
        });

        await Future.delayed(Duration(milliseconds: 200));

        PrinterModel? targetDevice;
        for (PrinterModel device in printers) {
          if (device.address == ipAddress) {
            targetDevice = device;
            break;
          }
        }

        if (targetDevice == null) {
          prints("Device with address $ipAddress not found");
          onError('Device not found', ipAddress);
          return;
        }

        // Handle different printer types
        bool? isConnected = targetDevice.isConnected;
        bool isIminPrinter = ReceiptPrinterUtils.isIminPrinter(targetDevice);
        bool isUsbPrinter =
            targetDevice.connectionType == ConnectionTypeEnum.USB;

        prints(
          'PrintTest - Device: ${targetDevice.name}, Type: ${targetDevice.connectionType}, Connected: $isConnected, IsImin: $isIminPrinter',
        );

        if (isIminPrinter) {
          // iMin printers have special handling
          await TestPrint.testingDesign(
            targetDevice,
            paperWidth,
            onError,
            _ref,
          );
        } else if (isUsbPrinter) {
          // USB printers - handle connection differently
          prints('CASE USB PRINTER');
          prints(targetDevice.toJson());

          if (isConnected == true) {
            // Already connected, print directly
            prints('USB ALREADY CONNECT, TRYING TO TEST PRINT');
            await TestPrint.testingDesign(
              targetDevice,
              paperWidth,
              onError,
              _ref,
            );
          } else {
            // Connect first, then print
            try {
              await bluetooth.connect(targetDevice);
              await Future.delayed(Duration(milliseconds: 500));
              await TestPrint.testingDesign(
                targetDevice,
                paperWidth,
                onError,
                _ref,
              );
            } catch (e) {
              prints('Error connecting to USB printer: $e');
              onError('Error connecting to USB printer', ipAddress);
            }
          }
        } else {
          // Bluetooth printers - always disconnect/reconnect for stability
          if (isConnected == true) {
            prints('CASE 1 - BLE CONNECTED');
            await bluetooth.disconnect(targetDevice);
            await Future.delayed(Duration(milliseconds: 1000));
            await bluetooth.connect(targetDevice);
            await Future.delayed(Duration(milliseconds: 500));
          } else {
            prints('CASE 2 - BLE NOT CONNECTED');
            try {
              await bluetooth.connect(targetDevice);
              await Future.delayed(Duration(milliseconds: 500));
            } catch (e) {
              prints('Error connecting to Bluetooth printer: $e');
              onError('Error connecting to Bluetooth printer', ipAddress);
              return;
            }
          }
          await TestPrint.testingDesign(
            targetDevice,
            paperWidth,
            onError,
            _ref,
          );
        }
      } catch (e) {
        prints('Error during printTest execution: $e');
        onError('errorGettingBondedDevices'.tr(), ipAddress);
      }
    } else {
      // Create a network printer instance

      final networkPrinter = PrinterModel(
        address: ipAddress,
        name: 'Network PrinterModel',
        connectionType: ConnectionTypeEnum.NETWORK,
      );

      try {
        // Call the unified method which handles the printing internally
        await TestPrint.testingDesign(
          networkPrinter,
          paperWidth,
          onError,
          _ref,
        );
        prints('TAK MASUK CATCH');
      } on Exception catch (e) {
        prints('Error during network printing: $e');
        onError('errorConnectingToDevice'.tr(), ipAddress);
      }
    }
  }

  Future<void> openCashDrawer(
    String ipAddress, {
    required bool isInterfaceBluetooth,
    required Function(String message, String ipAddress) onError,
    required String activityFrom,
  }) async {
    FlutterThermalPrinter thermalPrinter = FlutterThermalPrinter.instance;

    List<PrinterModel> printers = [];

    if (isInterfaceBluetooth) {
      try {
        // Start scanning for printers
        await thermalPrinter.getPrinters(
          connectionTypes: [ConnectionTypeEnum.USB, ConnectionTypeEnum.BLE],
        );

        // Listen for available printers
        thermalPrinter.devicesStream.listen((List<PrinterModel> event) {
          printers = event;
        });

        // Wait for printers to be detected
        // dear future me, dont put under 150 or it will not work
        await Future.delayed(Duration(milliseconds: 150));

        PrinterModel? targetDevice;
        for (PrinterModel device in printers) {
          if (device.address == ipAddress) {
            targetDevice = device;
            break;
          } else {
            prints('TAKDE TARGET DEVICE');
          }
        }

        if (targetDevice == null) {
          prints("Device with Cash DRAWER not found");
          onError(
            'Device with Cash DRAWER not found',
            'Some printers did not connect to cash drawer',
          );
          return;
        }

        bool? isConnected = targetDevice.isConnected;
        bool isIminPrinter = ReceiptPrinterService.isIminPrinter(targetDevice);
        bool isUsbPrinter =
            targetDevice.connectionType == ConnectionTypeEnum.USB;

        prints(
          'OpenCashDrawer - Device: ${targetDevice.name}, Type: ${targetDevice.connectionType}, Connected: $isConnected, IsImin: $isIminPrinter',
        );

        if (isIminPrinter) {
          prints('IS IMIN PRINTER');
          OpenCashDrawerDesign.openCashDrawer(
            printer: targetDevice,
            onError: onError,
            activityFrom: activityFrom,
            ref: _ref,
          );
        } else if (isUsbPrinter) {
          // USB printers - handle connection differently
          prints('IS USB PRINTER FOR CASH DRAWER');
          if (isConnected == true) {
            OpenCashDrawerDesign.openCashDrawer(
              printer: targetDevice,
              onError: onError,
              activityFrom: activityFrom,
              ref: _ref,
            );
          } else {
            try {
              await thermalPrinter.connect(targetDevice);
              await Future.delayed(Duration(milliseconds: 500));
              OpenCashDrawerDesign.openCashDrawer(
                printer: targetDevice,
                onError: onError,
                activityFrom: activityFrom,
                ref: _ref,
              );
            } catch (e) {
              prints("Error connecting to USB printer for cash drawer: $e");
              onError('Error connecting to USB printer', ipAddress);
            }
          }
        } else {
          // Bluetooth printers
          if (isConnected == true) {
            OpenCashDrawerDesign.openCashDrawer(
              printer: targetDevice,
              onError: onError,
              activityFrom: activityFrom,
              ref: _ref,
            );
          } else {
            await thermalPrinter
                .connect(targetDevice)
                .then((_) {
                  OpenCashDrawerDesign.openCashDrawer(
                    printer: targetDevice!,
                    onError: onError,
                    activityFrom: activityFrom,
                    ref: _ref,
                  );
                })
                .catchError((e) {
                  prints(
                    "Error connecting to Bluetooth device for opening cash drawer: $e",
                  );
                });
          }
        }
      } catch (e) {
        prints("Error during openCashDrawer execution: $e");
      }
    } else {
      // Create a network printer instance

      final networkPrinter = PrinterModel(
        address: ipAddress,
        name: 'Network PrinterModel',
        connectionType: ConnectionTypeEnum.NETWORK,
      );

      try {
        // Call the unified method which handles the printing internally
        await OpenCashDrawerDesign.openCashDrawer(
          printer: networkPrinter,
          onError: onError,
          activityFrom: activityFrom,
          ref: _ref,
        );
      } on Exception catch (e) {
        prints('Error during network printing: $e');
        onError('errorConnectingToDevice'.tr(), ipAddress);
      }
    }
  }

  Future<void> printSalesReceipt({
    required ReceiptModel receiptModel,
    required List<ReceiptItemModel> receiptItems,
    required bool isInterfaceBluetooth,
    required String ipAddress,
    required String paperWidth,
    required bool isOpenCashDrawer,
    required Function(String message, String ipAddress) onError,
    required List<PrinterSettingModel> listPrinterSettings,
    required bool isAutomaticPrint,
    required String activityFrom,
  }) async {
    if (isInterfaceBluetooth) {
      FlutterThermalPrinter thermalPrinter = FlutterThermalPrinter.instance;
      List<PrinterModel> printers = [];

      try {
        await thermalPrinter.getPrinters(
          connectionTypes: [ConnectionTypeEnum.USB, ConnectionTypeEnum.BLE],
        );

        thermalPrinter.devicesStream.listen((List<PrinterModel> event) {
          printers = event;
        });

        await Future.delayed(Duration(milliseconds: 200));

        PrinterModel? targetDevice;
        for (PrinterModel device in printers) {
          if (device.address == ipAddress) {
            targetDevice = device;
            break;
          }
        }

        if (targetDevice == null) {
          prints(" ❌❌❌Device with IP $ipAddress not found");
          onError('Device not found', ipAddress);
          return;
        }

        bool isIminPrinter = ReceiptPrinterService.isIminPrinter(targetDevice);
        if (isIminPrinter) {
          await SalesDesignPrint.salesDesign(
            paperWidth: paperWidth,
            printer: targetDevice,
            receiptModel: receiptModel,
            receiptItems: receiptItems,
            isOpenCashDrawer: isOpenCashDrawer,
            onError: onError,
            listPrinterSettings: listPrinterSettings,
            isAutomaticPrint: isAutomaticPrint,
            activityFrom: activityFrom,
            ref: _ref,
          );
        } else {
          bool? isConnected = targetDevice.isConnected;

          if (isConnected == true) {
            await thermalPrinter.disconnect(targetDevice);
            await Future.delayed(Duration(milliseconds: 1000));
            await thermalPrinter.connect(targetDevice);
            await Future.delayed(Duration(milliseconds: 500));
            await SalesDesignPrint.salesDesign(
              paperWidth: paperWidth,
              printer: targetDevice,
              receiptModel: receiptModel,
              receiptItems: receiptItems,
              isOpenCashDrawer: isOpenCashDrawer,
              onError: onError,
              listPrinterSettings: listPrinterSettings,
              isAutomaticPrint: isAutomaticPrint,
              activityFrom: activityFrom,
              ref: _ref,
            );
          } else {
            try {
              await thermalPrinter.connect(targetDevice);
              await Future.delayed(Duration(milliseconds: 500));
              await SalesDesignPrint.salesDesign(
                paperWidth: paperWidth,
                printer: targetDevice,
                receiptModel: receiptModel,
                receiptItems: receiptItems,
                isOpenCashDrawer: isOpenCashDrawer,
                onError: onError,
                listPrinterSettings: listPrinterSettings,
                isAutomaticPrint: isAutomaticPrint,
                activityFrom: activityFrom,
                ref: _ref,
              );
            } catch (e) {
              prints("Error connecting to device: $e");
              onError("Error connecting to device", ipAddress);
            }
          }
        }
      } catch (e) {
        prints("Error during printSalesReceipt execution: $e");
        onError("Error during execution", ipAddress);
      }
    } else {
      // Create a network printer instance

      final networkPrinter = PrinterModel(
        address: ipAddress,
        name: 'Network PrinterModel',
        connectionType: ConnectionTypeEnum.NETWORK,
      );

      try {
        // Call the unified method which handles the printing internally
        await SalesDesignPrint.salesDesign(
          paperWidth: paperWidth,
          printer: networkPrinter,
          receiptModel: receiptModel,
          receiptItems: receiptItems,
          isOpenCashDrawer: isOpenCashDrawer,
          onError: onError,
          listPrinterSettings: listPrinterSettings,
          isAutomaticPrint: isAutomaticPrint,
          activityFrom: activityFrom,
          ref: _ref,
        );
      } on Exception catch (e) {
        prints('Error during network printing: $e');
        onError('errorConnectingToDevice'.tr(), ipAddress);
      }
    }
  }

  Future<void> printVoidReceipt({
    required bool isInterfaceBluetooth,
    required String ipAddress,
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
    required Function(List<SaleItemModel>) onSuccess,
  }) async {
    if (isInterfaceBluetooth) {
      final bluetooth = FlutterThermalPrinter.instance;
      List<PrinterModel> printers = [];

      try {
        await bluetooth.getPrinters(
          connectionTypes: [ConnectionTypeEnum.USB, ConnectionTypeEnum.BLE],
        );

        bluetooth.devicesStream.listen((List<PrinterModel> event) {
          printers = event;
        });

        await Future.delayed(Duration(milliseconds: 200));

        PrinterModel? targetDevice;
        for (PrinterModel device in printers) {
          if (device.address == ipAddress) {
            targetDevice = device;
            break;
          }
        }

        if (targetDevice == null) {
          prints("Device with IP $ipAddress not found");
          onError('Device not found', ipAddress);
          return;
        }

        bool? isConnected = targetDevice.isConnected;

        if (isConnected == true) {
          await Future.delayed(Duration(milliseconds: 500));
          try {
            await VoidDesignPrint.voidDesign(
              paperWidth: paperWidth,
              printer: targetDevice,
              orderNumber: orderNumber,
              tableNumber: tableNumber,
              listSM: listSM,
              listSMO: listSMO,
              listSaleItems: listSaleItems,
              saleModel: saleModel,
              orderOptionModel: orderOptionModel,
              dpm: dpm,
              onError: onError,
              ref: _ref,
            );
            onSuccess(listSaleItems);
          } on Exception catch (e) {
            prints('Error during void design: $e');
            onError('Error during printing', ipAddress);
          }
        } else {
          try {
            await bluetooth.connect(targetDevice);
            await Future.delayed(Duration(milliseconds: 500));
            await VoidDesignPrint.voidDesign(
              paperWidth: paperWidth,
              printer: targetDevice,
              orderNumber: orderNumber,
              tableNumber: tableNumber,
              listSM: listSM,
              listSMO: listSMO,
              listSaleItems: listSaleItems,
              saleModel: saleModel,
              orderOptionModel: orderOptionModel,
              dpm: dpm,
              onError: onError,
              ref: _ref,
            );
            onSuccess(listSaleItems);
          } on Exception catch (e) {
            prints('Error during void design: $e');
            onError('Error during printing', ipAddress);
          }
        }
      } catch (e) {
        prints("Error during printVoidReceipt execution: $e");
        onError("Error during execution", ipAddress);
      }
    } else {
      // Create a network printer instance

      final networkPrinter = PrinterModel(
        address: ipAddress,
        name: 'Network PrinterModel',
        connectionType: ConnectionTypeEnum.NETWORK,
      );

      try {
        // Call the unified method which handles the printing internally
        await VoidDesignPrint.voidDesign(
          printer: networkPrinter,
          orderNumber: orderNumber,
          tableNumber: tableNumber,
          listSM: listSM,
          listSMO: listSMO,
          listSaleItems: listSaleItems,
          saleModel: saleModel,
          orderOptionModel: orderOptionModel,
          dpm: dpm,
          paperWidth: paperWidth,
          onError: onError,
          ref: _ref,
        );
      } on Exception catch (e) {
        prints('💩💩💩💩💩💩💩💩Error during network printing: $e');
        onError('connectionTimeout'.tr(), ipAddress);
        return;
      }
      onSuccess(listSaleItems);
    }
  }

  Future<void> printKitchenOrderDesign({
    required bool isInterfaceBluetooth,
    required String ipAddress,
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
    required Function() onSuccess,
    required PrinterSettingModel printerSetting,
  }) async {
    if (isInterfaceBluetooth) {
      final bluetooth = FlutterThermalPrinter.instance;
      List<PrinterModel> printers = [];

      try {
        await bluetooth.getPrinters(
          connectionTypes: [ConnectionTypeEnum.USB, ConnectionTypeEnum.BLE],
        );

        bluetooth.devicesStream.listen((List<PrinterModel> event) {
          printers = event;
        });

        await Future.delayed(Duration(milliseconds: 200));

        PrinterModel? targetDevice;
        for (PrinterModel device in printers) {
          if (device.address == ipAddress) {
            targetDevice = device;
            break;
          }
        }

        if (targetDevice == null) {
          prints("🤢🤢🤢🤢🤢🤢🤢🤢🤢🤢🤢🤢Device with IP $ipAddress not found");
          onError('Device not found', ipAddress);
          return;
        }

        bool? isConnected = targetDevice.isConnected;
        int reconnectionTime = 200;
        // globalStopwatch2.stop();
        // prints(
        //   '🥮🥮🥮🥮🥮🥮🥮=== TOTAL TIME FOR PRINT: ${globalStopwatch2.elapsedMilliseconds} ===',
        // );
        if (isConnected == true) {
          await Future.delayed(Duration(milliseconds: reconnectionTime));
          try {
            await KitchenOrderDesignOrder.kitchenOrderDesign(
              paperWidth: paperWidth,
              printer: targetDevice,
              orderNumber: orderNumber,
              tableNumber: tableNumber,
              listSM: listSM,
              listSMO: listSMO,
              listSaleItems: listSaleItems,
              saleModel: saleModel,
              orderOptionModel: orderOptionModel,
              dpm: dpm,
              onError: onError,
              printerSetting: printerSetting,
              ref: _ref,
            );
            onSuccess();
          } on Exception catch (e) {
            prints(
              '🥶🥶🥶🥶🥶🥶🥶🥶🥶🥶🥶🥶🥶🥶Error during kitchen order design: $e',
            );
            onError('Error during printing', ipAddress);
          }
        } else {
          try {
            await bluetooth.connect(targetDevice);
            await Future.delayed(Duration(milliseconds: reconnectionTime));
            await KitchenOrderDesignOrder.kitchenOrderDesign(
              paperWidth: paperWidth,
              printer: targetDevice,
              orderNumber: orderNumber,
              tableNumber: tableNumber,
              listSM: listSM,
              listSMO: listSMO,
              listSaleItems: listSaleItems,
              saleModel: saleModel,
              orderOptionModel: orderOptionModel,
              dpm: dpm,
              onError: onError,
              printerSetting: printerSetting,
              ref: _ref,
            );
            onSuccess();
          } on Exception catch (e) {
            prints(
              '👹👹👹👹👹👹👹👹👹👹👹👹👹👹👹👹👹👹👹Error during kitchen order design: $e',
            );
            onError('Error during printing', ipAddress);
          }
        }
      } catch (e) {
        prints(
          "🤬🤬🤬🤬🤬🤬🤬🤬🤬🤬🤬🤬🤬🤬🤬🤬🤬🤬🤬🤬Error during printKitchenOrderDesign execution: $e",
        );
        onError("Error during execution", ipAddress);
      }
    } else {
      // Create a network printer instance
      final networkPrinter = PrinterModel(
        address: ipAddress,
        name: 'Network PrinterModel',
        connectionType: ConnectionTypeEnum.NETWORK,
      );

      try {
        // Call the unified method which handles the printing internally
        await KitchenOrderDesignOrder.kitchenOrderDesign(
          printer: networkPrinter,
          orderNumber: orderNumber,
          tableNumber: tableNumber,
          listSM: listSM,
          listSMO: listSMO,
          listSaleItems: listSaleItems,
          saleModel: saleModel,
          orderOptionModel: orderOptionModel,
          dpm: dpm,
          paperWidth: paperWidth,
          onError: onError,
          printerSetting: printerSetting,
          ref: _ref,
        );
      } on Exception catch (e) {
        prints('🙀🙀🙀🙀🙀🙀🙀🙀🙀🙀🙀🙀Error during network printing: $e');
        onError('connectionTimeout'.tr(), ipAddress);
        return;
      }
      onSuccess();
    }
  }

  Future<void> printCloseShiftDesign({
    required bool isInterfaceBluetooth,
    required String ipAddress,
    required String paperWidth,
    required ShiftModel shiftModel,
    required Function(String, String) onError,
    required Map<String, dynamic> dataCloseShift,
  }) async {
    if (isInterfaceBluetooth) {
      final bluetooth = FlutterThermalPrinter.instance;
      List<PrinterModel> printers = [];

      try {
        await bluetooth.getPrinters(
          connectionTypes: [ConnectionTypeEnum.USB, ConnectionTypeEnum.BLE],
        );

        bluetooth.devicesStream.listen((List<PrinterModel> event) {
          printers = event;
        });

        await Future.delayed(Duration(milliseconds: 200));

        PrinterModel? targetDevice;
        for (PrinterModel device in printers) {
          if (device.address == ipAddress) {
            targetDevice = device;
            break;
          }
        }

        if (targetDevice == null) {
          prints("Device with IP $ipAddress not found");
          onError('Device not found', ipAddress);
          return;
        }

        bool? isConnected = targetDevice.isConnected;

        if (isConnected == true) {
          await Future.delayed(Duration(milliseconds: 500));
          await CloseShiftDesign.closeShiftDesign(
            dataCloseShift: dataCloseShift,
            shiftModel: shiftModel,
            paperWidth: paperWidth,
            printer: targetDevice,
            isOpenCashDrawer: false,
            onError: onError,
            ref: _ref,
          );
        } else {
          try {
            await bluetooth.connect(targetDevice);
            await Future.delayed(Duration(milliseconds: 500));
            await CloseShiftDesign.closeShiftDesign(
              dataCloseShift: dataCloseShift,
              shiftModel: shiftModel,
              paperWidth: paperWidth,
              printer: targetDevice,
              isOpenCashDrawer: false,
              onError: onError,
              ref: _ref,
            );
          } catch (e) {
            prints('Error PRINT CLOSE SHIFT BLUETOOTH: $e');
            onError(e.toString(), ipAddress);
          }
        }
      } catch (e) {
        prints("Error during printCloseShiftDesign execution: $e");
        onError("Error during execution", ipAddress);
      }
    } else {
      // Create a network printer instance

      final networkPrinter = PrinterModel(
        address: ipAddress,
        name: 'Network PrinterModel',
        connectionType: ConnectionTypeEnum.NETWORK,
      );

      try {
        // Call the unified method which handles the printing internally
        await CloseShiftDesign.closeShiftDesign(
          printer: networkPrinter,
          shiftModel: shiftModel,
          dataCloseShift: dataCloseShift,
          paperWidth: paperWidth,
          isOpenCashDrawer: false,
          onError: onError,
          ref: _ref,
        );
      } on Exception catch (e) {
        prints('Error during network printing: $e');
        onError('errorConnectingToDevice'.tr(), ipAddress);
      }
    }
  }

  Future<void> printRefundReceipt({
    required ReceiptModel receiptModel,
    required List<ReceiptItemModel> receiptItems,
    required bool isInterfaceBluetooth,
    required String ipAddress,
    required String paperWidth,
    required bool isOpenCashDrawer,
    required Function(String message, String ipAdd) onError,
    required List<PrinterSettingModel> listPrinterSettings,
    required bool isAutomaticPrint,
    required String activityFrom,
    required WidgetRef ref,
  }) async {
    if (isInterfaceBluetooth) {
      FlutterThermalPrinter thermalPrinter = FlutterThermalPrinter.instance;
      List<PrinterModel> printers = [];

      try {
        await thermalPrinter.getPrinters(
          connectionTypes: [ConnectionTypeEnum.USB, ConnectionTypeEnum.BLE],
        );

        thermalPrinter.devicesStream.listen((List<PrinterModel> event) {
          printers = event;
        });

        await Future.delayed(Duration(milliseconds: 200));

        PrinterModel? targetDevice;
        for (PrinterModel device in printers) {
          if (device.address == ipAddress) {
            targetDevice = device;
            break;
          }
        }

        prints('targetDevice: ${targetDevice?.name}');
        prints('targetDevice: ${targetDevice?.address}');
        prints('targetDevice: ${targetDevice?.connectionType}');
        prints('targetDevice: ${targetDevice?.isConnected}');

        if (targetDevice == null) {
          prints("Device with IP $ipAddress not found");
          onError('Device not found', ipAddress);
          return;
        }

        bool isIminPrinter = ReceiptPrinterService.isIminPrinter(targetDevice);
        if (isIminPrinter) {
          await SalesDesignPrint.salesDesign(
            paperWidth: paperWidth,
            printer: targetDevice,
            receiptModel: receiptModel,
            receiptItems: receiptItems,
            isOpenCashDrawer: isOpenCashDrawer,
            onError: onError,
            listPrinterSettings: listPrinterSettings,
            isAutomaticPrint: isAutomaticPrint,
            activityFrom: activityFrom,
            ref: _ref,
          );
        } else {
          bool? isConnected = targetDevice.isConnected;

          if (isConnected == true) {
            await thermalPrinter.disconnect(targetDevice);
            await Future.delayed(Duration(milliseconds: 1000));
            await thermalPrinter.connect(targetDevice);
            await Future.delayed(Duration(milliseconds: 500));
            await SalesDesignPrint.salesDesign(
              isOpenCashDrawer: isOpenCashDrawer,
              receiptModel: receiptModel,
              receiptItems: receiptItems,
              paperWidth: paperWidth,
              printer: targetDevice,
              onError: onError,
              listPrinterSettings: listPrinterSettings,
              isAutomaticPrint: isAutomaticPrint,
              activityFrom: activityFrom,
              ref: _ref,
            );
          } else {
            try {
              await thermalPrinter.connect(targetDevice);
              await Future.delayed(Duration(milliseconds: 500));
              await SalesDesignPrint.salesDesign(
                isOpenCashDrawer: isOpenCashDrawer,
                receiptModel: receiptModel,
                receiptItems: receiptItems,
                paperWidth: paperWidth,
                printer: targetDevice,
                onError: onError,
                listPrinterSettings: listPrinterSettings,
                isAutomaticPrint: isAutomaticPrint,
                activityFrom: activityFrom,
                ref: _ref,
              );
            } catch (e) {
              prints("Error connecting to device: $e");
              onError("Error connecting to device", ipAddress);
            }
          }
        }
      } catch (e) {
        prints("Error during printRefundReceipt execution: $e");
        onError("Error during execution", ipAddress);
      }
    } else {
      // Create a network printer instance

      final networkPrinter = PrinterModel(
        address: ipAddress,
        name: 'Network Printer',
        connectionType: ConnectionTypeEnum.NETWORK,
      );

      try {
        // Call the unified method which handles the printing internally
        await SalesDesignPrint.salesDesign(
          isOpenCashDrawer: isOpenCashDrawer,
          receiptModel: receiptModel,
          receiptItems: receiptItems,
          paperWidth: paperWidth,
          printer: networkPrinter,
          onError: onError,
          listPrinterSettings: listPrinterSettings,
          isAutomaticPrint: isAutomaticPrint,
          activityFrom: activityFrom,
          ref: _ref,
        );
      } on Exception catch (e) {
        prints('Error during network printing: $e');
        onError('errorConnectingToDevice'.tr(), ipAddress);
      }
    }
  }

  List<PrinterSettingModel> getListPrinterSettingFromHive() {
    return _localRepository.getListPrinterSettingFromHive();
  }

  Future<PrintReceiptCacheModel?> getModelBySaleId(String saleId) async {
    return await _localPrintReceiptCacheRepository.getModelBySaleId(saleId);
  }

  Future<List<PrinterSettingModel>> getListPrinterSettingByDevice({
    required bool isForThisDevice,
  }) async {
    return await _localRepository.getListPrinterSettingByDevice(
      isForThisDevice: isForThisDevice,
    );
  }
}

/// Provider for sorted items (computed provider)
final sortedPrinterSettingsProvider = Provider<List<PrinterSettingModel>>((
  ref,
) {
  final items = ref.watch(printerSettingProvider).items;
  final sorted = List<PrinterSettingModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for printerSetting domain
final printerSettingProvider =
    StateNotifierProvider<PrinterSettingNotifier, PrinterSettingState>((ref) {
      return PrinterSettingNotifier(
        localRepository: ServiceLocator.get<LocalPrinterSettingRepository>(),
        localSaleRepository: ServiceLocator.get<LocalSaleRepository>(),
        localPrintReceiptCacheRepository:
            ServiceLocator.get<LocalPrintReceiptCacheRepository>(),
        remoteRepository: ServiceLocator.get<PrinterSettingRepository>(),
        webService: ServiceLocator.get<IWebService>(),
        ref: ref,
      );
    });

/// Provider for printerSetting by ID (family provider for indexed lookups)
final printerSettingByIdProvider =
    FutureProvider.family<PrinterSettingModel?, String>((ref, id) async {
      final notifier = ref.watch(printerSettingProvider.notifier);
      return notifier.getPrinterSettingModelById(id);
    });
