import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class UserModel {
  /// Model name for sync handler registry
  static const String modelName = 'User';
  static const String modelBoxName = 'user_box';
  int? id;
  String? name;
  String? email;
  String? phoneNo;
  String? accessToken;
  String? posPermissionJson;
  DateTime? createdAt;
  DateTime? updatedAt;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.phoneNo,
    this.posPermissionJson,
    this.accessToken,
    this.createdAt,
    this.updatedAt,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToInt(json['id']);
    name = FormatUtils.parseToString(json['name']);
    email = FormatUtils.parseToString(json['email']);
    phoneNo = FormatUtils.parseToString(json['phone_no']);
    accessToken = FormatUtils.parseToString(json['access_token']);
    posPermissionJson = FormatUtils.parseToString(json['pos_permissions']);

    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['phone_no'] = phoneNo;
    data['pos_permissions'] = posPermissionJson;
    data['access_token'] = accessToken;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  //
  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phoneNo,
    String? posPermissionJson,
    String? accessToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNo: phoneNo ?? this.phoneNo,
      posPermissionJson: posPermissionJson ?? this.posPermissionJson,
      accessToken: accessToken ?? this.accessToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
