import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class PredefinedOrderModel {
  static const String modelName = 'PredefinedOrder';
  static const String modelBoxName = 'predefined_order_box';
  String? id;
  String? outletId;
  String? name;
  bool? isOccupied;
  String? remarks;
  int? orderColumn;
  String? tableId;
  String? tableName;
  bool? isCustom;
  DateTime? createdAt;
  DateTime? updatedAt;

  PredefinedOrderModel({
    this.id,
    this.outletId,
    this.name,
    this.tableId,
    this.tableName,
    this.isOccupied,
    this.isCustom,
    this.remarks,
    this.orderColumn,
    this.createdAt,
    this.updatedAt,
  });

  PredefinedOrderModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    outletId = FormatUtils.parseToString(json['outlet_id']);
    name = FormatUtils.parseToString(json['name']);
    isOccupied = FormatUtils.parseToBool(json['is_occupied']);
    isCustom = FormatUtils.parseToBool(json['is_custom']);
    remarks = FormatUtils.parseToString(json['remarks']);
    tableId = FormatUtils.parseToString(json['table_id']);
    tableName = FormatUtils.parseToString(json['table_name']);
    orderColumn =
        (json['order_column'] is String)
            ? int.parse(json['order_column'])
            : json['order_column'];
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['outlet_id'] = outletId;
    data['name'] = name;
    data['table_id'] = tableId;
    data['table_name'] = tableName;
    data['is_occupied'] = FormatUtils.boolToInt(isOccupied);
    data['is_custom'] = FormatUtils.boolToInt(isCustom);
    data['remarks'] = remarks;
    data['order_column'] = orderColumn;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }

    return data;
  }

  // @override
  // PredefinedOrderModel fromJson(Map<String, Object?> json) {
  //   return PredefinedOrderModel(
  //     id: json['id'] as int?,
  //     outletId: json['outlet_id'] as int?,
  //     name: json['name'] as String?,
  //     isOccupied: json['is_occupied'] as int == 1 ? true : false,
  //     isSynced: json['is_synced'] as int == 1 ? true : false,
  //     remarks: json['remarks'] as String?,
  //     createdAt: json['created_at'] != null
  //         ? DateTime.parse(json['created_at'] as String)
  //         : null,
  //     updatedAt: json['updated_at'] != null
  //         ? DateTime.parse(json['updated_at'] as String)
  //         : null,
  //   );
  // }

  // copy with
  PredefinedOrderModel copyWith({
    String? id,
    String? outletId,
    String? name,
    String? tableId,
    String? tableName,
    bool? isOccupied,
    bool? isCustom,
    String? remarks,
    int? orderColumn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PredefinedOrderModel(
      id: id ?? this.id,
      outletId: outletId ?? this.outletId,
      name: name ?? this.name,
      tableId: tableId,
      tableName: tableName,
      isOccupied: isOccupied ?? this.isOccupied,
      isCustom: isCustom ?? this.isCustom,
      remarks: remarks ?? this.remarks,
      orderColumn: orderColumn ?? this.orderColumn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
