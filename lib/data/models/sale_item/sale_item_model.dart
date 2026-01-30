import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class SaleItemModel {
  /// Model name for sync handler registry
  static const String modelName = 'SaleItem';
  static const String modelBoxName = 'sale_item_box';
  String? id;
  String? itemId;
  String? categoryId;
  String? saleId;
  String? taxId;
  String? discountId;
  String? inventoryId;
  double? price;
  double? quantity;
  String? comments;
  String? variantOptionId;
  double? cost;
  String? soldBy;
  bool? isVoided;
  double? discountTotal;
  double? taxAfterDiscount;
  double? taxIncludedAfterDiscount;
  double? totalAfterDiscAndTax;
  String? variantOptionJson;
  int? saleModifierCount;
  DateTime? createdAt;
  DateTime? updatedAt;

  SaleItemModel({
    this.id,
    this.itemId,
    this.categoryId,
    this.saleId,
    this.taxId,
    this.discountId,
    this.inventoryId,
    this.price,
    this.cost,
    this.quantity,
    this.comments,
    this.soldBy,
    this.variantOptionId,
    this.createdAt,
    this.updatedAt,
    this.isVoided,
    this.variantOptionJson,
    this.discountTotal,
    this.taxAfterDiscount,
    this.taxIncludedAfterDiscount,
    this.totalAfterDiscAndTax,
    this.saleModifierCount,
  });

  SaleItemModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    itemId = FormatUtils.parseToString(json['item_id']);
    categoryId = FormatUtils.parseToString(json['category_id']);
    saleId = FormatUtils.parseToString(json['sale_id']);
    taxId = FormatUtils.parseToString(json['tax_id']);
    discountId = FormatUtils.parseToString(json['discount_id']);
    inventoryId = FormatUtils.parseToString(json['inventory_id']);
    variantOptionId = FormatUtils.parseToString(json['variant_option_id']);
    price = FormatUtils.parseToDouble(json['price']);
    cost = FormatUtils.parseToDouble(json['cost']);
    quantity = FormatUtils.parseToDouble(json['quantity']);
    comments = FormatUtils.parseToString(json['comments']);
    soldBy = FormatUtils.parseToString(json['sold_by']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
    isVoided = FormatUtils.parseToBool(json['is_voided']);
    // isPrintedVoided = FormatUtils.parseToBool(json['is_printed_voided']);
    // isPrintedKitchen = FormatUtils.parseToBool(json['is_printed_kitchen']);
    variantOptionJson = FormatUtils.parseToString(json['variant_option_json']);
    discountTotal = FormatUtils.parseToDouble(json['discount_total']);
    taxAfterDiscount = FormatUtils.parseToDouble(json['tax_after_discount']);
    taxIncludedAfterDiscount = FormatUtils.parseToDouble(
      json['tax_included_after_discount'],
    );
    totalAfterDiscAndTax = FormatUtils.parseToDouble(
      json['total_after_disc_and_tax'],
    );
    saleModifierCount = FormatUtils.parseToInt(json['sale_modifier_count']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['item_id'] = itemId;

    data['category_id'] = categoryId;
    data['sale_id'] = saleId;
    data['tax_id'] = taxId;
    data['discount_id'] = discountId;
    data['inventory_id'] = inventoryId;
    data['price'] = price;
    data['cost'] = cost;
    data['quantity'] = quantity;
    data['variant_option_id'] = variantOptionId;
    data['comments'] = comments;
    data['sold_by'] = soldBy;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    data['is_voided'] = FormatUtils.boolToInt(isVoided);
    // data['is_printed_voided'] = FormatUtils.boolToInt(isPrintedVoided);
    // data['is_printed_kitchen'] = FormatUtils.boolToInt(isPrintedKitchen);
    data['variant_option_json'] = variantOptionJson;
    data['discount_total'] = discountTotal;
    data['tax_after_discount'] = taxAfterDiscount;
    data['tax_included_after_discount'] = taxIncludedAfterDiscount;
    data['total_after_disc_and_tax'] = totalAfterDiscAndTax;
    data['sale_modifier_count'] = saleModifierCount;
    return data;
  }

  SaleItemModel copyWith({
    String? id,
    String? itemId,
    String? categoryId,
    String? saleId,
    String? taxId,
    String? discountId,
    String? inventoryId,
    String? variantOptionId,
    double? price,
    double? cost,
    double? quantity,
    String? comments,
    String? soldBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVoided,
    // bool? isPrintedVoided,
    // bool? isPrintedKitchen,
    String? variantOptionJson,
    double? discountTotal,
    double? taxAfterDiscount,
    double? taxIncludedAfterDiscount,
    double? totalAfterDiscAndTax,
    int? saleModifierCount,
  }) {
    return SaleItemModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      categoryId: categoryId ?? this.categoryId,
      saleId: saleId ?? this.saleId,
      taxId: taxId ?? this.taxId,
      discountId: discountId ?? this.discountId,
      inventoryId: inventoryId ?? this.inventoryId,
      variantOptionId: variantOptionId ?? this.variantOptionId,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      quantity: quantity ?? this.quantity,
      comments: comments ?? this.comments,
      soldBy: soldBy ?? this.soldBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVoided: isVoided ?? this.isVoided,
      // isPrintedVoided: isPrintedVoided ?? this.isPrintedVoided,
      // isPrintedKitchen: isPrintedKitchen ?? this.isPrintedKitchen,
      variantOptionJson: variantOptionJson ?? this.variantOptionJson,
      discountTotal: discountTotal ?? this.discountTotal,
      taxAfterDiscount: taxAfterDiscount ?? this.taxAfterDiscount,
      taxIncludedAfterDiscount:
          taxIncludedAfterDiscount ?? this.taxIncludedAfterDiscount,
      totalAfterDiscAndTax: totalAfterDiscAndTax ?? this.totalAfterDiscAndTax,
      saleModifierCount: saleModifierCount ?? this.saleModifierCount,
    );
  }

  static List<SaleItemModel> mergeWithUniqueIds(
    List<SaleItemModel> showedListSaleItems,
    List<SaleItemModel> existingItemsInDB,
  ) {
    final Map<String, SaleItemModel> uniqueMap = {};

    for (var item in showedListSaleItems) {
      uniqueMap[item.id!] = item;
    }

    for (var item in existingItemsInDB) {
      uniqueMap.putIfAbsent(item.id!, () => item);
    }

    return uniqueMap.values.toList();
  }
}
