import 'package:mts/core/utils/format_utils.dart';

class DiscountSaleItemModel {
  static const modelName = 'DiscountSaleItem';
  static const String modelBoxName = 'discount_sale_item_box';

  String? discountId;
  String? saleItemId;

  DiscountSaleItemModel({this.discountId, this.saleItemId});

  DiscountSaleItemModel.fromJson(Map<String, dynamic> json) {
    discountId = FormatUtils.parseToString(json['discount_id']);
    saleItemId = FormatUtils.parseToString(json['sale_item_id']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['discount_id'] = discountId;
    data['sale_item_id'] = saleItemId;
    return data;
  }
}
