import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class CategoryTaxModel {
  // Static model name for use in pending changes
  static const String modelName = 'CategoryTax';
  static const String modelBoxName = 'category_tax_box';

  // Properties
  String? categoryId;
  String? taxId;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Constructor
  CategoryTaxModel({
    this.categoryId,
    this.taxId,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor from JSON
  CategoryTaxModel.fromJson(Map<String, dynamic> json) {
    categoryId = FormatUtils.parseToString(json['category_id']);
    taxId = FormatUtils.parseToString(json['tax_id']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['category_id'] = categoryId;
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
  CategoryTaxModel copyWith({
    String? categoryId,
    String? taxId,
    DateTime? createdAt,
    required DateTime? updatedAt,
  }) {
    return CategoryTaxModel(
      categoryId: categoryId ?? this.categoryId,
      taxId: taxId ?? this.taxId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
