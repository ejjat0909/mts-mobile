import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class PaymentTypeModel {
  /// Model name for sync handler registry
  static const String modelName = 'PaymentType';
  static const String modelBoxName = 'payment_type_box';
  String? id;
  String? name;
  String? paymentTypeCategory;
  bool? autoRounding;
  DateTime? createdAt;
  DateTime? updatedAt;

  PaymentTypeModel({
    this.id,
    this.name,
    this.paymentTypeCategory,
    this.autoRounding,
    this.createdAt,
    this.updatedAt,
  });

  PaymentTypeModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    name = FormatUtils.parseToString(json['name']);
    paymentTypeCategory = FormatUtils.parseToString(json['payment_type_category']);
    autoRounding = FormatUtils.parseToBool(json['auto_rounding']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['payment_type_category'] = paymentTypeCategory;
    data['auto_rounding'] = FormatUtils.boolToInt(autoRounding);
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  // copy with
  PaymentTypeModel copyWith({
    String? id,
    String? name,
    String? paymentTypeCategory,
    bool? autoRounding,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      paymentTypeCategory: paymentTypeCategory ?? this.paymentTypeCategory,
      autoRounding: autoRounding ?? this.autoRounding,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
