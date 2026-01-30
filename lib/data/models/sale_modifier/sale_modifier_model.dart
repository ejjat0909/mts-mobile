import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class SaleModifierModel {
  static const String modelName = 'SaleModifier';
  static const String modelBoxName = 'sale_modifier_box';
  String? id;
  String? saleItemId;
  String? modifierId;
  int? saleModifierOptionCount;
  DateTime? createdAt;
  DateTime? updatedAt;

  SaleModifierModel({
    this.id,
    this.saleItemId,
    this.modifierId,
    this.saleModifierOptionCount,
    this.createdAt,
    this.updatedAt,
  });

  SaleModifierModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    saleItemId = FormatUtils.parseToString(json['sale_item_id']);
    modifierId = FormatUtils.parseToString(json['modifier_id']);
    saleModifierOptionCount = FormatUtils.parseToInt(json['sale_modifier_option_count']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
    
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['sale_item_id'] = saleItemId;
    data['modifier_id'] = modifierId;
    data['sale_modifier_option_count'] = saleModifierOptionCount;

    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    
    return data;
  }

  // copy with
  SaleModifierModel copyWith({
    String? id,
    String? saleItemId,
    String? modifierId,
    int? saleModifierOptionCount,
    DateTime? createdAt,
    DateTime? updatedAt,
 
  }) {
    return SaleModifierModel(
      id: id ?? this.id,
      saleItemId: saleItemId ?? this.saleItemId,
      modifierId: modifierId ?? this.modifierId,
      saleModifierOptionCount: saleModifierOptionCount ?? this.saleModifierOptionCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    
    );
  }

  static List<SaleModifierModel> mergeWithUniqueIds(
    List<SaleModifierModel> listOne,
    List<SaleModifierModel> listTwo,
  ) {
    final Map<String, SaleModifierModel> uniqueMap = {};
    
    for (var item in listOne) {
      uniqueMap[item.id!] = item;
    }
    
    for (var item in listTwo) {
      uniqueMap.putIfAbsent(item.id!, () => item);
    }
    
    return uniqueMap.values.toList();
  }
}
