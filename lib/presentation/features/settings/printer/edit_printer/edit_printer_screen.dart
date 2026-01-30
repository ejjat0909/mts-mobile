import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/theme.dart';
import 'package:mts/core/enums/permission_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/providers/department_printer/department_printer_providers.dart';
import 'package:mts/providers/device/device_providers.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/paper_width_enum.dart';
import 'package:mts/core/enum/printer_setting_enum.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/ui_utils.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/form_bloc/edit_printer_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/plugins/flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:mts/plugins/flutter_thermal_printer/utils/printer.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/dialogs/loading_dialogue.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/button_bottom.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/my_dropdown_bloc_builder.dart';
import 'package:mts/presentation/common/widgets/my_text_field_bloc_builder.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/data/services/receipt_printer_service.dart';
import 'package:mts/presentation/features/settings/printer/add_printer/components/department_printer_checkbox.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/print_receipt_cache/print_receipt_cache_providers.dart';

class EditPrinterScreen extends ConsumerStatefulWidget {
  const EditPrinterScreen({super.key});

  @override
  ConsumerState<EditPrinterScreen> createState() => _EditPrinterScreenState();
}

class _EditPrinterScreenState extends ConsumerState<EditPrinterScreen> {
  bool isInterfaceBluetooth = false;
  PrinterSettingModel ps = PrinterSettingModel();
  List<PrinterModel> _printers = [];
  PrinterModel? _selectedPrinter;
  final FlutterThermalPrinter _flutterThermalPrinter =
      FlutterThermalPrinter.instance;
  String bluetoothState = 'OFF';
  String paperWidth = 'mm80'.tr();
  List<DepartmentPrinterModel> selectedDpModels = [];

  bool isPrintReceiptBills = false;
  bool isPrintOrders = false;
  bool isAutomaticPrintReceipt = false;

  StreamSubscription<List<PrinterModel>>? _devicesStreamSubscription;
  Timer? _usbRefreshTimer;

  late PrintReceiptCacheNotifier printReceiptCacheNotifier;

  @override
  void initState() {
    super.initState();
    printReceiptCacheNotifier = ref.read(printReceiptCacheProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getData();
      startScan(true);
      // _startUsbRefreshTimer();
    });
  }

  @override
  void dispose() {
    // Disconnect the printer and cancel any subscriptions
    if (_selectedPrinter != null) {
      _flutterThermalPrinter.disconnect(_selectedPrinter!);
    }
    _devicesStreamSubscription?.cancel();
    _usbRefreshTimer?.cancel(); // Cancel USB refresh timer
    _flutterThermalPrinter.stopScan();
    super.dispose();
  }

  void getData() {
    final navState = ref.read(myNavigatorProvider);
    if (navState.data is PrinterSettingModel) {
      ps = navState.data;
      isInterfaceBluetooth = ps.interface == PrinterSettingEnum.bluetooth;
      if (ps.paperWidth == PaperWidthEnum.paperWidth58mm) {
        paperWidth = 'mm58'.tr();
      } else if (ps.paperWidth == PaperWidthEnum.paperWidth80mm) {
        paperWidth = 'mm80'.tr();
      }
      isPrintReceiptBills = ps.printReceiptBills ?? false;
      isPrintOrders = ps.printOrders ?? false;
      isAutomaticPrintReceipt = ps.automaticallyPrintReceipt ?? false;
    }
    setState(() {});
  }

  Future<void> _connectToPrinter(PrinterModel? printer) async {
    if (printer != null) {
      if (printer.connectionType == ConnectionTypeEnum.USB) {
        prints('=== CONNECTING TO PRINTER ===');
        prints('Printer Name: ${printer.name}');
        prints('Printer Address: ${printer.address}');
        prints(
          'Connection Type: ${printer.connectionType == ConnectionTypeEnum.BLE}',
        );
        prints('Current Connected Status: ${printer.isConnected}');
        if (printer.isConnected != true) {
          prints('ATTEMPTING CONNECTION...');
          try {
            // Check if this is a USB printer and request permission if needed
            if (printer.connectionType == ConnectionTypeEnum.USB) {
              prints('USB PRINTER DETECTED - REQUESTING PERMISSION...');
              bool hasPermission = await _flutterThermalPrinter
                  .requestUsbPermission(printer);
              prints('USB PERMISSION RESULT: $hasPermission');

              if (!hasPermission) {
                prints('USB PERMISSION DENIED');
                // ThemeSnackBar.showSnackBar(
                //   context,
                //   'USB permission denied for ${printer.name}',
                // );
                return;
              }
              prints('USB PERMISSION GRANTED - PROCEEDING WITH CONNECTION...');
            }

            bool connectionResult = await _flutterThermalPrinter.connect(
              printer,
            );
            prints('CONNECTION RESULT: $connectionResult');

            if (connectionResult) {
              // Wait a moment for the connection to stabilize
              await Future.delayed(Duration(milliseconds: 500));

              if (mounted) {
                setState(() {
                  _selectedPrinter = printer;
                  // Update the printer's connection status based on connect result
                  printer.isConnected = true;
                });
              }

              prints('Final Connected Status: ${printer.isConnected}');

              // ThemeSnackBar.showSnackBar(
              //   context,
              //   'Successfully connected to ${printer.name}',
              // );
            } else {
              prints('CONNECTION FAILED');
              // ThemeSnackBar.showSnackBar(
              //   context,
              //   'Failed to connect to ${printer.name}',
              // );
            }
          } catch (error) {
            prints('ERROR CONNECTING TO PRINTER: $error');
            // ThemeSnackBar.showSnackBar(context, 'Failed to connect: $error');
          }
        } else {
          prints('PRINTER ALREADY CONNECTED');
        }
      } else {
        if (printer.isConnected != true) {
          prints('CONNECT PRINTER ${printer.name} ${printer.address}');
          try {
            bool connected = await _flutterThermalPrinter.connect(printer);
            if (connected) {
              if (mounted) {
                setState(() {
                  _selectedPrinter = printer;
                  printer.isConnected = true;
                });
              }
              // ThemeSnackBar.showSnackBar(
              //   context,
              //   'Successfully connected to ${printer.name}',
              // );
            } else {
              // Don't set _selectedPrinter to null - keep the selection in dropdown
              // but update the connection status
              if (mounted) {
                setState(() {
                  printer.isConnected = false;
                });
              }
              // ThemeSnackBar.showSnackBar(
              //   context,
              //   'Failed to connect to ${printer.name}',
              // );
            }
          } catch (error) {
            prints('Error connecting to printer: $error');
            // Don't set _selectedPrinter to null - keep the selection in dropdown
            if (mounted) {
              setState(() {
                printer.isConnected = false;
              });
            }
            // ThemeSnackBar.showSnackBar(
            //   context,
            //   'Error connecting to ${printer.name}: $error',
            // );
          }
        } else {
          prints('PrinterModel already connected');
          if (mounted) {
            setState(() {
              _selectedPrinter = printer;
            });
          }
        }
      }
    } else {
      // ThemeSnackBar.showSnackBar(context, 'No Device Selected');
      _disconnectAndClearPrinter();
    }
  }

  Future<void> _disconnectPrinter() async {
    if (_selectedPrinter != null && _selectedPrinter!.isConnected == true) {
      try {
        await _flutterThermalPrinter.disconnect(_selectedPrinter!);
        if (mounted) {
          setState(() {
            // Don't set _selectedPrinter to null - just update connection status
            // This keeps the selection in the dropdown
            _selectedPrinter!.isConnected = false;
          });
        }
      } catch (error) {
        prints('Error disconnecting printer: $error');
      }
    }
  }

  Future<void> _disconnectAndClearPrinter() async {
    if (_selectedPrinter != null && _selectedPrinter!.isConnected == true) {
      try {
        await _flutterThermalPrinter.disconnect(_selectedPrinter!);
      } catch (error) {
        prints('Error disconnecting printer: $error');
      }
    }
    if (mounted) {
      setState(() {
        _selectedPrinter = null;
      });
    }
  }

  Future<void> startScan(bool isInit) async {
    // Cancel any existing subscription
    _devicesStreamSubscription?.cancel();

    try {
      // Start scanning for printers
      await _flutterThermalPrinter.getPrinters(
        connectionTypes: [ConnectionTypeEnum.USB, ConnectionTypeEnum.BLE],
      );

      // Listen for available printers
      _devicesStreamSubscription = _flutterThermalPrinter.devicesStream.listen((
        List<PrinterModel> printers,
      ) {
        if (!mounted) return;

        setState(() {
          _printers = printers;
          // Remove printers with null or empty names
          _printers.removeWhere(
            (element) => element.name == null || element.name!.isEmpty,
          );

          // Additional check for USB printers - verify they are still connected
          // _printers.removeWhere((printer) {
          //   if (printer.connectionType == ConnectionTypeEnum.USB) {
          //     // For USB printers, if isConnected is false, it means the device is disconnected
          //     return printer.isConnected == false;
          //   }
          //   return false;
          // });

          // // If we had a selected USB printer that's no longer in the list, clear it
          // if (_selectedPrinter != null &&
          //     _selectedPrinter!.connectionType == ConnectionTypeEnum.USB) {
          //   bool printerStillExists = _printers.any(
          //     (p) =>
          //         p.address == _selectedPrinter!.address &&
          //         p.connectionType == ConnectionTypeEnum.USB,
          //   );
          //   if (!printerStillExists) {
          //     _selectedPrinter = null;
          //   }
          // }

          // Set bluetooth state based on whether we found any printers
          bluetoothState = _printers.isNotEmpty ? 'ON' : 'OFF';

          // If this is initial scan and we have the printer address from settings
          if (isInit &&
              ps.identifierAddress != null &&
              ps.identifierAddress!.isNotEmpty) {
            // Try to find the saved printer in the list
            PrinterModel? savedPrinter = _printers.firstWhere(
              (p) => p.address == ps.identifierAddress,
              orElse: () => PrinterModel(name: null, address: null),
            );

            // If we found a valid printer, select it and try to connect
            if (savedPrinter.address != null) {
              _selectedPrinter = savedPrinter;
              _connectToPrinter(_selectedPrinter);
            }
          }
        });
      });
    } catch (e) {
      prints('Error starting printer scan: $e');
      if (mounted) {
        setState(() {
          bluetoothState = 'OFF';
        });
      }
    }
  }

  // void _startUsbRefreshTimer() {
  //   // Refresh USB devices every 3 seconds to detect disconnections
  //   _usbRefreshTimer = Timer.periodic(const Duration(milliseconds: 300), (
  //     timer,
  //   ) {
  //     if (mounted) {
  //       // Trigger a new scan to refresh USB device list
  //       _flutterThermalPrinter.getPrinters(
  //         connectionTypes: [ConnectionTypeEnum.USB, ConnectionTypeEnum.BLE],
  //       );
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final featureCompNotifier = ref.watch(featureCompanyProvider.notifier);
    final isFeatureActive = featureCompNotifier.isDepartmentPrintersActive();

    final navState = ref.watch(myNavigatorProvider);
    if (navState.data is PrinterSettingModel) {
      PrinterSettingModel ps = navState.data;
      List<String> dpmIds = List<String>.from(
        json.decode(ps.departmentPrinterJson ?? '[]'),
      );

      return FutureBuilder(
        future: ref
            .read(departmentPrinterProvider.notifier)
            .getListDepartmentPrintersFromIds(dpmIds),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Container();
          }
          if (!snapshot.hasData) {
            return Container();
          }
          List<DepartmentPrinterModel> initDpModels = snapshot.data!;
          return Container(
            // to make the container at the center of the screen
            margin: const EdgeInsets.only(
              top: 20,
              left: 50,
              right: 50,
              bottom: 20,
            ),
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: kWhiteColor,
              borderRadius: BorderRadius.circular(10.sp),
            ),
            child: BlocProvider(
              create:
                  (providerContext) => EditPrinterFormBloc(
                    navState.data,
                    context,
                    ref.read(printerSettingProvider.notifier),
                    ref.read(departmentPrinterProvider.notifier),
                    ref.read(deviceProvider.notifier),
                  ),
              child: Builder(
                builder: (context) {
                  final editPrinterFormBloc =
                      context.read<EditPrinterFormBloc>();
                  return FormBlocListener<
                    EditPrinterFormBloc,
                    PrinterSettingModel,
                    String
                  >(
                    onSubmitting: (context, state) {
                      LoadingDialog.show(context);
                      prints('on submit');
                    },
                    onSuccess: (context, state) async {
                      prints('on success');

                      if (_selectedPrinter != null) {
                        // await _disconnectPrinter();
                        // await Future.delayed(const Duration(seconds: 1));
                        // await _connectToPrinter(_selectedPrinter);
                      }
                      LoadingDialog.hide(context);
                      await Future.delayed(Duration(milliseconds: 200));
                      ref
                          .read(myNavigatorProvider.notifier)
                          .setSelectedTab(4200, 'printers'.tr());
                    },
                    onFailure: (context, state) {
                      LoadingDialog.hide(context);
                      prints('on fail');
                      ThemeSnackBar.showSnackBar(
                        context,
                        state.failureResponse!,
                      );
                    },
                    onSubmissionFailed: (context, state) {
                      LoadingDialog.hide(context);
                      prints('on sub fail');
                      prints(state.currentStep);
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 10.h),
                                Text(
                                  navState.data.name,
                                  style: AppTheme.h1TextStyle(),
                                ),
                                SizedBox(height: 10.h),
                                const Divider(thickness: 1),
                                SizedBox(height: 10.h),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // list interfaces
                                    MyDropdownBlocBuilder(
                                      isEnabled: true,
                                      label: 'connection'.tr() /*"Interface"*/,
                                      selectFieldBloc:
                                          editPrinterFormBloc.printerInterface,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == 'bluetooth'.tr()) {
                                            isInterfaceBluetooth = true;
                                          } else {
                                            isInterfaceBluetooth = false;
                                          }
                                        });
                                      },
                                    ),
                                    MyTextFieldBlocBuilder(
                                      isEnabled: true,
                                      textFieldBloc: editPrinterFormBloc.name,
                                      keyboardType: TextInputType.name,
                                      labelText: 'name'.tr(),
                                      hintText: 'enterPrinterName'.tr(),
                                      inputFormatters: const [],
                                      textCapitalization:
                                          TextCapitalization.characters,
                                    ),

                                    MyTextFieldBlocBuilder(
                                      isEnabled: !isInterfaceBluetooth,
                                      textFieldBloc:
                                          editPrinterFormBloc
                                              .printerModelDevice,
                                      keyboardType: TextInputType.name,
                                      labelText: 'model'.tr(),
                                      hintText: 'printerModel'.tr(),
                                      inputFormatters: const [],
                                      textCapitalization:
                                          TextCapitalization.characters,
                                    ),

                                    Visibility(
                                      visible: isInterfaceBluetooth,
                                      child: const Space(10),
                                    ),

                                    bluetoothWidgets(editPrinterFormBloc, true),

                                    // list paperwidth
                                    MyDropdownBlocBuilder(
                                      isEnabled: true,
                                      label:
                                          'paperWidth'.tr() /*"Paper width"*/,
                                      selectFieldBloc:
                                          editPrinterFormBloc.printerPaperWidth,
                                      onChanged: (value) {
                                        setState(() {
                                          paperWidth = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 15),
                                    MyTextFieldBlocBuilder(
                                      isEnabled: !isInterfaceBluetooth,
                                      textFieldBloc:
                                          editPrinterFormBloc.ipAddress,
                                      keyboardType: TextInputType.number,
                                      labelText: 'printerIpAddress'.tr(),
                                      hintText: 'ipAddress'.tr(),
                                      inputFormatters: const [],
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      decoration: UIUtils.createInputDecoration(
                                        labelText: '',
                                        hintText: '',
                                      ),
                                    ),
                                    const SizedBox(height: 15),

                                    // MyTextFieldBlocBuilder(
                                    //   isEnabled: true,
                                    //   textFieldBloc:
                                    //       editPrinterFormBloc.cashDrawerCommand,
                                    //   keyboardType: TextInputType.number,
                                    //   labelText: 'cashDrawerCommand'.tr(),
                                    //   hintText: '10,23,23',
                                    //   inputFormatters: const [],
                                    //   textCapitalization:
                                    //       TextCapitalization.characters,
                                    //   decoration: UIUtils.createInputDecoration(
                                    //     labelText: '',
                                    //     hintText: '10,23,23',
                                    //   ),
                                    // ),
                                    printerOptions(
                                      editPrinterFormBloc,
                                      true,
                                      isFeatureActive,
                                    ),
                                    isFeatureActive
                                        ? DepartmentPrinterCheckbox(
                                          initialSelectedDepartments:
                                              initDpModels,
                                          isEnabled:
                                              isFeatureActive
                                                  ? editPrinterFormBloc
                                                      .printOrders
                                                      .value
                                                  : false,
                                          onSelectionChanged: (selectedList) {
                                            selectedDpModels = selectedList;
                                            editPrinterFormBloc
                                                .departmentPrinter
                                                .updateValue(
                                                  jsonEncode(
                                                    selectedDpModels
                                                        .map((e) => e.id)
                                                        .toList(),
                                                  ),
                                                );
                                          },
                                        )
                                        : SizedBox.shrink(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        threeButtonBottom(
                          context,
                          navState.data,
                          editPrinterFormBloc,
                          true,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    }
    return Container();
  }

  Padding threeButtonBottom(
    BuildContext context,
    PrinterSettingModel printerSettingModel,
    EditPrinterFormBloc editPrinterFormBloc,
    bool hasSettingPermission,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: ScaleTap(
              onPressed: () async {
                await onPressDelete(
                  context,
                  printerSettingModel,
                  hasSettingPermission,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: scaffoldBackgroundColor,
                ),
                child: const Icon(FontAwesomeIcons.trashCan, color: Colors.red),
              ),
            ),
          ),
          const Expanded(flex: 3, child: SizedBox()),
          Expanded(
            child: ButtonTertiary(
              onPressed: () {
                ref
                    .read(myNavigatorProvider.notifier)
                    .setSelectedTab(4200, 'printers'.tr());
              },
              text: 'cancel'.tr(),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 2,
            child: ButtonBottom(
              'printTest'.tr(),
              press: () async {
                prints('IP: ${editPrinterFormBloc.ipAddress.value}');
                if (isInterfaceBluetooth) {
                  // if (_selectedPrinter != null) {
                  //   // await _disconnectPrinter();
                  //   // await Future.delayed(const Duration(seconds: 1));
                  //   await _connectToPrinter(_selectedPrinter);
                  // }
                } else {
                  prints('BUKAN BLEEEEEE');
                }
                ref
                    .read(printerSettingProvider.notifier)
                    .printTest(
                      isInterfaceBluetooth: isInterfaceBluetooth,
                      ipAddress: editPrinterFormBloc.ipAddress.value,
                      paperWidth: ReceiptPrinterService.getPaperWidth(
                        paperWidth == 'mm58'.tr()
                            ? PaperWidthEnum.paperWidth58mm
                            : PaperWidthEnum.paperWidth80mm,
                      ),
                    
                      onError: (message, ip) async {
                        DialogUtils.printerErrorDialogue(
                          context,
                          message,
                          ip,
                          null,
                        );
                      },
                    );
              },
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: ButtonBottom(
              'save'.tr(),
              press: () async {
                // for prints again prints cache yg lama
                // prints("_selectedPrinter!.toJson()");
                // prints(_selectedPrinter?.toJson());
                // bool togglePrintOrders = editPrinterFormBloc.printOrders.value;
                // if (togglePrintOrders == true) {
                //   // check dulu dengan yg current

                //   // yg asal tutup, then nak ubah ke open
                //   if (ps.printOrders != togglePrintOrders) {
                //     List<PrintReceiptCacheModel> listPendingPRC =
                //         await printReceiptCacheFacade
                //             .getListPrintReceiptCacheWithPendingStatus();
                //     if (listPendingPRC.isNotEmpty) {
                //       final globalContext = navigatorKey.currentContext;
                //       if (globalContext != null) {
                //         CustomDialog.show(
                //           globalContext,
                //           icon: FontAwesomeIcons.receipt,
                //           dialogType: DialogType.warning,
                //           title: 'unPrintOrders'.tr(),
                //           description: "unPrintOrdersDesc".tr(),
                //           btnCancelText: 'cancel'.tr(),
                //           btnOkText: 'ok'.tr(),
                //           btnCancelOnPress: () async {
                //             NavigationUtils.pop(globalContext);
                //             // mark status prints cache as cancelled
                //             final updateListPRC =
                //                 listPendingPRC
                //                     .map(
                //                       (prc) => prc.copyWith(
                //                         status: PrintCacheStatusEnum.cancel,
                //                       ),
                //                     )
                //                     .toList();
                //             // then delete the prints cache
                //             await Future.wait(
                //               updateListPRC.map(
                //                 (prc) => printReceiptCacheFacade.update(prc),
                //               ),
                //             );

                //             await printReceiptCacheFacade
                //                 .deleteBySuccessAndCancelStatusAndFailed();
                //           },
                //           btnOkOnPress: () async {
                //             NavigationUtils.pop(globalContext);
                //             // at this time, the page alrerady turn to list printer
                //             await _printerSettingFacade
                //                 .onHandlePrintVoidAndKitchen(
                //                   onSuccess: () {},
                //                   onError: (message, ipAdd) {},
                //                   departmentType:
                //                       null, // will prints for kitchen and void
                //                   onSuccessPrintReceiptCache: (list) {},
                //                 );
                //           },
                //         );
                //       }
                //     }
                //   }
                // }
                onPressSave(editPrinterFormBloc, hasSettingPermission);
              },
            ),
          ),
        ],
      ),
    );
  }

  void onPressSave(
    EditPrinterFormBloc editPrinterFormBloc,
    bool hasSettingPermission,
  ) {
    if (!hasSettingPermission) {
      DialogUtils.showPinDialog(
        context,
        permission: PermissionEnum.CHANGE_SETTINGS,
        onSuccess: () async {
          editPrinterFormBloc.submit();
        },
        onError: (error) {
          ThemeSnackBar.showSnackBar(context, error);
          return;
        },
      );
    }
    if (hasSettingPermission) {
      editPrinterFormBloc.submit();
    }
  }

  Future<void> onPressDelete(
    BuildContext context,
    PrinterSettingModel printerSettingModel,
    bool hasSettingPermission,
  ) async {
    if (!hasSettingPermission) {
      await DialogUtils.showPinDialog(
        context,
        permission: PermissionEnum.CHANGE_SETTINGS,
        onSuccess: () async {
          CustomDialog.show(
            context,
            icon: FontAwesomeIcons.trashCan,
            isDissmissable: true,
            dialogType: DialogType.warning,
            title: 'deletePrinter'.tr(),
            description: 'deletePrinterDescription'.tr(),
            btnCancelText: 'cancel'.tr(),
            btnCancelOnPress: () {
              NavigationUtils.pop(context);
            },
            btnOkText: 'delete'.tr(),
            btnOkOnPress: () async {
              NavigationUtils.pop(context);
              await ref
                  .read(printerSettingProvider.notifier)
                  .delete(printerSettingModel.id!);
              ref
                  .read(myNavigatorProvider.notifier)
                  .setSelectedTab(4200, 'printers'.tr());
            },
          );
        },
        onError: (error) {
          ThemeSnackBar.showSnackBar(context, error);
          return;
        },
      );
    }

    if (hasSettingPermission) {
      CustomDialog.show(
        context,
        icon: FontAwesomeIcons.trashCan,
        isDissmissable: true,
        dialogType: DialogType.warning,
        title: 'deletePrinter'.tr(),
        description: 'deletePrinterDescription'.tr(),
        btnCancelText: 'cancel'.tr(),
        btnCancelOnPress: () {
          NavigationUtils.pop(context);
        },
        btnOkText: 'delete'.tr(),
        btnOkOnPress: () async {
          NavigationUtils.pop(context);
          await ref
              .read(printerSettingProvider.notifier)
              .delete(printerSettingModel.id!);
          ref
              .read(myNavigatorProvider.notifier)
              .setSelectedTab(4200, 'printers'.tr());
        },
      );
    }
  }

  Widget bluetoothWidgets(
    EditPrinterFormBloc editPrinterFormBloc,
    bool hasSettingPermission,
  ) {
    // if (bluetoothState == 'OFF') {
    //   return Visibility(
    //     visible: isInterfaceBluetooth,
    //     child: Text(
    //       'Please turn on bluetooth',
    //       style: AppTheme.normalTextStyle(color: Colors.red),
    //     ),
    //   );
    // } else
    // {
    return Visibility(
      visible: isInterfaceBluetooth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10.h),
          Text('bluetoothPrinter'.tr(), style: AppTheme.normalTextStyle()),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Visibility(
                visible: isInterfaceBluetooth,
                child: Expanded(
                  flex: 5,
                  child: DropdownButtonFormField<PrinterModel>(
                    decoration: UIUtils.createInputDecoration(
                      labelText: '',
                      hintText: 'selectPrinter'.tr(),
                    ),
                    items: _getPrinterItems(),
                    value: _selectedPrinter,
                    onChanged:
                        hasSettingPermission
                            ? (PrinterModel? value) async {
                              setState(() {
                                _selectedPrinter = value;
                              });
                              // Do not connect here
                              if (value != null) {
                                editPrinterFormBloc.printerModelDevice
                                    .updateValue(value.name ?? '');
                                editPrinterFormBloc.ipAddress.updateValue(
                                  value.address ?? '',
                                );
                              }
                            }
                            : null,
                  ),
                ),
              ),
              Visibility(
                visible: isInterfaceBluetooth,
                child: const SizedBox(width: 10),
              ),
              Visibility(
                visible: isInterfaceBluetooth,
                child: Expanded(
                  child: Column(
                    children: [
                      ButtonBottom(
                        'scanForPrinter'.tr(),
                        press: () {
                          startScan(false);
                          //  _startUsbRefreshTimer();
                          // if (bluetoothState == 'OFF') {
                          //   ThemeSnackBar.showSnackBar(
                          //     context,
                          //     'Please turn on the bluetooth',
                          //   );
                          // }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
    // }
  }

  Column printerOptions(
    EditPrinterFormBloc editPrinterFormBloc,
    bool hasSettingPermission,
    bool isFeatureActive,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('printReceiptAndBills'.tr())),
            Flexible(
              child: SizedBox(
                width: 55,
                child: Switch(
                  value: isPrintReceiptBills,
                  onChanged:
                      hasSettingPermission
                          ? (value) async {
                            editPrinterFormBloc.printReceiptBills.updateValue(
                              value,
                            );
                            isPrintReceiptBills = value;

                            if (!value && isAutomaticPrintReceipt) {
                              editPrinterFormBloc.automaticallyPrintReceipt
                                  .updateValue(false);
                              isAutomaticPrintReceipt = false;
                            }

                            if (mounted) {
                              setState(() {});
                            }

                            // setState(() {});
                          }
                          : null,
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('automaticallyPrintReceipt'.tr())),
            // Flexible(
            //   child: SizedBox(
            //     width: 55,
            //     child: SwitchFieldBlocBuilder(
            //       isEnabled: hasSettingPermission ? isPrintReceiptBills : false,
            //       padding: EdgeInsets.zero,
            //       booleanFieldBloc:
            //           editPrinterFormBloc.automaticallyPrintReceipt,
            //       body: Container(),
            //     ),
            //   ),
            // ),
            Flexible(
              child: SizedBox(
                width: 55,
                child: Switch(
                  value: hasSettingPermission ? isAutomaticPrintReceipt : false,
                  onChanged:
                      hasSettingPermission
                          ? isPrintReceiptBills
                              ? (value) async {
                                await Future.microtask(() async {
                                  editPrinterFormBloc.automaticallyPrintReceipt
                                      .updateValue(value);
                                  isAutomaticPrintReceipt = value;
                                  if (mounted) {
                                    setState(() {});
                                  }
                                });

                                // setState(() {});
                              }
                              : null
                          : null, // use null to disabled the switch
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            isFeatureActive
                ? Expanded(child: Text('printOrders'.tr()))
                : Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('printOrders'.tr()),
                      Text(
                        'thisFeatureIsNotAvailable'.tr(),
                        style: textStyleNormal(color: kTextRed, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            Flexible(
              child: SizedBox(
                width: 55,
                child: Switch(
                  value: isFeatureActive ? isPrintOrders : false,
                  onChanged:
                      isFeatureActive
                          ? (hasSettingPermission
                              ? (value) async {
                                editPrinterFormBloc.printOrders.updateValue(
                                  value,
                                );
                                isPrintOrders = value;

                                if (mounted) {
                                  setState(() {});
                                }
                              }
                              : null)
                          : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<DropdownMenuItem<PrinterModel>> _getPrinterItems() {
    // Create dropdown items from the list of printers
    List<DropdownMenuItem<PrinterModel>> items = [];

    if (_printers.isEmpty) {
      // Handle the case when no printers are available
      items.add(const DropdownMenuItem(child: Text('No printers available')));
    } else {
      for (var printer in _printers) {
        items.add(
          DropdownMenuItem(
            value: printer,
            child: Text(printer.name ?? 'Unknown Device'),
          ),
        );
      }
    }
    return items;
  }
}
