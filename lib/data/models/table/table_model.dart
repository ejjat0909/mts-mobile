import 'package:flutter/material.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class TableModel {
  static const String modelName = 'Table';
  static const String modelBoxName = 'table_box';
  String? id;
  String? tableSectionId;
  double? left;
  double? top;
  String? name; //table name
  String? type; //square or circle
  int? status; // table status TableStatusEnum
  String? staffId;
  String? customerId;
  String? saleId;
  String? predefinedOrderId;
  String? outletId;
  int? seats;
  DateTime? createdAt;
  DateTime? updatedAt;

  TableModel({
    this.id,
    this.tableSectionId,
    this.left,
    this.top,
    this.name,
    this.type,
    this.status,
    this.staffId,
    this.customerId,
    this.saleId,
    this.predefinedOrderId,
    this.outletId,
    this.seats,
    this.createdAt,
    this.updatedAt,
  });

  //needed for deep copy
  TableModel copyWith({
    String? id,
    String? tableSectionId,
    double? left,
    double? top,
    String? name,
    String? type,
    int? status,
    String? staffId,
    String? customerId,
    String? saleId,
    String? predefinedOrderId,
    String? outletId,
    int? seats,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TableModel(
      id: id ?? this.id,
      tableSectionId: tableSectionId ?? this.tableSectionId,
      left: left ?? this.left,
      top: top ?? this.top,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      staffId: staffId ?? this.staffId,
      customerId: customerId ?? this.customerId,
      saleId: saleId ?? this.saleId,
      predefinedOrderId: predefinedOrderId ?? this.predefinedOrderId,
      outletId: outletId ?? this.outletId,
      seats: seats ?? this.seats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  TableModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    tableSectionId = FormatUtils.parseToString(json['table_section_id']);
    left = FormatUtils.parseToDouble(json['left']);
    top = FormatUtils.parseToDouble(json['top']);
    name = FormatUtils.parseToString(json['name']);
    type = FormatUtils.parseToString(json['type']);
    status = FormatUtils.parseToInt(json['status']);
    staffId = FormatUtils.parseToString(json['staff_id']);
    customerId = FormatUtils.parseToString(json['customer_id']);
    saleId = FormatUtils.parseToString(json['sale_id']);
    predefinedOrderId = FormatUtils.parseToString(json['predefined_order_id']);
    outletId = FormatUtils.parseToString(json['outlet_id']);
    seats = FormatUtils.parseToInt(json['seats']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['table_section_id'] = tableSectionId;
    data['left'] = left;
    data['top'] = top;
    data['name'] = name;
    data['type'] = type;
    data['status'] = status;
    data['staff_id'] = staffId;
    data['customer_id'] = customerId;
    data['sale_id'] = saleId;
    data['predefined_order_id'] = predefinedOrderId;
    data['outlet_id'] = outletId;
    data['seats'] = seats;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  static IconData getIcon() {
    return Icons.view_quilt_rounded;
  }
}
