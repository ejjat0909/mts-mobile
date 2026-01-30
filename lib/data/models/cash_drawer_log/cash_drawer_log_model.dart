import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

/// Model representing cash drawer activity logs
class CashDrawerLogModel {
  /// Model name for sync handler registry
  static const String modelName = 'CashDrawerLog';
  static const String modelBoxName = 'cash_drawer_log_box';

  String? id;
  String? staffName;
  String? activity;
  String? companyId;
  String? shiftId;
  String? posDeviceName;
  String? posDeviceId;

  DateTime? shiftStartAt;
  DateTime? createdAt;
  DateTime? updatedAt;

  CashDrawerLogModel({
    this.id,
    this.staffName,
    this.activity,
    this.companyId,
    this.shiftId,
    this.posDeviceName,
    this.posDeviceId,
    this.shiftStartAt,
    this.createdAt,
    this.updatedAt,
  });

  CashDrawerLogModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    staffName = FormatUtils.parseToString(json['staff_name']);
    activity = FormatUtils.parseToString(json['activity']);
    companyId = FormatUtils.parseToString(json['company_id']);
    shiftId = FormatUtils.parseToString(json['shift_id']);
    posDeviceName = FormatUtils.parseToString(json['pos_device_name']);
    posDeviceId = FormatUtils.parseToString(json['pos_device_id']);

    shiftStartAt =
        json['shift_start_at'] != null
            ? DateTime.parse(json['shift_start_at'])
            : null;
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['staff_name'] = staffName;
    data['activity'] = activity;
    data['company_id'] = companyId;
    data['shift_id'] = shiftId;
    data['pos_device_name'] = posDeviceName;
    data['pos_device_id'] = posDeviceId;

    if (shiftStartAt != null) {
      data['shift_start_at'] = DateTimeUtils.getDateTimeFormat(shiftStartAt);
    }
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  // copy with
  CashDrawerLogModel copyWith({
    String? id,
    String? staffName,
    String? activity,
    String? companyId,
    String? shiftId,
    String? posDeviceName,
    String? posDeviceId,
    String? printerIp,
    String? printerName,
    String? printerModel,
    String? printerInterface,
    DateTime? shiftStartAt,
    DateTime? createdAt,
    required DateTime? updatedAt,
  }) {
    return CashDrawerLogModel(
      id: id ?? this.id,
      staffName: staffName ?? this.staffName,
      activity: activity ?? this.activity,
      companyId: companyId ?? this.companyId,
      shiftId: shiftId ?? this.shiftId,
      posDeviceName: posDeviceName ?? this.posDeviceName,
      posDeviceId: posDeviceId ?? this.posDeviceId,
      shiftStartAt: shiftStartAt ?? this.shiftStartAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
