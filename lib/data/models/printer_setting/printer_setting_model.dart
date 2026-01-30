import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class PrinterSettingModel {
  /// Model name for sync handler registry
  static const String modelName = 'PrinterSetting';
  static const String modelBoxName = 'printer_setting_box';
  String? id;
  String? name;
  String? model;
  String? interface;
  String? identifierAddress;
  String? paperWidth;
  bool? printReceiptBills;
  bool? printOrders;
  bool? automaticallyPrintReceipt;
  String? categories;
  String? departmentPrinterJson;
  String? outletId;

  String? customCdCommand; // custom cash drawer command
  String? posDeviceId;

  // dont have for db, use in printer setting facade uiGetAllPrinter()
  String? posDeviceName;
  bool? isPosDeviceSame;

  DateTime? createdAt;
  DateTime? updatedAt;

  PrinterSettingModel({
    this.id,
    this.name,
    this.model,
    this.interface,
    this.identifierAddress,
    this.paperWidth,
    this.printReceiptBills,
    this.categories,
    this.departmentPrinterJson,
    this.printOrders,
    this.automaticallyPrintReceipt,
    this.outletId,
    this.customCdCommand,
    this.posDeviceId,
    this.createdAt,
    this.updatedAt,
  });

  PrinterSettingModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    name = FormatUtils.parseToString(json['name']);
    model = FormatUtils.parseToString(json['model']);
    interface = FormatUtils.parseToString(json['interface']);
    identifierAddress = FormatUtils.parseToString(json['identifier_address']);
    paperWidth = (json['paper_width']).toString();
    categories = FormatUtils.parseToString(json['categories']);
    departmentPrinterJson = FormatUtils.parseToString(
      json['department_printer_json'],
    );
    printReceiptBills = FormatUtils.parseToBool(json['print_receipt_bills']);
    printOrders = FormatUtils.parseToBool(json['print_orders']);
    automaticallyPrintReceipt = FormatUtils.parseToBool(
      json['automatically_print_receipt'],
    );
    outletId = FormatUtils.parseToString(json['outlet_id']);
    customCdCommand = FormatUtils.parseToString(json['custom_cd_command']);
    posDeviceId = FormatUtils.parseToString(json['pos_device_id']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['model'] = model;
    data['interface'] = interface;
    data['categories'] = categories;
    data['department_printer_json'] = departmentPrinterJson;
    data['identifier_address'] = identifierAddress;
    data['paper_width'] = paperWidth;
    data['print_receipt_bills'] = FormatUtils.boolToInt(printReceiptBills);
    data['print_orders'] = FormatUtils.boolToInt(printOrders);
    data['outlet_id'] = outletId;
    data['custom_cd_command'] = customCdCommand;
    data['pos_device_id'] = posDeviceId;
    data['automatically_print_receipt'] = FormatUtils.boolToInt(
      automaticallyPrintReceipt,
    );
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }

    return data;
  }

  // copy with
  PrinterSettingModel copyWith({
    String? id,
    String? name,
    String? model,
    String? interface,
    String? identifierAddress,
    String? paperWidth,
    bool? printReceiptBills,
    bool? printOrders,
    bool? automaticallyPrintReceipt,
    String? categories,
    String? departmentJson,
    String? posDeviceId,
    String? customCdCommand,
    String? outletId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrinterSettingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      interface: interface ?? this.interface,
      identifierAddress: identifierAddress ?? this.identifierAddress,
      paperWidth: paperWidth ?? this.paperWidth,
      printReceiptBills: printReceiptBills ?? this.printReceiptBills,
      printOrders: printOrders ?? this.printOrders,
      automaticallyPrintReceipt:
          automaticallyPrintReceipt ?? this.automaticallyPrintReceipt,
      departmentPrinterJson: departmentJson ?? departmentPrinterJson,
      categories: categories ?? this.categories,
      outletId: outletId ?? this.outletId,
      customCdCommand: customCdCommand, // can be null
      posDeviceId: posDeviceId ?? this.posDeviceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
