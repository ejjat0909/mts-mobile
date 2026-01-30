import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class CustomerModel {
  /// Model name for sync handler registry
  static const String modelName = 'Customer';
  static const String modelBoxName = 'customer_box';
  String? id;
  String? companyId;
  String? name;
  String? phoneNo;
  String? email;
  String? address;
  String? postcode;
  int? worldCityId;
  int? worldDivisionId;
  int? worldCountryId;
  String? note;
  DateTime? createdAt;
  DateTime? updatedAt;

  CustomerModel({
    this.id,
    this.companyId,
    this.name,
    this.phoneNo,
    this.email,
    this.address,
    this.postcode,
    this.worldCityId,
    this.worldDivisionId,
    this.worldCountryId,
    this.note, 
    this.createdAt,
    this.updatedAt,
  });

  CustomerModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    companyId = FormatUtils.parseToString(json['company_id']);
    name = FormatUtils.parseToString(json['name']);
    phoneNo = FormatUtils.parseToString(json['phone_no']);
    email = FormatUtils.parseToString(json['email']);
    address = FormatUtils.parseToString(json['address']);
    postcode = FormatUtils.parseToString(json['postcode']);
    worldCityId =
        (json['world_city_id'] is String)
            ? int.parse(json['world_city_id'])
            : json['world_city_id'];
    worldDivisionId =
        (json['world_division_id'] is String)
            ? int.parse(json['world_division_id'])
            : json['world_division_id'];
    worldCountryId =
        (json['world_country_id'] is String)
            ? int.parse(json['world_country_id'])
            : json['world_country_id'];
    note = FormatUtils.parseToString(json['note']);
    
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['company_id'] = companyId;
    data['name'] = name;
    data['phone_no'] = phoneNo;
    data['email'] = email;
    data['address'] = address;
    data['postcode'] = postcode;
    data['world_city_id'] = worldCityId;
    data['world_division_id'] = worldDivisionId;
    data['world_country_id'] = worldCountryId;
    data['note'] = note;
    
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  CustomerModel copyWith({
    String? id,
    String? companyId,
    String? name,
    String? phoneNo,
    String? email,
    String? address,
    String? postcode,
    int? worldCityId,
    int? worldDivisionId,
    int? worldCountryId,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      phoneNo: phoneNo ?? this.phoneNo,
      email: email ?? this.email,
      address: address ?? this.address,
      postcode: postcode ?? this.postcode,
      worldCityId: worldCityId ?? this.worldCityId,
      worldDivisionId: worldDivisionId ?? this.worldDivisionId,
      worldCountryId: worldCountryId ?? this.worldCountryId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
