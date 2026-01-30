import 'package:mts/core/utils/format_utils.dart';

class CountryModel {
  // Static model name for use in pending changes
  static const String modelName = 'Country';
  static const String modelBoxName = 'country_box';

  // Properties
  int? id;
  String? callingCode;
  String? capital;
  String? code;
  String? codeAlpha3;
  int? continentId;
  String? currencyCode;
  String? currencyName;
  String? emoji;
  String? fullName;
  int? hasDivision;
  String? name;
  String? tld;

  // Constructor
  CountryModel({
    this.id,
    this.callingCode,
    this.capital,
    this.code,
    this.codeAlpha3,
    this.continentId,
    this.currencyCode,
    this.currencyName,
    this.emoji,
    this.fullName,
    this.hasDivision,
    this.name,
    this.tld,
  });

  // Factory constructor from JSON
  CountryModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToInt(json['id']);
    callingCode = FormatUtils.parseToString(json['callingcode']);
    capital = FormatUtils.parseToString(json['capital']);
    code = FormatUtils.parseToString(json['code']);
    codeAlpha3 = FormatUtils.parseToString(json['code_alpha3']);
    continentId = FormatUtils.parseToInt(json['continent_id']);
    currencyCode = FormatUtils.parseToString(json['currency_code']);
    currencyName = FormatUtils.parseToString(json['currency_name']);
    emoji = FormatUtils.parseToString(json['emoji']);
    fullName = FormatUtils.parseToString(json['full_name']);
    hasDivision = FormatUtils.parseToInt(json['has_division']);
    name = FormatUtils.parseToString(json['name']);
    tld = FormatUtils.parseToString(json['tld']);
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['callingcode'] = callingCode;
    data['capital'] = capital;
    data['code'] = code;
    data['code_alpha3'] = codeAlpha3;
    data['continent_id'] = continentId;
    data['currency_code'] = currencyCode;
    data['currency_name'] = currencyName;
    data['emoji'] = emoji;
    data['full_name'] = fullName;
    data['has_division'] = hasDivision;
    data['name'] = name;
    data['tld'] = tld;

    return data;
  }

  // Copy with method for immutability
  CountryModel copyWith({
    int? id,
    String? callingCode,
    String? capital,
    String? code,
    String? codeAlpha3,
    int? continentId,
    String? currencyCode,
    String? currencyName,
    String? emoji,
    String? fullName,
    int? hasDivision,
    String? name,
    String? tld,
  }) {
    return CountryModel(
      id: id ?? this.id,
      callingCode: callingCode ?? this.callingCode,
      capital: capital ?? this.capital,
      code: code ?? this.code,
      codeAlpha3: codeAlpha3 ?? this.codeAlpha3,
      continentId: continentId ?? this.continentId,
      currencyCode: currencyCode ?? this.currencyCode,
      currencyName: currencyName ?? this.currencyName,
      emoji: emoji ?? this.emoji,
      fullName: fullName ?? this.fullName,
      hasDivision: hasDivision ?? this.hasDivision,
      name: name ?? this.name,
      tld: tld ?? this.tld,
    );
  }
}
