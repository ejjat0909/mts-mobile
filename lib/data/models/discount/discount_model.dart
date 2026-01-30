import 'package:easy_localization/easy_localization.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class DiscountModel {
  /// Model name for sync handler registry
  static const String modelName = 'Discount';
  static const String modelBoxName = 'discount_box';
  String? id;
  String? name;
  int? type;
  double? value;
  int? option;
  DateTime? validFrom;
  DateTime? validTo;
  DateTime? createdAt;
  DateTime? updatedAt;

  DiscountModel({
    this.id,
    this.name,
    this.type,
    this.value,
    this.option,
    this.validFrom,
    this.validTo,
    this.createdAt,
    this.updatedAt,
  });

  DiscountModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    name = FormatUtils.parseToString(json['name']);
    type = FormatUtils.parseToInt(json['type']);
    value = FormatUtils.parseToDouble(json['value']);
    option = FormatUtils.parseToInt(json['option']);
    validFrom =
        json['valid_from'] != null ? DateTime.parse(json['valid_from']) : null;
    validTo =
        json['valid_to'] != null ? DateTime.parse(json['valid_to']) : null;
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['type'] = type;
    data['value'] = value;
    data['option'] = option;

    if (validFrom != null) {
      data['valid_from'] = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
        'en_US',
      ).format(validFrom!);
    }
    if (validTo != null) {
      data['valid_to'] = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
        'en_US',
      ).format(validTo!);
    }
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }
}
