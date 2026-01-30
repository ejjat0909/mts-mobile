import 'package:mts/core/enum/polymorphic_enum.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/data/models/category/category_model.dart';
import 'package:mts/data/models/item/item_model.dart';

class PageItemModel {
  static const String modelName = 'PageItem';
  static const String modelBoxName = 'page_item_box';
  String? id;
  String? pageId;
  String? pageItemableId;
  String? pageItemableType;
  int? sort;
  DateTime? createdAt;
  DateTime? updatedAt;

  PageItemModel({
    this.id,
    this.pageId,
    this.pageItemableId,
    this.pageItemableType,
    this.sort,
    this.createdAt,
    this.updatedAt,
  });

  PageItemModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    pageId = FormatUtils.parseToString(json['page_id']);
    pageItemableId = FormatUtils.parseToString(json['page_itemable_id']);
    pageItemableType = FormatUtils.parseToString(json['page_itemable_type']);
    sort = FormatUtils.parseToInt(json['sort']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['page_id'] = pageId;
    data['page_itemable_id'] = pageItemableId;
    data['page_itemable_type'] = pageItemableType;
    data['sort'] = sort;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt!);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  static List<ItemModel> getItemModelsFromPageItems(
    List<PageItemModel> pageItems,
    List<ItemModel> allItems,
    String pageId,
  ) {
    return pageItems
        .where(
          (pageItem) =>
              pageItem.pageItemableType == PolymorphicEnum.item &&
              pageItem.pageId == pageId,
        )
        .map(
          (pageItem) =>
              allItems.firstWhere((item) => item.id == pageItem.pageItemableId),
        )
        .toList();
  }

  static List<CategoryModel> getCategoryModelsFromPageItems(
    List<PageItemModel> pageItems,
    List<CategoryModel> allCategories,
    String pageId,
  ) {
    return pageItems
        .where(
          (pageItem) =>
              pageItem.pageItemableType == PolymorphicEnum.category &&
              pageItem.pageId == pageId,
        )
        .map(
          (pageItem) => allCategories.firstWhere(
            (category) => category.id == pageItem.pageItemableId,
          ),
        )
        .toList();
  }
}
