import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class ItemTaxModel {
  static const String modelName = "ItemTax";
  static const String modelBoxName = 'item_tax_box';
  String? itemId;
  String? taxId;
  DateTime? createdAt;
  DateTime? updatedAt;

  ItemTaxModel({
    this.itemId,
    this.taxId,
    this.createdAt,
    this.updatedAt,
  });

  ItemTaxModel.fromJson(Map<String, dynamic> json) {
    itemId = FormatUtils.parseToString(json['item_id']);
    taxId = FormatUtils.parseToString(json['tax_id']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['item_id'] = itemId;
    data['tax_id'] = taxId;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }
}
