import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class DiscountItemModel {
  static const String modelName = 'DiscountItem';
  static const String modelBoxName = 'discount_item_box';
  String? itemId;
  String? discountId;
  DateTime? createdAt;
  DateTime? updatedAt;

  DiscountItemModel({
    this.itemId,
    this.discountId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['item_id'] = itemId;
    data['discount_id'] = discountId;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  DiscountItemModel.fromJson(Map<String, dynamic> json) {
    itemId = FormatUtils.parseToString(json['item_id']);
    discountId = FormatUtils.parseToString(json['discount_id']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  DiscountItemModel copyWith({
    String? id,
    String? itemId,
    String? discountId,
    DateTime? createdAt,
    required DateTime? updatedAt,
  }) {
    return DiscountItemModel(
      itemId: itemId ?? this.itemId,
      discountId: discountId ?? this.discountId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
