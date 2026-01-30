import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class CategoryDiscountModel {
  static const String modelName = "CategoryDiscount";
  static const String modelBoxName = 'category_discount_box';
  String? categoryId;
  String? discountId;
  DateTime? createdAt;
  DateTime? updatedAt;

  CategoryDiscountModel({
    this.categoryId,
    this.discountId,
    this.createdAt,
    this.updatedAt,
  });

  CategoryDiscountModel.fromJson(Map<String, dynamic> json) {
    categoryId = FormatUtils.parseToString(json['category_id']);
    discountId = FormatUtils.parseToString(json['discount_id']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['category_id'] = categoryId;
    data['discount_id'] = discountId;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  CategoryDiscountModel copyWith({
    String? categoryId,
    String? discountId,
    DateTime? createdAt,
    required DateTime? updatedAt,
  }) {
    return CategoryDiscountModel(
      categoryId: categoryId ?? this.categoryId,
      discountId: discountId ?? this.discountId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
