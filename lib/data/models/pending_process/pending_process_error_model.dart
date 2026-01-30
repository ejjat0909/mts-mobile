import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';

class PendingProcessErrorModel extends PendingChangesModel {
  String? error;

  PendingProcessErrorModel({
    super.modelName,
    super.modelId,
    super.operation,
    this.error,
  });

  PendingProcessErrorModel.fromJson(Map<String, dynamic> json)
    : super.fromJson(json) {
    error = FormatUtils.parseToString(json['error']);
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['error'] = error;
    return data;
  }
}
