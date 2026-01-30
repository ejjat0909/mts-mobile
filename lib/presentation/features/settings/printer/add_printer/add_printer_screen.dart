import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/enum/paper_width_enum.dart';
import 'package:mts/core/enums/permission_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';
import 'package:mts/providers/print_receipt_cache/print_receipt_cache_providers.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/ui_utils.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';
import 'package:mts/data/models/printer_interface/printer_interface_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/form_bloc/add_printer_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/plugins/flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:mts/plugins/flutter_thermal_printer/utils/printer.dart';
import 'package:mts/plugins/imin_printer/imin_printer.dart';
import 'package:mts/presentation/common/dialogs/loading_dialogue.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/button_bottom.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/my_dropdown_bloc_builder.dart';
import 'package:mts/presentation/common/widgets/my_text_field_bloc_builder.dart';
import 'package:mts/data/services/receipt_printer_service.dart';
import 'package:mts/presentation/features/settings/printer/add_printer/components/department_printer_checkbox.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/device/device_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddPrinterScreen extends ConsumerStatefulWidget {
  const AddPrinterScreen({super.key});

  @override
  ConsumerState<AddPrinterScreen> createState() => _AddPrinterScreenState();
}

class _AddPrinterScreenState extends ConsumerState<AddPrinterScreen> {
  // for printer
  final FlutterThermalPrinter _flutterThermalPrinter =
      FlutterThermalPrinter.instance;
  List<PrinterModel> _printers = [];
  PrinterModel? _selectedPrinter;
  final iminPrinter = IminPrinter();
  String bluetoothState = 'OFF';

  late PrinterInterfaceModel selectedInterface;
  late PrinterInterfaceModel selectedPaperWidth;
  bool isInterfaceBluetooth = true;
  String paperWidth = 'mm80'.tr();

  List<PrinterInterfaceModel> listPrinterInterfaces = [
    PrinterInterfaceModel(id: '-1', name: 'Choose Interface'),
    PrinterInterfaceModel(id: '0', name: 'Ethernet'),
    PrinterInterfaceModel(id: '1', name: 'Bluetooth'),
  ];

  List<PrinterInterfaceModel> listPrinterPaperWidth = [
    PrinterInterfaceModel(id: '-1', name: 'Choose Paper Width'),
    PrinterInterfaceModel(id: '0', name: 'mm80'),
    PrinterInterfaceModel(id: '1', name: 'mm58'),
  ];

  List<Widget> departmentPrinter = [];
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

    startScan();
    getListInterfaceAndPaperWidth();
    // _startUsbRefreshTimer();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (_selectedPrinter != null) {
      _flutterThermalPrinter.disconnect(_selectedPrinter!);
    }
    _devicesStreamSubscription
        ?.cancel(); // Cancel subscription to avoid memory leaks
    _usbRefreshTimer?.cancel(); // Cancel USB refresh timer
    _flutterThermalPrinter.stopScan();
    super.dispose();
  }

  Future<void> startScan() async {
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

          prints('LEPASSSSSSSSS SCANNN');
          prints(_printers.map((p) => p.name).toList());

          // Note: We don't filter USB printers by connection status here
          // USB printers should be shown in the list even if not connected yet
          // so users can select and connect to them

          // If we had a selected USB printer that's no longer in the list, clear it
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
        });
      });
    } catch (e) {
      prints('Error starting printer scan: $e');
      setState(() {
        bluetoothState = 'OFF';
      });
    }
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

  Future<void> _disconnectPrinter() async {
    if (_selectedPrinter != null && _selectedPrinter!.isConnected == true) {
      try {
        await _flutterThermalPrinter.disconnect(_selectedPrinter!);
        setState(() {
          // Don't set _selectedPrinter to null - just update connection status
          // This keeps the selection in the dropdown
          _selectedPrinter!.isConnected = false;
        });
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
    setState(() {
      _selectedPrinter = null;
    });
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
        bool connectionResult = await _flutterThermalPrinter.connect(printer);
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

            // bool connectionResult = await _flutterThermalPrinter.connect(
            //   printer,
            // );
            prints('CONNECTION RESULT: $connectionResult');

            if (connectionResult) {
              // Wait a moment for the connection to stabilize
              await Future.delayed(Duration(milliseconds: 500));

              setState(() {
                _selectedPrinter = printer;
                // Update the printer's connection status based on connect result
                printer.isConnected = true;
              });

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
            ThemeSnackBar.showSnackBar(context, 'Failed to connect: $error');
          }
        } else {
          prints('PRINTER ALREADY CONNECTED');
        }
      } else {
        // for ble and network
        if (printer.isConnected != true) {
          prints('CONNECT PRINTER ${printer.name} ${printer.address}');
          try {
            bool connected = await _flutterThermalPrinter.connect(printer);
            if (connected) {
              setState(() {
                _selectedPrinter = printer;
                printer.isConnected = true;
              });
              // ThemeSnackBar.showSnackBar(
              //   context,
              //   'Successfully connected to ${printer.name}',
              // );
            } else {
              // Don't set _selectedPrinter to null - keep the selection in dropdown
              // but update the connection status
              setState(() {
                printer.isConnected = false;
              });
              // ThemeSnackBar.showSnackBar(
              //   context,
              //   'Failed to connect to ${printer.name}',
              // );
            }
          } catch (error) {
            prints('Error connecting to printer: $error');
            // Don't set _selectedPrinter to null - keep the selection in dropdown
            setState(() {
              printer.isConnected = false;
            });
            // ThemeSnackBar.showSnackBar(
            //   context,
            //   'Error connecting to ${printer.name}: $error',
            // );
          }
        } else {
          prints('PrinterModel already connected');
          setState(() {
            _selectedPrinter = printer;
          });
        }
      }
    } else {
      prints('NO PRINTER SELECTED');
      // ThemeSnackBar.showSnackBar(context, 'No Device Selected');
      _disconnectAndClearPrinter();
    }
  }

  void getListInterfaceAndPaperWidth() {
    selectedInterface = listPrinterInterfaces.firstWhere((device) => true);
    if (listPrinterInterfaces.isNotEmpty) {
      selectedInterface = listPrinterInterfaces[0];
    }

    selectedPaperWidth = listPrinterPaperWidth.firstWhere((pw) => true);
    if (listPrinterPaperWidth.isNotEmpty) {
      selectedPaperWidth = listPrinterPaperWidth[0];
    }
  }

  // void _startUsbRefreshTimer() {
  //   // Refresh USB devices every 3 seconds to detect disconnections
  //   _usbRefreshTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
  //     if (mounted) {
  //       // Trigger a new scan to refresh USB device list
  //       _flutterThermalPrinter.getPrinters(
  //         connectionTypes: [ConnectionTypeEnum.USB, ConnectionTypeEnum.BLE],
  //       );
  //     }
  //   });
  // }

  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // permission notifier
    final permissionNotifier = ref.watch(permissionProvider.notifier);
    final featureCompNotifier = ref.watch(featureCompanyProvider.notifier);
    final isFeatureActive = featureCompNotifier.isDepartmentPrintersActive();

    bool hasPermissionSettings =
        permissionNotifier.hasChangeSettingsPermission();
    // hasPermissionSettings = true;
    return Container(
      // to make the container at the center of the screen
      margin: const EdgeInsets.only(top: 20, left: 50, right: 50, bottom: 20),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(10.sp),
      ),
      // wrap the button bottom with the form bloc
      child: BlocProvider(
        create:
            (context) => AddPrinterFormBloc(
              isInterfaceBluetooth,
              context,
              ref.read(printerSettingProvider.notifier),
              ref.read(deviceProvider.notifier),
            ),
        child: Builder(
          builder: (context) {
            final addPrinterFormBloc = context.read<AddPrinterFormBloc>();

            return FormBlocListener<
              AddPrinterFormBloc,
              PrinterSettingModel,
              String
            >(
              onSubmitting: (context, state) {
                LoadingDialog.show(context);
              },
              onSuccess: (context, state) async {
                if (_selectedPrinter != null) {
                  if (isInterfaceBluetooth) {
                    // await _disconnectPrinter();
                    // await _connectToPrinter(_selectedPrinter);
                  }
                }
                LoadingDialog.hide(context);
                await Future.delayed(Duration(milliseconds: 200));
                ref
                    .read(myNavigatorProvider.notifier)
                    .setSelectedTab(4200, 'printers'.tr());
              },
              onFailure: (context, state) {
                LoadingDialog.hide(context);
                ThemeSnackBar.showSnackBar(context, state.failureResponse!);
              },
              onSubmissionFailed: (context, state) {
                LoadingDialog.hide(context);
              },
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.h),
                          Text(
                            'addPrinter'.tr(),
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
                                // isEnabled: hasPermissionSettings,
                                label: 'connection'.tr() /*"Interface"*/,
                                selectFieldBloc:
                                    addPrinterFormBloc.printerInterface,
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
                                textFieldBloc: addPrinterFormBloc.name,
                                keyboardType: TextInputType.name,
                                labelText: 'name'.tr(),
                                hintText: 'enterPrinterName'.tr(),
                                inputFormatters: const [],
                                textCapitalization:
                                    TextCapitalization.characters,
                              ),

                              MyTextFieldBlocBuilder(
                                isEnabled: !isInterfaceBluetooth,
                                // isEnabled: true,
                                textFieldBloc: addPrinterFormBloc.printerModel,
                                keyboardType: TextInputType.name,
                                labelText: 'model'.tr(),
                                hintText: 'printerModel'.tr(),
                                inputFormatters: const [],
                                textCapitalization:
                                    TextCapitalization.characters,
                              ),

                              bluetoothWidgets(addPrinterFormBloc, true),

                              MyTextFieldBlocBuilder(
                                isEnabled: !isInterfaceBluetooth,
                                textFieldBloc: addPrinterFormBloc.ipAddress,
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
                              // list paperwidth
                              MyDropdownBlocBuilder(
                                isEnabled: true,
                                label: 'paperWidth'.tr() /*"Paper width"*/,
                                selectFieldBloc:
                                    addPrinterFormBloc.printerPaperWidth,
                                onChanged: (value) {
                                  setState(() {
                                    paperWidth = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 15),

                              // MyTextFieldBlocBuilder(
                              //   isEnabled: true,
                              //   textFieldBloc:
                              //       addPrinterFormBloc.cashDrawerCommand,
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
                                addPrinterFormBloc,
                                true,
                                isFeatureActive,
                              ),

                              isFeatureActive
                                  ? DepartmentPrinterCheckbox(
                                    initialSelectedDepartments: const [],
                                    isEnabled:
                                        isFeatureActive
                                            ? addPrinterFormBloc
                                                .printOrders
                                                .value
                                            : false,
                                    // isEnabled:
                                    //     isFeatureActive
                                    //         ? (hasPermissionSettings
                                    //             ? addPrinterFormBloc
                                    //                 .printOrders
                                    //                 .value
                                    //             : false)
                                    //         : false,
                                    onSelectionChanged: (selectedList) {
                                      selectedDpModels = selectedList;
                                      addPrinterFormBloc.departmentPrinter
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
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
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
                              // LogUtils.log(
                              //   'paperwidth ${paperWidth == 'mm80'.tr()}',
                              // );
                              ref
                                  .read(printerSettingProvider.notifier)
                                  .printTest(
                                    isInterfaceBluetooth: isInterfaceBluetooth,
                                    ipAddress:
                                        addPrinterFormBloc.ipAddress.value,
                                    paperWidth:
                                        ReceiptPrinterService.getPaperWidth(
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
                              // if (addPrinterFormBloc.printOrders.value ==
                              //     true) {
                              //   List<PrintReceiptCacheModel> listPendingPRC =
                              //       await printReceiptCacheFacade
                              //           .getListPrintReceiptCacheWithPendingStatus();
                              //   if (listPendingPRC.isNotEmpty) {
                              //     final globalContext =
                              //         navigatorKey.currentContext;
                              //     if (globalContext != null) {
                              //       CustomDialog.show(
                              //         globalContext,
                              //         icon: FontAwesomeIcons.receipt,
                              //         dialogType: DialogType.warning,
                              //         title: 'unPrintOrders'.tr(),
                              //         description: "unPrintOrdersDesc".tr(),
                              //         btnCancelText: 'cancel'.tr(),
                              //         btnOkText: 'ok'.tr(),
                              //         btnCancelOnPress: () async {
                              //           NavigationUtils.pop(globalContext);
                              //           // mark status prints cache as cancelled
                              //           final updateListPRC =
                              //               listPendingPRC
                              //                   .map(
                              //                     (prc) => prc.copyWith(
                              //                       status:
                              //                           PrintCacheStatusEnum
                              //                               .cancel,
                              //                     ),
                              //                   )
                              //                   .toList();
                              //           // then delete the prints cache
                              //           await Future.wait(
                              //             updateListPRC.map(
                              //               (prc) => printReceiptCacheFacade
                              //                   .update(prc),
                              //             ),
                              //           );

                              //           await printReceiptCacheFacade
                              //               .deleteBySuccessAndCancelStatusAndFailed();
                              //         },
                              //         btnOkOnPress: () async {
                              //           NavigationUtils.pop(globalContext);
                              //           await _printerSettingFacade
                              //               .onHandlePrintVoidAndKitchen(
                              //                 onSuccess: () {},
                              //                 onError: (message, ipAdd) {},
                              //                 departmentType:
                              //                     null, // will prints for kitchen and void
                              //                 onSuccessPrintReceiptCache:
                              //                     (list) {},
                              //               );
                              //         },
                              //       );
                              //     }
                              //   }
                              // }

                              // then save the printer setting
                              await onPressSave(
                                addPrinterFormBloc,
                                hasPermissionSettings,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> onPressSave(
    AddPrinterFormBloc addPrinterFormBloc,
    bool hasSettingPermission,
  ) async {
    if (!hasSettingPermission) {
      await DialogUtils.showPinDialog(
        context,
        permission: PermissionEnum.CHANGE_SETTINGS,
        onSuccess: () async {
          addPrinterFormBloc.submit();
        },
        onError: (error) {
          ThemeSnackBar.showSnackBar(context, error);
          return;
        },
      );
    }

    if (hasSettingPermission) {
      addPrinterFormBloc.submit();
    }
  }

  Widget bluetoothWidgets(
    AddPrinterFormBloc addPrinterFormBloc,
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
            children: [
              Expanded(
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
                              addPrinterFormBloc.ipAddress.updateValue(
                                value.address ?? '',
                              );
                            }
                            await _disconnectPrinter();
                            if (value != null) {
                              addPrinterFormBloc.printerModel.updateValue(
                                value.name ?? '',
                              );

                              prints('CONNECTED TO ${value.name}');
                              _connectToPrinter(value);
                            }
                          }
                          : null,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ButtonTertiary(
                  onPressed: () {
                    startScan();
                    // _startUsbRefreshTimer();
                    // if (bluetoothState == 'OFF') {
                    //   ThemeSnackBar.showSnackBar(
                    //     context,
                    //     'Please turn on the bluetooth',
                    //   );
                    // }
                  },
                  text: 'scanForPrinter'.tr(),
                ),
              ),
              // ElevatedButton(
              //   style: ElevatedButton.styleFrom(
              //       backgroundColor: _connected ? Colors.red : Colors.green),
              //   onPressed: _connected ? _disconnect : _connect,
              //   child: Padding(
              //     padding: const EdgeInsets.symmetric(vertical: 12),
              //     child: Text(
              //       _connected ? 'disconnect'.tr() : 'connect'.tr(),
              //       style: const TextStyle(color: Colors.white),
              //     ),
              //   ),
              // )
            ],
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
    // }
  }

  WidgetStateProperty<Color?>? getThumbColor() {
    return WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      // Check if the thumb is in the default state (no states are active)
      if (states.isEmpty) {
        return kPrimaryColor;
      }
      // If any other state is active, return null to use the default theme color
      return null;
    });
  }

  Column printerOptions(
    AddPrinterFormBloc addPrinterFormBloc,
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
                            addPrinterFormBloc.printReceiptBills.updateValue(
                              value,
                            );
                            isPrintReceiptBills = value;

                            // If printReceiptBills is turned off, also turn off automaticallyPrintReceipt
                            if (!value && isAutomaticPrintReceipt) {
                              addPrinterFormBloc.automaticallyPrintReceipt
                                  .updateValue(false);
                              isAutomaticPrintReceipt = false;
                            }

                            setState(() {});
                            // _scrollToBottom();
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
            //           addPrinterFormBloc.automaticallyPrintReceipt,
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
                                  addPrinterFormBloc.automaticallyPrintReceipt
                                      .updateValue(value);
                                  isAutomaticPrintReceipt = value;
                                  setState(() {});
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
                                addPrinterFormBloc.printOrders.updateValue(
                                  value,
                                );
                                isPrintOrders = value;

                                setState(() {});
                                _scrollToBottom();
                                // setState(() {});
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
}
