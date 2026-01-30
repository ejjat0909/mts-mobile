import 'dart:convert';

import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class SaleModel {
  /// Model name for sync handler registry
  static const String modelName = 'Sale';
  static const String modelBoxName = 'sale_box';
  String? id;
  String? staffId;
  // not in db, just for display purpose
  String? staffName;
  String? tableId;
  String? tableName;
  int? runningNumber;
  String? predefinedOrderId;
  String? orderOptionId;
  String? orderOptionName; // not in the database
  String? outletId;
  String? name;
  int? saleItemCount;
  String? saleItemIdsToPrintVoid;
  String? saleItemIdsToPrint;
  String? remarks;
  double? totalPrice;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? chargedAt;

  SaleModel({
    this.id,
    this.staffId,
    this.staffName,
    this.tableId,
    this.tableName,
    this.runningNumber,
    this.predefinedOrderId,
    this.orderOptionId,
    this.orderOptionName,
    this.outletId,

    this.name,
    this.saleItemIdsToPrint,
    this.saleItemIdsToPrintVoid,
    this.saleItemCount,
    this.remarks,
    this.totalPrice,
    this.createdAt,
    this.updatedAt,
    this.chargedAt,
  });

  SaleModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    staffId = FormatUtils.parseToString(json['staff_id']);
    tableId = FormatUtils.parseToString(json['table_id']);
    tableName = FormatUtils.parseToString(json['table_name']);
    saleItemIdsToPrint = FormatUtils.parseToString(
      json['sale_item_ids_to_print'],
    );
    saleItemIdsToPrintVoid = FormatUtils.parseToString(
      json['sale_item_ids_to_print_void'],
    );
    saleItemCount = FormatUtils.parseToInt(json['sale_item_count']);
    runningNumber = FormatUtils.parseToInt(json['running_number']);
    predefinedOrderId = FormatUtils.parseToString(json['predefined_order_id']);
    orderOptionId = FormatUtils.parseToString(json['order_option_id']);
    outletId = FormatUtils.parseToString(json['outlet_id']);
    name = FormatUtils.parseToString(json['name']);

    remarks = FormatUtils.parseToString(json['remarks']);
    totalPrice = FormatUtils.parseToDouble(json['total_price']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;

    chargedAt =
        json['charged_at'] != null ? DateTime.parse(json['charged_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['staff_id'] = staffId;
    data['table_id'] = tableId;
    data['table_name'] = tableName;
    data['running_number'] = runningNumber;
    data['predefined_order_id'] = predefinedOrderId;
    data['sale_item_ids_to_print'] = saleItemIdsToPrint;
    data['sale_item_ids_to_print_void'] = saleItemIdsToPrintVoid;
    data['sale_item_count'] = saleItemCount;

    data['order_option_id'] = orderOptionId;

    data['outlet_id'] = outletId;
    data['name'] = name;
    data['remarks'] = remarks;
    data['total_price'] = totalPrice;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }

    if (chargedAt != null) {
      data['charged_at'] = DateTimeUtils.getDateTimeFormat(chargedAt);
    } else {
      data['charged_at'] = null;
    }

    return data;
  }

  SaleModel copyWith({
    String? id,
    String? staffId,
    String? staffName,
    String? tableId,
    String? tableName,
    int? runningNumber,
    String? predefinedOrderId,
    int? saleItemCount,
    String? saleItemIdsToPrintVoid,
    String? saleItemIdsToPrint,
    String? orderOptionId,
    String? orderOptionName,
    String? outletId,
    String? name,
    String? remarks,
    double? totalPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? chargedAt,
  }) {
    return SaleModel(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      runningNumber: runningNumber ?? this.runningNumber,
      predefinedOrderId: predefinedOrderId ?? this.predefinedOrderId,
      orderOptionId: orderOptionId ?? this.orderOptionId,
      orderOptionName: orderOptionName ?? this.orderOptionName,
      outletId: outletId ?? this.outletId,
      name: name ?? this.name,
      saleItemCount: saleItemCount ?? this.saleItemCount,
      saleItemIdsToPrintVoid:
          saleItemIdsToPrintVoid ?? this.saleItemIdsToPrintVoid,
      saleItemIdsToPrint: saleItemIdsToPrint ?? this.saleItemIdsToPrint,
      remarks: remarks ?? this.remarks,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      chargedAt: chargedAt ?? this.chargedAt,
    );
  }

  static List<String> decodeSaleItemIds(String? saleItemIds) {
    final decoded = List<String>.from(json.decode(saleItemIds ?? '[]'));
    return decoded;
  }
}
