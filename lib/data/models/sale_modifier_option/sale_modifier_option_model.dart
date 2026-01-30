import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class SaleModifierOptionModel {
  static const String modelName = 'SaleModifierOption';
  static const String modelBoxName = 'sale_modifier_option_box';
  String? id;
  String? saleModifierId;
  String? modifierOptionId;
  DateTime? createdAt;
  DateTime? updatedAt;

  SaleModifierOptionModel({
    this.id,
    this.saleModifierId,
    this.modifierOptionId,
    this.createdAt,
    this.updatedAt,
  });

  SaleModifierOptionModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    saleModifierId = FormatUtils.parseToString(json['sale_modifier_id']);
    modifierOptionId = FormatUtils.parseToString(json['modifier_option_id']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['sale_modifier_id'] = saleModifierId;
    data['modifier_option_id'] = modifierOptionId;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
  
    return data;
  }

  // copy with
  SaleModifierOptionModel copyWith({
    String? id,
    String? saleModifierId,
    String? modifierOptionId,
    DateTime? createdAt,
    DateTime? updatedAt,
   
  }) {
    return SaleModifierOptionModel(
      id: id ?? this.id,
      saleModifierId: saleModifierId ?? this.saleModifierId,
      modifierOptionId: modifierOptionId ?? this.modifierOptionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    
    );
  }

  static List<SaleModifierOptionModel> mergeWithUniqueIds(
    List<SaleModifierOptionModel> listOne,
    List<SaleModifierOptionModel> listTwo,
  ) {
    final Map<String, SaleModifierOptionModel> uniqueMap = {};
    
    for (var item in listOne) {
      uniqueMap[item.id!] = item;
    }
    
    for (var item in listTwo) {
      uniqueMap.putIfAbsent(item.id!, () => item);
    }
    
    return uniqueMap.values.toList();
  }
}
