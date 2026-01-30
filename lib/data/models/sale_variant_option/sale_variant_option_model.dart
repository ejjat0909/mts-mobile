import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class SaleVariantOptionModel {
  static const String modelName = 'SaleVariantOption';
  static const String modelBoxName = 'sale_variant_option_box';
  String? id;
  String? variantOptionId;
  DateTime? createdAt;
  DateTime? updatedAt;

  SaleVariantOptionModel({
    this.id,
    this.variantOptionId,
    this.createdAt,
    this.updatedAt,
  });

  SaleVariantOptionModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    variantOptionId = FormatUtils.parseToString(json['variant_option_id']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['variant_option_id'] = variantOptionId;
      if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }
}
