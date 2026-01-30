class SyncCheckModel {
  bool? changesDetected;
  List<String>? modelsToSync;

  SyncCheckModel({this.changesDetected, this.modelsToSync});

  factory SyncCheckModel.fromJson(Map<String, dynamic> json) {
    return SyncCheckModel(
      changesDetected: json['changes_detected'] as bool? ?? false,
      modelsToSync: List<String>.from(json['models_to_sync'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'changes_detected': changesDetected,
      'models_to_sync': modelsToSync,
    };
  }
}
