import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class VariantOptionModel {
  static const String modelName = "VariantOption";
  String? id;
  String? variantId;
  String? itemId;
  String? sku;
  String? barcode;
  String? name;
  String? imagePath;
  double? price;
  double? cost;
  int? columnOrder;
  String? inventoryId;
  DateTime? createdAt;
  DateTime? updatedAt;

  VariantOptionModel({
    this.id,
    this.variantId,
    this.itemId,
    this.sku,
    this.barcode,
    this.name,
    this.imagePath,
    this.price,
    this.cost,
    this.columnOrder,
    this.inventoryId,
    this.createdAt,
    this.updatedAt,
  });

  VariantOptionModel.fromJson(
    Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    variantId = FormatUtils.parseToString(json['variant_id']);
    itemId = FormatUtils.parseToString(json['item_id']);
    sku = FormatUtils.parseToString(json['sku']);
    barcode = FormatUtils.parseToString(json['barcode']);
    name = FormatUtils.parseToString(json['name']);
    imagePath = FormatUtils.parseToString(json['image_path']);
    price = FormatUtils.parseToDouble(json['price']);
    cost = FormatUtils.parseToDouble(json['cost']);
    columnOrder = json['column_order'];
    inventoryId = FormatUtils.parseToString(json['inventory_id']);
   // isCustom = json['is_custom'] == 1;
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['variant_id'] = variantId;
    data['item_id'] = itemId;
    data['sku'] = sku;
    data['barcode'] = barcode;
    data['name'] = name;
    data['image_path'] = imagePath;
    data['price'] = price;
    data['cost'] = cost;
    data['column_order'] = columnOrder;
    data['inventory_id'] = inventoryId;
  //  data['is_custom'] = isCustom == true ? 1 : 0;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  // copywith
  VariantOptionModel copyWith({
    String? id,
    String? variantId,
    String? itemId,
    String? sku,
    String? barcode,
    String? name,
    String? imagePath,
    double? price,
    double? cost,
    int? columnOrder,
    String? inventoryId,
  //  bool? isCustom,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VariantOptionModel(
      id: id ?? this.id,
      variantId: variantId ?? this.variantId,
      itemId: itemId ?? this.itemId,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      columnOrder: columnOrder ?? this.columnOrder,
      inventoryId: inventoryId ?? this.inventoryId,
    //  isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
