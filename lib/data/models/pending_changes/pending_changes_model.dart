// ignore_for_file: non_constant_identifier_names

import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class PendingChangesModel {
  static const String modelBoxName = 'pending_changes_box';
  String? id;
  String? operation; // updated created deleted
  String? modelName;
  String? modelId;
  String? data;
  DateTime? createdAt; // the date that changes occur

  PendingChangesModel({
    this.id,
    this.operation,
    this.modelName,
    this.modelId,
    this.data,
    this.createdAt,
  });

  PendingChangesModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    operation = FormatUtils.parseToString(json['operation']);
    modelName = FormatUtils.parseToString(json['model_name']);
    modelId = FormatUtils.parseToString(json['model_id']);
    data = FormatUtils.parseToString(json['data']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> datas = <String, dynamic>{};
    datas['id'] = id;
    datas['operation'] = operation;
    datas['model_name'] = modelName;
    datas['model_id'] = modelId;
    datas['data'] = data;
    if (createdAt != null) {
      datas['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    return datas;
  }
}
