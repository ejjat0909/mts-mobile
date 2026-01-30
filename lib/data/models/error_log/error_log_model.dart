import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class ErrorLogModel {
  /// model name
  static const String modelName = 'ErrorLog';
  static const String modelBoxName = 'error_log_box';
  String? id;
  String? description;
  String? posDeviceId;
  String? deviceName;
  int? userId;
  String? currentUserName;
  DateTime? createdAt;
  DateTime? updatedAt;

  ErrorLogModel({
    this.id,
    this.description,
    this.posDeviceId,
    this.deviceName,
    this.userId,
    this.currentUserName,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['description'] = description;
    data['pos_device_id'] = posDeviceId;
    data['device_name'] = deviceName;
    data['user_id'] = userId;
    data['current_user_name'] = currentUserName;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  ErrorLogModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    description = FormatUtils.parseToString(json['description']);
    posDeviceId = FormatUtils.parseToString(json['pos_device_id']);
    deviceName = FormatUtils.parseToString(json['device_name']);
    userId = FormatUtils.parseToInt(json['user_id']);
    currentUserName = FormatUtils.parseToString(json['current_user_name']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  // Copy with method for immutability
  ErrorLogModel copyWith({
    String? id,
    String? description,
    String? posDeviceId,
    String? deviceName,
    int? currentUserId,
    String? currentUserName,
    DateTime? createdAt,
    required DateTime? updatedAt,
  }) {
    return ErrorLogModel(
      id: id ?? this.id,
      description: description ?? this.description,
      posDeviceId: posDeviceId ?? posDeviceId,
      deviceName: deviceName ?? this.deviceName,
      userId: currentUserId ?? userId,
      currentUserName: currentUserName ?? this.currentUserName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
