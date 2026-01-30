import 'package:mts/core/utils/format_utils.dart';

class DivisionModel {
  // Static model name for use in pending changes
  static const String modelName = 'Division';
  static const String modelBoxName = 'division_box';

  // Properties
  int? id;
  String? code;
  int? countryId;
  String? fullName;
  int? hasCity;
  String? name;

  // Constructor
  DivisionModel({
    this.id,
    this.code,
    this.countryId,
    this.fullName,
    this.hasCity,
    this.name,
  });

  // Factory constructor from JSON
  DivisionModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToInt(json['id']);
    code = FormatUtils.parseToString(json['code']);
    countryId = FormatUtils.parseToInt(json['country_id']);
    fullName = FormatUtils.parseToString(json['full_name']);
    hasCity = FormatUtils.parseToInt(json['has_city']);
    name = FormatUtils.parseToString(json['name']);
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['code'] = code;
    data['country_id'] = countryId;
    data['full_name'] = fullName;
    data['has_city'] = hasCity;
    data['name'] = name;

    return data;
  }

  // Copy with method for immutability
  DivisionModel copyWith({
    int? id,
    String? code,
    int? countryId,
    String? fullName,
    int? hasCity,
    String? name,
  }) {
    return DivisionModel(
      id: id ?? this.id,
      code: code ?? this.code,
      countryId: countryId ?? this.countryId,
      fullName: fullName ?? this.fullName,
      hasCity: hasCity ?? this.hasCity,
      name: name ?? this.name,
    );
  }
}
