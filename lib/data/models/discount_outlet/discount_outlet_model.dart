import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class DiscountOutletModel {
  static const String modelName = "DiscountOutlet";
  static const String modelBoxName = 'discount_outlet_box';
  String? discountId;
  String? outletId;
  DateTime? createdAt;
  DateTime? updatedAt;

  DiscountOutletModel({
    this.discountId,
    this.outletId,
    this.createdAt,
    this.updatedAt,
  });

  DiscountOutletModel.fromJson(Map<String, dynamic> json) {
    discountId = FormatUtils.parseToString(json['discount_id']);
    outletId = FormatUtils.parseToString(json['outlet_id']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['discount_id'] = discountId;
    data['outlet_id'] = outletId;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  DiscountOutletModel copyWith({
    String? discountId,
    String? outletId,
    DateTime? createdAt,
    required DateTime? updatedAt,
  }) {
    return DiscountOutletModel(
      discountId: discountId ?? this.discountId,
      outletId: outletId ?? this.outletId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
