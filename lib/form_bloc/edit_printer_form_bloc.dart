import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/enum/paper_width_enum.dart';
import 'package:mts/core/enum/printer_setting_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/validation_utils.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/providers/department_printer/department_printer_providers.dart';
import 'package:mts/providers/device/device_providers.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';

class EditPrinterFormBloc extends FormBloc<PrinterSettingModel, String> {
  final PrinterSettingModel printerModel;
  final BuildContext context;
  final PrinterSettingNotifier _printerSettingNotifier;
  final DepartmentPrinterNotifier _departmentPrinterNotifier;
  final DeviceNotifier _deviceNotifier;

  final name = TextFieldBloc(validators: [ValidationUtils.validateRequired]);

  final printerInterface = SelectFieldBloc();

  final printerPaperWidth = SelectFieldBloc();

  final ipAddress = TextFieldBloc(
    validators: [ValidationUtils.validateRequired],
  );
  final printerModelDevice = TextFieldBloc(
    validators: [ValidationUtils.validateRequired],
  );

  final departmentPrinter = TextFieldBloc();

  final cashDrawerCommand = TextFieldBloc(
    validators: [ValidationUtils.validateCashDrawer],
  );

  final printReceiptBills = BooleanFieldBloc();
  final printOrders = BooleanFieldBloc();
  final automaticallyPrintReceipt = BooleanFieldBloc();

  EditPrinterFormBloc(
    this.printerModel,
    this.context,
    this._printerSettingNotifier,
    this._departmentPrinterNotifier,
    this._deviceNotifier,
  ) {
    name.updateValue(printerModel.name!);
    cashDrawerCommand.updateValue(printerModel.customCdCommand ?? '');
    printerInterface.updateValue(printerModel.interface!);
    printerModelDevice.updateValue(printerModel.model!);

    printerInterface.addItem('bluetooth'.tr());
    printerInterface.addItem('ethernet'.tr());

    // check interface id
    if (printerModel.interface == PrinterSettingEnum.ethernet) {
      printerInterface.updateInitialValue('ethernet'.tr());
    } else if (printerModel.interface == PrinterSettingEnum.bluetooth) {
      printerInterface.updateInitialValue('bluetooth'.tr());
    }

    printerPaperWidth.addItem('mm80'.tr());
    printerPaperWidth.addItem('mm58'.tr());

    // check paper width
    if (printerModel.paperWidth == PaperWidthEnum.paperWidth80mm) {
      printerPaperWidth.updateInitialValue('mm80'.tr());
    } else if (printerModel.paperWidth == PaperWidthEnum.paperWidth58mm) {
      printerPaperWidth.updateInitialValue('mm58'.tr());
    }

    ipAddress.updateValue(printerModel.identifierAddress ?? '');

    printReceiptBills.updateValue(printerModel.printReceiptBills ?? false);
    printOrders.updateValue(printerModel.printOrders ?? false);
    automaticallyPrintReceipt.updateValue(
      printerModel.automaticallyPrintReceipt ?? false,
    );

    addFieldBlocs(
      fieldBlocs: [
        name,
        printerInterface,
        printerPaperWidth,
        ipAddress,
        printReceiptBills,
        printOrders,
        automaticallyPrintReceipt,
        printerModelDevice,
        departmentPrinter,
        //  cashDrawerCommand,
      ],
    );

    // Initialize department printer data asynchronously
    _initDepartmentPrinter();
  }

  Future<void> _initDepartmentPrinter() async {
    if (printerModel.departmentPrinterJson != null) {
      List<String> dpmIds = List<String>.from(
        json.decode(printerModel.departmentPrinterJson ?? '[]'),
      );
      List<DepartmentPrinterModel> initDpModels =
          await _departmentPrinterNotifier.getListDepartmentPrintersFromIds(
            dpmIds,
          );

      departmentPrinter.updateValue(
        jsonEncode(initDpModels.map((dpm) => dpm.id).toList()),
      );
    }
  }

  @override
  Future<void> onSubmitting() async {
    OutletModel outletModel = ServiceLocator.get<OutletModel>();
    PosDeviceModel? posDeviceModel =
        await _deviceNotifier.getLatestDeviceModel();
    try {
      prints('PRINTER ID ${printerModel.id}');
      if (printerModel.id != null) {
        prints('PRINTER ID TAK NULL');
        PrinterSettingModel printerSettingModel = PrinterSettingModel(
          id: printerModel.id,
          outletId: outletModel.id!,
          name: name.value,
          model: printerModelDevice.value,
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

        bool isUpdated = await _printerSettingNotifier.updatePrinterSetting(
          printerSettingModel,
        );

        if (!isUpdated) {
          ipAddress.addFieldError('ipAddressExist'.tr());
          emitFailure(failureResponse: 'ipAddressExist'.tr());
          return;
        }

        // prints(jsonEncode(printerSettingModel));

        emitSuccess(canSubmitAgain: true, successResponse: printerSettingModel);
      }
    } catch (e) {
      emitFailure(failureResponse: e.toString());
    }
  }
}
