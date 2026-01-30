import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class CityModel {
  // Static model name for use in pending changes
  static const String modelName = 'City';
  static const String modelBoxName = 'city_box';

  // Properties
  int? id;
  String? code;
  int? countryId;
  int? divisionId;
  String? fullName;
  String? name;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Constructor
  CityModel({
    this.id,
    this.code,
    this.countryId,
    this.divisionId,
    this.fullName,
    this.name,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor from JSON
  CityModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToInt(json['id']);
    code = FormatUtils.parseToString(json['code']);
    countryId =
        json['country_id'] != null
            ? int.tryParse(json['country_id'].toString())
            : null;
    divisionId =
        json['division_id'] != null
            ? int.tryParse(json['division_id'].toString())
            : null;
    fullName = FormatUtils.parseToString(json['full_name']);
    name = FormatUtils.parseToString(json['name']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['code'] = code;
    data['country_id'] = countryId;
    data['division_id'] = divisionId;
    data['full_name'] = fullName;
    data['name'] = name;

    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }

    return data;
  }

  // Copy with method for immutability
  CityModel copyWith({
    int? id,
    String? code,
    int? countryId,
    int? divisionId,
    String? fullName,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CityModel(
      id: id ?? this.id,
      code: code ?? this.code,
      countryId: countryId ?? this.countryId,
      divisionId: divisionId ?? this.divisionId,
      fullName: fullName ?? this.fullName,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
