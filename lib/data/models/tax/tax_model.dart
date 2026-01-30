import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class TaxModel {
  /// Model name for sync handler registry
  static const String modelName = 'Tax';
  static const String modelBoxName = 'tax_box';
  String? id;
  String? name;
  double? rate;
  String? type;
  int? option;
  DateTime? createdAt;
  DateTime? updatedAt;
  bool? isOrderOptionChecked;

  TaxModel({
    this.id,
    this.name,
    this.rate,
    this.type,
    this.option,
    this.createdAt,
    this.updatedAt,
    this.isOrderOptionChecked,
  });

  TaxModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    name = FormatUtils.parseToString(json['name']);
    rate = FormatUtils.parseToDouble(json['rate']);
    type = FormatUtils.parseToString(json['type']);
    option =
        (json['option'] is String) ? int.parse(json['option']) : json['option'];
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
    isOrderOptionChecked = FormatUtils.parseToBool(
      json['is_order_option_checked'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['rate'] = rate;
    data['type'] = type;
    data['option'] = option;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    data['is_order_option_checked'] = FormatUtils.boolToInt(
      isOrderOptionChecked,
    );
    return data;
  }
}
