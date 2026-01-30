import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/pending_process/pending_process_error_model.dart';

class PendingProcessDataModel {
  List<PendingChangesModel>? processed;
  List<PendingProcessErrorModel>? errors;

  PendingProcessDataModel({this.processed, this.errors});

  PendingProcessDataModel.fromJson(Map<String, dynamic> json) {
    if (json['processed'] != null) {
      processed = <PendingChangesModel>[];
      json['processed'].forEach((v) {
        processed!.add(PendingChangesModel.fromJson(v));
      });
    }
    if (json['errors'] != null) {
      errors = <PendingProcessErrorModel>[];
      json['errors'].forEach((v) {
        errors!.add(PendingProcessErrorModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (processed != null) {
      data['processed'] = processed!.map((v) => v.toJson()).toList();
    }
    if (errors != null) {
      data['errors'] = errors!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
