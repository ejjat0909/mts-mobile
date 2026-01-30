import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/enum/paper_width_enum.dart';
import 'package:mts/core/enum/printer_setting_enum.dart';
import 'package:mts/core/utils/validation_utils.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/providers/device/device_providers.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';

class AddPrinterFormBloc extends FormBloc<PrinterSettingModel, String> {
  final BuildContext context;
  final PrinterSettingNotifier _printerSettingNotifier;
  final DeviceNotifier _deviceNotifier;

  final name = TextFieldBloc(validators: [ValidationUtils.validateRequired]);

  final printerInterface = SelectFieldBloc(
    validators: [ValidationUtils.validateRequired],
  );
  final printerPaperWidth = SelectFieldBloc(
    validators: [ValidationUtils.validateRequired],
  );

  final ipAddress = TextFieldBloc();
  final printerModel = TextFieldBloc(
    validators: [ValidationUtils.validateRequired],
  );

  final printerBluetoothAddress = SelectFieldBloc(
    validators: [ValidationUtils.validateRequired],
  );

  final cashDrawerCommand = TextFieldBloc(
    validators: [ValidationUtils.validateCashDrawer],
  );

  final departmentPrinter = TextFieldBloc();

  final printReceiptBills = BooleanFieldBloc(initialValue: false);
  final printOrders = BooleanFieldBloc(initialValue: false);
  final automaticallyPrintReceipt = BooleanFieldBloc(initialValue: false);

  AddPrinterFormBloc(
    bool isInterfaceBluetooth,
    this.context,
    this._printerSettingNotifier,
    this._deviceNotifier,
  ) {
    cashDrawerCommand.updateInitialValue('14,10,00,00,00');
    printerInterface.addItem('bluetooth'.tr());
    printerInterface.addItem('ethernet'.tr());
    printerInterface.updateInitialValue('bluetooth'.tr());

    printerPaperWidth.addItem('mm80'.tr());
    printerPaperWidth.addItem('mm58'.tr());
    printerPaperWidth.updateInitialValue('mm80'.tr());

    addFieldBlocs(
      fieldBlocs: [
        name,
        printerInterface,
        printerPaperWidth,
        departmentPrinter,
        ipAddress,
        printReceiptBills,
        printOrders,
        automaticallyPrintReceipt,
        printerModel,
        //  cashDrawerCommand,
      ],
    );

    // Listen to changes in printerInterface to apply conditional validation
    printerInterface.onValueChanges(
      onData: (previous, current) async* {
        if (current.value == 'Bluetooth') {
          // Make printerBluetoothAddress required if interface is Bluetooth
          printerBluetoothAddress.addValidators([FieldBlocValidators.required]);
        } else {
          // Remove the required validator if the interface is not Bluetooth
          printerBluetoothAddress.updateValidators([]);
        }
      },
    );

    // Listen to changes in printerInterface to apply conditional validation
    printerInterface.onValueChanges(
      onData: (previous, current) async* {
        if (current.value != 'bluetooth'.tr()) {
          // Add IP address required validation for Ethernet
          ipAddress.addValidators([
            (value) {
              if (value.isEmpty) {
                return 'ipAddressRequired'.tr();
              }
              final ipRegex = RegExp(r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$');
              if (!ipRegex.hasMatch(value)) {
                return 'Enter a valid IP address';
              }
              return null;
            },
          ]);
        } else {
          // Clear validators if the printer interface is not Ethernet
          ipAddress.updateValidators([]);
        }
      },
    );
  }

  @override
  Future<void> onSubmitting() async {
    OutletModel outletModel = ServiceLocator.get<OutletModel>();
    PosDeviceModel? posDeviceModel =
        await _deviceNotifier.getLatestDeviceModel();
    try {
      PrinterSettingModel newPrinterSettingModel = PrinterSettingModel(
        outletId: outletModel.id!,
        name: name.value,
        model: printerModel.value,
        interface:
            printerInterface.value == 'bluetooth'.tr()
                ? PrinterSettingEnum.bluetooth
                : printerInterface.value == 'ethernet'.tr()
                ? PrinterSettingEnum.ethernet
                : PrinterSettingEnum.usb,
        identifierAddress: ipAddress.value,
        paperWidth:
            printerPaperWidth.value == 'mm80'.tr()
                ? PaperWidthEnum.paperWidth80mm
                : PaperWidthEnum.paperWidth58mm,
        printReceiptBills: printReceiptBills.value,
        printOrders: printOrders.value,
        automaticallyPrintReceipt: automaticallyPrintReceipt.value,
        departmentPrinterJson:
            departmentPrinter.value.isEmpty ? '[]' : departmentPrinter.value,
        posDeviceId: posDeviceModel?.id,
        customCdCommand: cashDrawerCommand.value,
      );

      bool isIpExist = await _printerSettingNotifier.checkIpAddressExist(
        ipAddress.value,
      );
      if (isIpExist) {
        ipAddress.addFieldError('ipAddressExist'.tr());
        emitFailure(failureResponse: 'ipAddressExist'.tr());
        return;
      }

      await _printerSettingNotifier.insert(context, newPrinterSettingModel);

      emitSuccess(
        canSubmitAgain: true,
        successResponse: newPrinterSettingModel,
      );
    } catch (exception) {
      emitFailure(failureResponse: 'Server error');
    }
  }
}
