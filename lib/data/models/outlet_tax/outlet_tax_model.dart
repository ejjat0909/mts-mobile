import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class OutletTaxModel {
  static const String modelName = 'OutletTax';
  static const String modelBoxName = 'outlet_tax_box';

  // Properties
  String? outletId;
  String? taxId;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Constructor
  OutletTaxModel({this.outletId, this.taxId, this.createdAt, this.updatedAt});

  // Factory constructor from JSON
  OutletTaxModel.fromJson(Map<String, dynamic> json) {
    outletId = FormatUtils.parseToString(json['outlet_id']);
    taxId = FormatUtils.parseToString(json['tax_id']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['outlet_id'] = outletId;
    data['tax_id'] = taxId;

    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }

    return data;
  }

  // Copy with method for immutability
  OutletTaxModel copyWith({
    String? outletId,
    String? taxId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OutletTaxModel(
      outletId: outletId ?? this.outletId,
      taxId: taxId ?? this.taxId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
