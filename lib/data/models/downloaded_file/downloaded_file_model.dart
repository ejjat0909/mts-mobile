import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class DownloadedFileModel {
  static const String modelName = 'DownloadedFile';
  static const String modelBoxName = 'downloaded_file_box';
  String? id;
  String? url;
  String? nameModel;
  String? modelId;
  String? path;
  String? fileName;
  bool? isDownloaded;
  DateTime? createdAt;
  DateTime? updatedAt;

  DownloadedFileModel({
    this.id,
    this.nameModel,
    this.modelId,
    this.url,
    this.path,
    this.fileName,
    this.isDownloaded,
    this.createdAt,
    this.updatedAt,
  });

  DownloadedFileModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    nameModel = FormatUtils.parseToString(json['name_model']);
    modelId = FormatUtils.parseToString(json['model_id']);
    url = FormatUtils.parseToString(json['url']);
    path = FormatUtils.parseToString(json['path']);
    fileName = FormatUtils.parseToString(json['file_name']);
    isDownloaded = FormatUtils.parseToBool(json['is_downloaded']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name_model'] = nameModel;
    data['model_id'] = modelId;
    data['url'] = url;
    data['path'] = path;
    data['file_name'] = fileName;
    data['is_downloaded'] = FormatUtils.boolToInt(isDownloaded);
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  // copywith
  DownloadedFileModel copyWith({
    String? id,
    String? nameModel,
    String? modelId,
    String? url,
    String? path,
    String? fileName,
    bool? isDownloaded,
    DateTime? createdAt,
    required DateTime? updatedAt,
  }) {
    return DownloadedFileModel(
      id: id ?? this.id,
      nameModel: nameModel ?? this.nameModel,
      modelId: modelId ?? this.modelId,
      url: url ?? this.url,
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
