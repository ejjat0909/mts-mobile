import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class StaffModel {
  /// Model name for sync handler registry
  static const String modelName = 'Staff';
  static const String modelBoxName = 'staff_box';
  String? id;
  String? pin;
  int? userId;

  String? companyId;
  String? roleGroupId;
  String? currentShiftId;
  DateTime? createdAt;
  DateTime? updatedAt;

  StaffModel({
    this.id,
    this.pin,
    this.userId,

    this.companyId,
    this.currentShiftId,
    this.roleGroupId,
    this.createdAt,
    this.updatedAt,
  });

  StaffModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    pin = json['pin'].toString();
    userId = json['user_id'];

    companyId = FormatUtils.parseToString(json['company_id']);
    currentShiftId = FormatUtils.parseToString(json['current_shift_id']);
    roleGroupId = FormatUtils.parseToString(json['role_group_id']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['pin'] = pin;
    data['user_id'] = userId;

    // data['pos_permissions'] = posPermissionJson;

    data['current_shift_id'] = currentShiftId;
    data['company_id'] = companyId;
    data['role_group_id'] = roleGroupId;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  // copy with
  StaffModel copyWith({
    String? id,
    String? pin,
    int? userId,
    String? outletId,
    String? companyId,
    String? currentShiftId,
    String? roleGroupId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffModel(
      id: id ?? this.id,
      pin: pin ?? this.pin,
      userId: userId ?? this.userId,

      companyId: companyId ?? this.companyId,
      // because current shift id can be null when clock out and close shift
      currentShiftId: currentShiftId,
      roleGroupId: roleGroupId ?? this.roleGroupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
