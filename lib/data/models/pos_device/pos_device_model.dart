import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class PosDeviceModel {
  /// Model name for sync handler registry
  static const String modelName = 'PosDevice';
  static const String modelBoxName = 'pos_device_box';
  String? id;
  String? outletId;
  String? name;
  String? code;
  int? nextRnReceipt;
  bool? isActive;
  DateTime? createdAt;
  DateTime? updatedAt;

  PosDeviceModel({
    this.id,
    this.outletId,
    this.name,
    this.code,
    this.nextRnReceipt,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  PosDeviceModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    outletId = FormatUtils.parseToString(json['outlet_id']);
    name = FormatUtils.parseToString(json['name']);
    code = FormatUtils.parseToString(json['code']);
    nextRnReceipt = FormatUtils.parseToInt(json['next_rn_receipt']);
    isActive = FormatUtils.parseToBool(json['is_active']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['outlet_id'] = outletId;
    data['name'] = name;
    data['code'] = code;
    data['next_rn_receipt'] = nextRnReceipt;
    data['is_active'] = FormatUtils.boolToInt(isActive);

    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }

    return data;
  }

  // copy with
  PosDeviceModel copyWith({
    String? id,
    String? outletId,
    String? name,
    int? nextRnReceipt,
    int? nextOrderNumber,
    String? code,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PosDeviceModel(
      id: id ?? this.id,
      outletId: outletId ?? this.outletId,
      name: name ?? this.name,
      nextRnReceipt: nextRnReceipt ?? this.nextRnReceipt,
      code: code ?? this.code,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
