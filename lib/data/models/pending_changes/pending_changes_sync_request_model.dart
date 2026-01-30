import 'package:mts/data/models/pending_changes/pending_changes_model.dart';

/// Request model for syncing printer settings
class PendingChangesSyncRequestModel {
  List<PendingChangesModel>? pendingChanges;

  PendingChangesSyncRequestModel({this.pendingChanges});

  PendingChangesSyncRequestModel.fromJson(Map<String, dynamic> json) {
    if (json['changes'] != null) {
      pendingChanges = <PendingChangesModel>[];
      json['changes'].forEach((v) {
        pendingChanges!.add(PendingChangesModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (pendingChanges != null) {
      data['changes'] = pendingChanges!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
