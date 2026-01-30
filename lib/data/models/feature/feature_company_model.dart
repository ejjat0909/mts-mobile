import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class FeatureCompanyModel {
  /// Model name for sync handler registry
  static const String modelName = 'FeatureCompany';
  static const String modelBoxName = 'feature_company_box';

  String? featureId;
  String? companyId;
  bool? isActive;
  DateTime? createdAt;
  DateTime? updatedAt;

  FeatureCompanyModel({
    this.featureId,
    this.companyId,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  FeatureCompanyModel.fromJson(Map<String, dynamic> json) {
    featureId = FormatUtils.parseToString(json['feature_id']);
    companyId = FormatUtils.parseToString(json['company_id']);
    isActive = FormatUtils.parseToBool(json['is_active']);

    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['feature_id'] = featureId;
    data['company_id'] = companyId;
    data['is_active'] = FormatUtils.boolToInt(isActive);

    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }

    return data;
  }

  FeatureCompanyModel copyWith({
    String? featureId,
    String? companyId,
    bool? isActive,
    DateTime? createdAt,
    required DateTime? updatedAt,
  }) {
    return FeatureCompanyModel(
      featureId: featureId ?? this.featureId,
      companyId: companyId ?? this.companyId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
