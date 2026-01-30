import 'package:mts/core/utils/format_utils.dart';

class LicenseModel {
  String? id;
  int? worldCountryId;
  String? name;
  String? licenseKey;
  String? locale;
  String? createdAt;
  String? updatedAt;

  LicenseModel({
    this.id,
    this.worldCountryId,
    this.name,
    this.licenseKey,
    this.locale,
    this.createdAt,
    this.updatedAt,
  });

  LicenseModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    worldCountryId = FormatUtils.parseToInt(json['world_country_id']);
    name = FormatUtils.parseToString(json['name']);
    licenseKey = FormatUtils.parseToString(json['license_key']);
    locale = FormatUtils.parseToString(json['locale']);
    createdAt = FormatUtils.parseToString(json['created_at']);
    updatedAt = FormatUtils.parseToString(json['updated_at']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['world_country_id'] = worldCountryId;
    data['name'] = name;
    data['license_key'] = licenseKey;
    data['locale'] = locale;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
