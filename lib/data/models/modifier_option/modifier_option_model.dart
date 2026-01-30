import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class ModifierOptionModel {
  static const String modelName = "ModifierOption";
  static const String modelBoxName = 'modifier_option_box';
  String? id;
  String? modifierId;
  String? name;
  double? price;
  double? cost;
  int? orderColumn;
  DateTime? createdAt;
  DateTime? updatedAt;

  ModifierOptionModel({
    this.id,
    this.modifierId,
    this.name,
    this.price,
    this.cost,
    this.orderColumn,
    this.createdAt,
    this.updatedAt,
  });

  ModifierOptionModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    modifierId = FormatUtils.parseToString(json['modifier_id']);
    name = FormatUtils.parseToString(json['name']);
    price = FormatUtils.parseToDouble(json['price']);
    cost = FormatUtils.parseToDouble(json['cost']);
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
    data['modifier_id'] = modifierId;
    data['name'] = name;
    data['price'] = price;
    data['cost'] = cost;
    data['order_column'] = orderColumn;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }
}
