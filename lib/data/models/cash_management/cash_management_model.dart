import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class CashManagementModel {
  static const String modelName = 'CashManagement';
  static const String modelBoxName = 'cash_management_box';
  String? id;
  String? staffId;
  String? shiftId;
  double? amount;
  String? comment;
  int? type;
  DateTime? createdAt;
  DateTime? updatedAt;

  CashManagementModel({
    this.id,
    this.staffId,
    this.shiftId,
    this.amount,
    this.comment,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

  CashManagementModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    staffId = FormatUtils.parseToString(json['staff_id']);
    shiftId = FormatUtils.parseToString(json['shift_id']);
    amount = FormatUtils.parseToDouble(json['amount']);
    comment = FormatUtils.parseToString(json['comment']);
    type = json['type'];
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['staff_id'] = staffId;
    data['shift_id'] = shiftId;
    data['amount'] = amount;
    data['type'] = type;
    data['comment'] = comment;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  // copy with
  CashManagementModel copyWith({
    String? id,
    String? staffId,
    String? shiftId,
    double? amount,
    String? comment,
    int? type,
    DateTime? createdAt,
    required DateTime? updatedAt,
  }) {
    return CashManagementModel(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      shiftId: shiftId ?? this.shiftId,
      amount: amount ?? this.amount,
      comment: comment ?? this.comment,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
