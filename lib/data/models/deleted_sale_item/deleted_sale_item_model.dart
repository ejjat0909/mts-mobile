import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class DeletedSaleItemModel {
  static const String modelName = 'DeletedSaleItem';
  static const String modelBoxName = 'deleted_sale_item_box';
  String? id;
  String? staffName;
  String? orderNumber;
  String? itemQuantity;
  String? itemPrice;
  String? itemTotalPrice;
  String? itemName;
  String? itemSku;
  String? itemModifiers;
  String? itemVariant;
  String? posDeviceName;
  String? posDeviceCode;
  String? outletName;
  String? outletId;
  String? companyId;
  DateTime? createdAt;
  DateTime? updatedAt;

  DeletedSaleItemModel({
    this.id,
    this.staffName,
    this.orderNumber,
    this.itemQuantity,
    this.itemPrice,
    this.itemTotalPrice,
    this.itemName,
    this.itemSku,
    this.itemModifiers,
    this.itemVariant,
    this.posDeviceName,
    this.posDeviceCode,
    this.outletName,
    this.outletId,
    this.companyId,
    this.createdAt,
    this.updatedAt,
  });

  DeletedSaleItemModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    staffName = FormatUtils.parseToString(json['staff_name']);
    orderNumber = FormatUtils.parseToString(json['order_number']);
    itemQuantity = FormatUtils.parseToString(json['item_quantity']);
    itemPrice = FormatUtils.parseToString(json['item_price']);
    itemTotalPrice = FormatUtils.parseToString(json['item_total_price']);
    itemName = FormatUtils.parseToString(json['item_name']);
    itemSku = FormatUtils.parseToString(json['item_sku']);
    itemModifiers = FormatUtils.parseToString(json['item_modifiers']);
    itemVariant = FormatUtils.parseToString(json['item_variant']);
    posDeviceName = FormatUtils.parseToString(json['pos_device_name']);
    posDeviceCode = FormatUtils.parseToString(json['pos_device_code']);
    outletName = FormatUtils.parseToString(json['outlet_name']);
    outletId = FormatUtils.parseToString(json['outlet_id']);
    companyId = FormatUtils.parseToString(json['company_id']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['staff_name'] = staffName;
    data['order_number'] = orderNumber;
    data['item_quantity'] = itemQuantity;
    data['item_price'] = itemPrice;
    data['item_total_price'] = itemTotalPrice;
    data['item_name'] = itemName;
    data['item_sku'] = itemSku;
    data['item_modifiers'] = itemModifiers;
    data['item_variant'] = itemVariant;
    data['pos_device_name'] = posDeviceName;
    data['pos_device_code'] = posDeviceCode;
    data['outlet_name'] = outletName;
    data['outlet_id'] = outletId;
    data['company_id'] = companyId;

    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  // copy with
  DeletedSaleItemModel copyWith({
    String? id,
    String? staffName,
    String? orderNumber,
    String? itemQuantity,
    String? itemPrice,
    String? itemTotalPrice,
    String? itemName,
    String? itemSku,
    String? itemModifiers,
    String? itemVariant,
    String? posDeviceName,
    String? posDeviceCode,
    String? outletName,
    String? outletId,
    String? companyId,
    DateTime? createdAt,
    required DateTime? updatedAt,
  }) {
    return DeletedSaleItemModel(
      id: id ?? this.id,
      staffName: staffName ?? this.staffName,
      orderNumber: orderNumber ?? this.orderNumber,
      itemQuantity: itemQuantity ?? this.itemQuantity,
      itemPrice: itemPrice ?? this.itemPrice,
      itemTotalPrice: itemTotalPrice ?? this.itemTotalPrice,
      itemName: itemName ?? this.itemName,
      itemSku: itemSku ?? this.itemSku,
      itemModifiers: itemModifiers ?? this.itemModifiers,
      itemVariant: itemVariant ?? this.itemVariant,
      posDeviceName: posDeviceName ?? this.posDeviceName,
      posDeviceCode: posDeviceCode ?? this.posDeviceCode,
      outletName: outletName ?? this.outletName,
      outletId: outletId ?? this.outletId,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
