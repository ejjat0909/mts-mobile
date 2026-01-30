// order_option_tax_model.dart

import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class OrderOptionTaxModel {
  // Static model name for use in pending changes
  static const String modelName = 'OrderOptionTax';
  static const String modelBoxName = 'order_option_tax_box';

  // Properties
  String? orderOptionId;
  String? taxId;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Constructor
  OrderOptionTaxModel({
    this.orderOptionId,
    this.taxId,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor from JSON
  OrderOptionTaxModel.fromJson(Map<String, dynamic> json) {
    orderOptionId = FormatUtils.parseToString(json['order_option_id']);
    taxId = FormatUtils.parseToString(json['tax_id']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['order_option_id'] = orderOptionId;
    data['tax_id'] = taxId;

    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }

    return data;
  }

  // Copy with method for immutability
  OrderOptionTaxModel copyWith({
    String? orderOptionId,
    String? taxId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderOptionTaxModel(
      orderOptionId: orderOptionId ?? this.orderOptionId,
      taxId: taxId ?? this.taxId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
