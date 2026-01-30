import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class ReceiptItemModel {
  static const String modelName = "ReceiptItem";
  static const String modelBoxName = 'receipt_item_box';
  String? id;
  String? receiptId;
  String? sku;
  String? barcode;
  String? name;
  String? itemId;
  double? price;
  double? cost;
  double? quantity;
  double? totalDiscount;
  double? totalTax;
  double? taxIncludedAfterDiscount;
  double? netSale;
  double? grossAmount; // qty x price
  String? categoryId;
  double totalRefunded = 0;
  bool? isRefunded;
  String? comment;
  String? soldBy;

  String? modifiers; // JSON format (name, option), cast to array List<dynamic>
  String? variants; // JSON format (name, option),  Map<String, dynamic>
  String? discounts; // JSON format (name, value), cast to array List<dynamic>
  String? taxes; // JSON format (name, value), cast to array List<dynamic>
  DateTime? createdAt;
  DateTime? updatedAt;
  ReceiptItemModel({
    this.id,
    this.receiptId,
    this.sku,
    this.barcode,
    this.name,
    this.itemId,
    this.price,
    this.cost,
    this.quantity,
    this.totalDiscount,
    this.totalTax,
    this.taxIncludedAfterDiscount,
    this.netSale,
    this.categoryId,
    this.grossAmount,
    this.totalRefunded = 0,
    this.isRefunded,
    this.comment,
    this.soldBy,
    this.modifiers,
    this.variants,
    this.discounts,
    this.taxes,
    this.createdAt,
    this.updatedAt,
  });

  ReceiptItemModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    receiptId = FormatUtils.parseToString(json['receipt_id']);
    sku = FormatUtils.parseToString(json['sku']);
    barcode = FormatUtils.parseToString(json['barcode']);
    name = FormatUtils.parseToString(json['name']);
    itemId = FormatUtils.parseToString(json['item_id']);
    price = FormatUtils.parseToDouble(json['price']);
    cost = FormatUtils.parseToDouble(json['cost']);
    quantity = FormatUtils.parseToDouble(json['quantity']);
    grossAmount = FormatUtils.parseToDouble(json['gross_amount']);
    totalDiscount = FormatUtils.parseToDouble(json['total_discount']);
    totalTax = FormatUtils.parseToDouble(json['total_tax']);
    taxIncludedAfterDiscount = FormatUtils.parseToDouble(
      json['tax_included_after_discount'],
    );
    netSale = FormatUtils.parseToDouble(json['net_sale']);
    categoryId = FormatUtils.parseToString(json['category_id']);
    totalRefunded = FormatUtils.parseToDouble(json['total_refunded']) ?? 0;
    isRefunded = FormatUtils.parseToBool(json['is_refunded']);
    comment = FormatUtils.parseToString(json['comment']);
    soldBy = FormatUtils.parseToString(json['sold_by']);
    modifiers = FormatUtils.parseToString(json['modifiers']);
    variants = FormatUtils.parseToString(json['variants']);
    discounts = FormatUtils.parseToString(json['discounts']);
    taxes = FormatUtils.parseToString(json['taxes']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['receipt_id'] = receiptId;
    data['sku'] = sku;
    data['barcode'] = barcode;
    data['name'] = name;
    data['item_id'] = itemId;
    data['price'] = price;
    data['cost'] = cost;
    data['quantity'] = quantity;
    data['gross_amount'] = grossAmount;
    data['total_discount'] = totalDiscount;
    data['total_tax'] = totalTax;
    data['tax_included_after_discount'] = taxIncludedAfterDiscount;
    data['net_sale'] = netSale;
    data['category_id'] = categoryId;
    data['total_refunded'] = totalRefunded;
    data['is_refunded'] = FormatUtils.boolToInt(isRefunded);
    data['comment'] = comment;
    data['sold_by'] = soldBy;
    //data['total_temp_refund'] = this.totalTempRefund;
    data['modifiers'] = modifiers;
    data['variants'] = variants;
    data['discounts'] = discounts;
    data['taxes'] = taxes;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  // create copy with
  ReceiptItemModel copyWith({
    String? id,
    String? receiptId,
    String? sku,
    String? barcode,
    String? name,
    String? itemId,
    double? price,
    double? cost,
    double? quantity,
    double? grossAmount,
    double? totalDiscount,
    double? totalTax,
    double? taxIncludedAfterDiscount,
    double? netSale,
    String? categoryId,
    double? totalRefunded,
    bool? isRefunded,
    String? comment,
    String? soldBy,
    String? modifiers,
    String? variants,
    String? discounts,
    String? taxes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReceiptItemModel(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      itemId: itemId ?? this.itemId,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      quantity: quantity ?? this.quantity,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      totalTax: totalTax ?? this.totalTax,
      taxIncludedAfterDiscount:
          taxIncludedAfterDiscount ?? this.taxIncludedAfterDiscount,
      netSale: netSale ?? this.netSale,
      categoryId: categoryId ?? this.categoryId,
      totalRefunded: totalRefunded ?? this.totalRefunded,
      isRefunded: isRefunded ?? this.isRefunded,
      comment: comment ?? this.comment,
      grossAmount: grossAmount ?? this.grossAmount,
      soldBy: soldBy ?? this.soldBy,
      modifiers: modifiers ?? this.modifiers,
      variants: variants ?? this.variants,
      discounts: discounts ?? this.discounts,
      taxes: taxes ?? this.taxes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
