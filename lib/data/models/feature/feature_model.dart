import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class FeatureModel {
  /// Model name for sync handler registry
  static const String modelName = 'Feature';
  static const String modelBoxName = 'feature_box';

  String? id;
  String? name;
  String? description;
  String? icon;
  DateTime? createdAt;
  DateTime? updatedAt;

  FeatureModel({
    this.id,
    this.name,
    this.description,
    this.icon,
    this.createdAt,
    this.updatedAt,
  });

  FeatureModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    name = FormatUtils.parseToString(json['name']);
    description = FormatUtils.parseToString(json['description']);
    icon = FormatUtils.parseToString(json['icon']);

    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['icon'] = icon;

    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }

    return data;
  }

  FeatureModel copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    DateTime? createdAt,
    required DateTime? updatedAt,
  }) {
    return FeatureModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
