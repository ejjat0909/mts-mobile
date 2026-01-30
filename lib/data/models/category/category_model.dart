import 'package:mts/core/enum/polymorphic_enum.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/data/models/page_item/page_item_model.dart';

class CategoryModel {
  static const String modelName = 'Category';
  static const String modelBoxName = 'category_box';
  String? id;
  String? name;
  String? color;
  String? companyId;
  DateTime? createdAt;
  DateTime? updatedAt;

  CategoryModel({
    this.id,
    this.name,
    this.color,
    this.companyId,
    this.createdAt,
    this.updatedAt,
  });

  CategoryModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    name = FormatUtils.parseToString(json['name']);
    color = FormatUtils.parseToString(json['color']);
    companyId = FormatUtils.parseToString(json['company_id']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['color'] = color;
    data['company_id'] = companyId;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  // Retrieves an ItemModel based on the provided pageId, pageItems, and item. Returns the found ItemModel if a matching PageItemModel is found, otherwise returns null.
  static CategoryModel? getSelectedCategoryByPageId(
    String pageId,
    List<PageItemModel> pageItems,
    CategoryModel? item,
  ) {
    if (item == null) return null;

    PageItemModel? pageItem = pageItems.firstWhere(
      (pageItem) =>
          pageItem.pageId == pageId &&
          pageItem.pageItemableType == PolymorphicEnum.category &&
          pageItem.pageItemableId == item.id,
      orElse: () => PageItemModel(), // Provide a fallback value of null
    );

    return pageItem.id != null ? item : null;
  }
}
