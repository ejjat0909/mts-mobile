import 'dart:convert';

import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/print_receipt_cache/print_data_payload.dart';

class PrintReceiptCacheModel {
  static const String modelName = 'PrintReceiptCache';
  static const String modelBoxName = 'print_receipt_cache_box';

  String? id;
  String? saleId;
  String? outletId;
  String? shiftId;
  String? printType;
  int? orderNumber;
  String? tableNumber;
  String? paperWidth;
  PrintDataPayload? printData;
  String? departmentPrinterId;
  String? printerSettingId;
  String? posDeviceId;
  // print cache status enum
  // static const String success = '1';
  // static const String pending = '2';
  // static const String failed = '3';
  String? status;
  int? printedAttempts;
  String? lastError;
  DateTime? createdAt;
  DateTime? printedAt;
  DateTime? updatedAt;

  PrintReceiptCacheModel({
    this.id,
    this.saleId,
    this.outletId,
    this.shiftId,
    this.printType,
    this.orderNumber,
    this.tableNumber,
    this.paperWidth,
    this.printData,
    this.departmentPrinterId,
    this.printerSettingId,
    this.posDeviceId,
    this.status,
    this.printedAttempts,
    this.lastError,
    this.createdAt,
    this.printedAt,
    this.updatedAt,
  });

  PrintReceiptCacheModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    saleId = FormatUtils.parseToString(json['sale_id']);
    outletId = FormatUtils.parseToString(json['outlet_id']);
    shiftId = FormatUtils.parseToString(json['shift_id']);
    printType = FormatUtils.parseToString(json['print_type']);
    orderNumber = FormatUtils.parseToInt(json['order_number']);
    tableNumber = FormatUtils.parseToString(json['table_number']);
    paperWidth = FormatUtils.parseToString(json['paper_width']);
    if (json['print_data'] != null) {
      try {
        if (json['print_data'] is String) {
          printData = PrintDataPayload.fromJson(jsonDecode(json['print_data']));
        } else {
          printData = PrintDataPayload.fromJson(json['print_data']);
        }
      } catch (e) {
        prints('❌ ERROR deserializing printData: $e');
        prints('Print data type: ${json['print_data'].runtimeType}');
        prints('Print data value: ${json['print_data']}');
        printData = null;
      }
    } else {
      printData = null;
    }

    departmentPrinterId = FormatUtils.parseToString(
      json['department_printer_id'],
    );
    printerSettingId = FormatUtils.parseToString(json['printer_setting_id']);
    posDeviceId = FormatUtils.parseToString(json['pos_device_id']);
    status = FormatUtils.parseToString(json['status']);
    printedAttempts = FormatUtils.parseToInt(json['printed_attempts']);
    lastError = FormatUtils.parseToString(json['last_error']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    printedAt =
        json['printed_at'] != null ? DateTime.parse(json['printed_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['sale_id'] = saleId;
    data['outlet_id'] = outletId;
    data['shift_id'] = shiftId;
    data['print_type'] = printType;
    data['order_number'] = orderNumber;
    data['table_number'] = tableNumber;
    data['paper_width'] = paperWidth;
    data['department_printer_id'] = departmentPrinterId;
    data['printer_setting_id'] = printerSettingId;
    data['pos_device_id'] = posDeviceId;
    data['status'] = status;
    data['printed_attempts'] = printedAttempts;
    data['last_error'] = lastError;
    if (printData != null) {
      data['print_data'] = jsonEncode(printData!.toJson());
    }

    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (printedAt != null) {
      data['printed_at'] = DateTimeUtils.getDateTimeFormat(printedAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }

    return data;
  }

  PrintReceiptCacheModel copyWith({
    String? id,
    String? saleId,
    String? outletId,
    String? shiftId,
    String? printType,
    int? orderNumber,
    String? tableNumber,
    String? paperWidth,
    PrintDataPayload? printData,
    String? departmentPrinterId,
    String? printerSettingId,
    String? posDeviceId,
    String? status,
    int? printedAttempts,
    String? lastError,
    DateTime? createdAt,
    DateTime? printedAt,
    DateTime? updatedAt,
  }) {
    return PrintReceiptCacheModel(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      outletId: outletId ?? this.outletId,
      shiftId: shiftId ?? this.shiftId,
      printType: printType ?? this.printType,
      orderNumber: orderNumber ?? this.orderNumber,
      tableNumber: tableNumber ?? this.tableNumber,
      paperWidth: paperWidth ?? this.paperWidth,
      printData: printData ?? this.printData,
      departmentPrinterId: departmentPrinterId ?? this.departmentPrinterId,
      printerSettingId: printerSettingId ?? this.printerSettingId,
      posDeviceId: posDeviceId ?? this.posDeviceId,
      status: status ?? this.status,
      printedAttempts: printedAttempts ?? this.printedAttempts,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      printedAt: printedAt ?? this.printedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
