import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class PrintingLogModel {
  static const String modelName = 'PrintingLog';
  static const String modelBoxName = 'printing_log_box';
  String? id;
  String? reason;
  String? printerIp;
  String? printerName;
  String? posDeviceName;
  String? posDeviceId;
  String? printerModel;
  String? printerInterface;
  String? staffName;
  String? shiftId;
  String? status;
  String? companyId;
  DateTime? shiftStartAt;
  DateTime? createdAt;
  DateTime? updatedAt;

  PrintingLogModel({
    this.id,
    this.reason,
    this.printerIp,
    this.printerName,
    this.posDeviceName,
    this.posDeviceId,
    this.printerModel,
    this.printerInterface,
    this.staffName,
    this.shiftId,
    this.status,
    this.companyId,
    this.createdAt,
    this.updatedAt,
    this.shiftStartAt,
  });

  PrintingLogModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    reason = FormatUtils.parseToString(json['reason']);
    printerIp = FormatUtils.parseToString(json['printer_ip']);
    printerName = FormatUtils.parseToString(json['printer_name']);
    posDeviceName = FormatUtils.parseToString(json['pos_device_name']);
    posDeviceId = FormatUtils.parseToString(json['pos_device_id']);
    printerModel = FormatUtils.parseToString(json['printer_model']);
    printerInterface = FormatUtils.parseToString(json['printer_interface']);
    staffName = FormatUtils.parseToString(json['staff_name']);
    shiftId = FormatUtils.parseToString(json['shift_id']);
    status = FormatUtils.parseToString(json['status']);
    companyId = FormatUtils.parseToString(json['company_id']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
    shiftStartAt =
        json['shift_start_at'] != null
            ? DateTime.parse(json['shift_start_at'])
            : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['reason'] = reason;
    data['printer_ip'] = printerIp;
    data['printer_name'] = printerName;
    data['pos_device_name'] = posDeviceName;
    data['pos_device_id'] = posDeviceId;
    data['printer_model'] = printerModel;
    data['printer_interface'] = printerInterface;
    data['staff_name'] = staffName;
    data['shift_id'] = shiftId;
    data['status'] = status;
    data['company_id'] = companyId;

    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    if (shiftStartAt != null) {
      data['shift_start_at'] = DateTimeUtils.getDateTimeFormat(shiftStartAt);
    }
    return data;
  }

  // copy with
  PrintingLogModel copyWith({
    String? id,
    String? reason,
    String? printerIp,
    String? printerName,
    String? posDeviceName,
    String? posDeviceId,
    String? printerModel,
    String? printerInterface,
    String? staffName,
    String? shiftId,
    String? status,
    String? companyId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? shiftStartAt,
  }) {
    return PrintingLogModel(
      id: id ?? this.id,
      reason: reason ?? this.reason,
      printerIp: printerIp ?? this.printerIp,
      printerName: printerName ?? this.printerName,
      posDeviceName: posDeviceName ?? this.posDeviceName,
      posDeviceId: posDeviceId ?? this.posDeviceId,
      printerModel: printerModel ?? this.printerModel,
      printerInterface: printerInterface ?? this.printerInterface,
      staffName: staffName ?? this.staffName,
      shiftId: shiftId ?? this.shiftId,
      status: status ?? this.status,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shiftStartAt: shiftStartAt ?? this.shiftStartAt,
    );
  }
}
