import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class OrderOptionModel {
  /// Model name for sync handler registry
  static const String modelName = 'OrderOption';
  static const String modelBoxName = 'order_option_box';
  String? id;
  String? name;
  String? outletId;
  int? orderColumn;
  DateTime? createdAt;
  DateTime? updatedAt;

  OrderOptionModel({
    this.id,
    this.name,
    this.outletId,
    this.orderColumn,
    this.createdAt,
    this.updatedAt,
  });

  OrderOptionModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    name = FormatUtils.parseToString(json['name']);
    outletId = FormatUtils.parseToString(json['outlet_id']);
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
    data['name'] = name;
    data['outlet_id'] = outletId;
    data['order_column'] = orderColumn;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OrderOptionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
