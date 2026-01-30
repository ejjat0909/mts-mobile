import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class DeletedModel {
  static const String modelName = 'DeletedModel';
  static const String modelBoxName = 'deleted_box';

  int? id;
  String? model;
  String? modelId;
  DateTime? createdAt;
  DateTime? updatedAt;

  DeletedModel({
    this.id,
    this.model,
    this.modelId,
    this.createdAt,
    this.updatedAt,
  });

  DeletedModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    model = FormatUtils.parseToString(json['model']);
    modelId = FormatUtils.parseToString(json['model_id']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['model'] = model;
    data['model_id'] = modelId;

    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }

    return data;
  }

  DeletedModel copyWith({
    int? id,
    String? model,
    String? modelId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeletedModel(
      id: id ?? this.id,
      model: model ?? this.model,
      modelId: modelId ?? this.modelId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
