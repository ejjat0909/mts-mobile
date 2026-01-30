import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class ItemModel {
  static const String modelName = 'Item';
  static const String modelBoxName = 'item_box';
  String? id;
  String? name;
  String? categoryId;
  String? variantOptionJson;
  String? barcode;
  String? description;
  String? soldBy;
  String? sku;
  double? price;
  double? cost;
  String? itemRepresentationId;
  String? inventoryId;
  int? requiredModifierNum;
  DateTime? createdAt;
  DateTime? updatedAt;

  ItemModel({
    this.id,
    this.name,
    this.categoryId,
    this.variantOptionJson,
    this.requiredModifierNum,
    this.barcode,
    this.description,
    this.soldBy,
    this.sku,
    this.price,
    this.cost,
    this.itemRepresentationId,
    this.inventoryId,
    this.createdAt,
    this.updatedAt,
  });

  ItemModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    name = FormatUtils.parseToString(json['name']);
    categoryId = FormatUtils.parseToString(json['category_id']);
    variantOptionJson = FormatUtils.parseToString(json['variant_option_json']);
    barcode = FormatUtils.parseToString(json['barcode']);
    requiredModifierNum = FormatUtils.parseToInt(json['required_modifier_num']);
    description = FormatUtils.parseToString(json['description']);
    soldBy = FormatUtils.parseToString(json['sold_by']);
    sku = FormatUtils.parseToString(json['sku']);
    price = FormatUtils.parseToDouble(json['price']);
    cost = FormatUtils.parseToDouble(json['cost']);
    itemRepresentationId = FormatUtils.parseToString(
      json['item_representation_id'],
    );
    inventoryId = FormatUtils.parseToString(json['inventory_id']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['category_id'] = categoryId;
    data['variant_option_json'] = variantOptionJson;
    data['barcode'] = barcode;
    data['description'] = description;
    data['sold_by'] = soldBy;
    data['sku'] = sku;
    data['price'] = price;
    data['required_modifier_num'] = requiredModifierNum;
    data['cost'] = cost;
    data['item_representation_id'] = itemRepresentationId;
    data['inventory_id'] = inventoryId;

    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  // copy with
  ItemModel copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? variantOptionJson,
    String? barcode,
    String? description,
    String? soldBy,
    String? sku,
    double? price,
    double? cost,
    String? itemRepresentationId,
    String? inventoryId,
    int? requiredModifierNum,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      variantOptionJson: variantOptionJson ?? this.variantOptionJson,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      soldBy: soldBy ?? this.soldBy,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      itemRepresentationId: itemRepresentationId ?? this.itemRepresentationId,
      inventoryId: inventoryId ?? this.inventoryId,
      requiredModifierNum: requiredModifierNum ?? this.requiredModifierNum,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
