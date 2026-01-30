import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class ItemModifierModel {
  /// Model name for sync handler registry
  static const String modelName = 'ItemModifier';
  static const String modelBoxName = 'item_modifier_box';
  String? itemId;
  String? modifierId;
  DateTime? createdAt;
  DateTime? updatedAt;

  ItemModifierModel({
    this.itemId,
    this.modifierId,
    this.createdAt,
    this.updatedAt,
  });

  ItemModifierModel.fromJson(Map<String, dynamic> json) {
    itemId = FormatUtils.parseToString(json['item_id']);
    modifierId = FormatUtils.parseToString(json['modifier_id']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['item_id'] = itemId;
    data['modifier_id'] = modifierId;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }
}
