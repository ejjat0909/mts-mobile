import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class TimecardModel {
  static const String modelName = 'Timecard';
  static const String modelBoxName = 'timecard_box';
  String? id;
  String? staffId;
  String? outletId;
  String? shiftId;
  DateTime? clockIn;
  DateTime? clockOut;

  // if total hour 1 hour 30 minutes, it will be 1.5
  double? totalHour;
  DateTime? createdAt;
  DateTime? updatedAt;

  TimecardModel({
    this.id,
    this.staffId,
    this.outletId,
    this.shiftId,
    this.clockIn,
    this.clockOut,
    this.totalHour,
    this.createdAt,
    this.updatedAt,
  });

  TimecardModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    staffId = FormatUtils.parseToString(json['staff_id']);
    outletId = FormatUtils.parseToString(json['outlet_id']);
    shiftId = FormatUtils.parseToString(json['shift_id']);
    clockIn =
        json['clock_in'] != null ? DateTime.parse(json['clock_in']) : null;
    clockOut =
        json['clock_out'] != null ? DateTime.parse(json['clock_out']) : null;
    totalHour = FormatUtils.parseToDouble(json['total_hour']) ?? 0.00;
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['staff_id'] = staffId;
    data['outlet_id'] = outletId;
    data['shift_id'] = shiftId;
    if (clockIn != null) {
      data['clock_in'] = DateTimeUtils.getDateTimeFormat(clockIn);
    }
    if (clockOut != null) {
      data['clock_out'] = DateTimeUtils.getDateTimeFormat(clockOut);
    } else {
      data['clock_out'] = null;
    }
    data['total_hour'] = totalHour;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  // copywith
  TimecardModel copyWith({
    String? id,
    String? staffId,
    String? shiftId,
    String? outletId,
    DateTime? clockIn,
    DateTime? clockOut,
    double? totalHour,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimecardModel(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      outletId: outletId ?? this.outletId,
      shiftId: shiftId ?? this.shiftId,
      clockIn: clockIn ?? this.clockIn,
      clockOut: clockOut ?? this.clockOut,
      totalHour: totalHour ?? this.totalHour,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
