import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class OutletModel {
  /// Model name for sync handler registry
  static const String modelName = 'Outlet';
  static const String modelBoxName = 'outlet_box';
  String? id;
  String? name;
  String? address;
  String? postcode;
  String? phoneNo;
  String? description;
  int? nextOrderNumber;
  String? companyId;
  bool? isEnabledOpenOrder;
  int? worldCountryId;
  int? worldDivisionId;
  int? worldCityId;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? fullAddress;

  OutletModel({
    this.id,
    this.name,
    this.address,
    this.postcode,
    this.phoneNo,
    this.description,
    this.companyId,
    this.isEnabledOpenOrder,
    this.nextOrderNumber,
    this.worldCountryId,
    this.worldDivisionId,
    this.worldCityId,
    this.createdAt,
    this.updatedAt,
    this.fullAddress,
  });

  OutletModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    address = json['address'];
    postcode = json['postcode'];
    phoneNo = json['phone_no'];
    description = json['description'];
    companyId = json['company_id'];
    nextOrderNumber = FormatUtils.parseToInt(json['next_order_number']);
    isEnabledOpenOrder = FormatUtils.parseToBool(json['is_enabled_open_order']);
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
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
    fullAddress = json['full_address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['address'] = address;
    data['postcode'] = postcode;
    data['phone_no'] = phoneNo;
    data['description'] = description;
    data['company_id'] = companyId;
    data['next_order_number'] = nextOrderNumber;
    data['is_enabled_open_order'] = FormatUtils.boolToInt(isEnabledOpenOrder);
    data['world_country_id'] = worldCountryId;
    data['world_division_id'] = worldDivisionId;
    data['world_city_id'] = worldCityId;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    data['full_address'] = fullAddress;
    return data;
  }

  // copy with
  OutletModel copyWith({
    String? id,
    String? name,
    String? address,
    String? postcode,
    String? phoneNo,
    String? description,
    int? nextOrderNumber,
    String? companyId,
    bool? isEnabledOpenOrder,
    int? worldCountryId,
    int? worldDivisionId,
    int? worldCityId,
    DateTime? createdAt,
    required DateTime? updatedAt,
  }) {
    return OutletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      postcode: postcode ?? this.postcode,
      phoneNo: phoneNo ?? this.phoneNo,
      description: description ?? this.description,
      nextOrderNumber: nextOrderNumber ?? this.nextOrderNumber,
      companyId: companyId ?? this.companyId,
      isEnabledOpenOrder: isEnabledOpenOrder ?? this.isEnabledOpenOrder,
      worldCountryId: worldCountryId ?? this.worldCountryId,
      worldDivisionId: worldDivisionId ?? this.worldDivisionId,
      worldCityId: worldCityId ?? this.worldCityId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
