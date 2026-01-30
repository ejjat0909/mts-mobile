import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class SupplierModel {
  /// Model name for sync handler registry
  static const String modelName = 'Supplier';
  static const String modelBoxName = 'supplier_box';

  String? id;
  String? name;
  String? email;
  String? phoneNo;
  String? description;
  DateTime? createdAt;
  DateTime? updatedAt;

  SupplierModel({
    this.id,
    this.name,
    this.email,
    this.phoneNo,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  SupplierModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    name = FormatUtils.parseToString(json['name']);
    email = FormatUtils.parseToString(json['email']);
    phoneNo = FormatUtils.parseToString(json['phone_no']);
    description = FormatUtils.parseToString(json['description']);

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
    data['description'] = description;

    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  SupplierModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNo,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNo: phoneNo ?? this.phoneNo,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
