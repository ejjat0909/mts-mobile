import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class ShiftModel {
  /// Model name for sync handler registry
  static const String modelName = 'Shift';
  static const String modelBoxName = 'shift_box';
  String? id;
  String? outletId;
  double? startingCash;
  double? expectedCash;
  double? actualCash;
  double? shortCash;
  bool? isPrint;
  DateTime? closedAt;
  DateTime? createdAt;
  DateTime? updatedAt;

  /// [USE STAFF ID]
  String? closedBy;

  /// [USE STAFF ID]
  String? openedBy;
  String? posDeviceId;
  String? posDeviceName;
  double? cashPayments;
  double? cashRefunds;
  String? saleSummaryJson;

  ShiftModel({
    this.id,
    this.outletId,
    this.startingCash,
    this.expectedCash,
    this.actualCash,
    this.shortCash,
    this.isPrint,
    this.closedAt,
    this.createdAt,
    this.updatedAt,
    this.closedBy,
    this.openedBy,
    this.posDeviceId,
    this.posDeviceName,
    this.cashPayments,
    this.cashRefunds,
    this.saleSummaryJson,
  });

  ShiftModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    outletId = FormatUtils.parseToString(json['outlet_id']);
    startingCash = FormatUtils.parseToDouble(json['starting_cash']);
    expectedCash = FormatUtils.parseToDouble(json['expected_cash']);
    actualCash = FormatUtils.parseToDouble(json['actual_cash']);
    shortCash = FormatUtils.parseToDouble(json['short_cash']);
    isPrint = FormatUtils.parseToBool(json['is_print']);
    closedAt =
        json['closed_at'] != null ? DateTime.parse(json['closed_at']) : null;
    closedBy = FormatUtils.parseToString(json['closed_by']);
    openedBy = FormatUtils.parseToString(json['opened_by']);
    posDeviceId = FormatUtils.parseToString(json['pos_device_id']);
    posDeviceName = FormatUtils.parseToString(json['pos_device_name']);
    cashPayments = FormatUtils.parseToDouble(json['cash_payments']);
    cashRefunds = FormatUtils.parseToDouble(json['cash_refunds']);
    saleSummaryJson = FormatUtils.parseToString(json['sales_summary_json']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['outlet_id'] = outletId;
    data['starting_cash'] = startingCash;
    data['expected_cash'] = expectedCash;
    data['actual_cash'] = actualCash;
    data['short_cash'] = shortCash;
    data['is_print'] = FormatUtils.boolToInt(isPrint);
    if (closedAt != null) {
      data['closed_at'] = DateTimeUtils.getDateTimeFormat(closedAt);
    }
    data['closed_by'] = closedBy;
    data['opened_by'] = openedBy;
    data['pos_device_id'] = posDeviceId;
    data['pos_device_name'] = posDeviceName;
    data['cash_payments'] = cashPayments;
    data['cash_refunds'] = cashRefunds;
    data['sales_summary_json'] = saleSummaryJson;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }

    return data;
  }

  // copyWith
  ShiftModel copyWith({
    String? id,
    String? outletId,
    double? startingCash,
    double? expectedCash,
    double? actualCash,
    double? shortCash,
    bool? isPrint,
    int? nextOrderNumber,
    DateTime? closedAt,
    String? closedBy,
    String? openedBy,
    String? posDeviceId,
    String? posDeviceName,
    double? cashPayments,
    double? cashRefunds,
    String? saleSummaryJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      outletId: outletId ?? this.outletId,
      startingCash: startingCash ?? this.startingCash,
      expectedCash: expectedCash ?? this.expectedCash,
      actualCash: actualCash ?? this.actualCash,
      shortCash: shortCash ?? this.shortCash,
      isPrint: isPrint ?? this.isPrint,
      closedAt: closedAt ?? this.closedAt,
      closedBy: closedBy ?? this.closedBy,
      openedBy: openedBy ?? this.openedBy,
      posDeviceId: posDeviceId ?? this.posDeviceId,
      posDeviceName: posDeviceName ?? this.posDeviceName,
      cashPayments: cashPayments ?? this.cashPayments,
      cashRefunds: cashRefunds ?? this.cashRefunds,
      saleSummaryJson: saleSummaryJson ?? this.saleSummaryJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
