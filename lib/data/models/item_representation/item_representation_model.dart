import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class ItemRepresentationModel {
  static const String modelName = 'ItemRepresentation';
  static const String modelBoxName = 'item_representation_box';
  String? id;
  String? color;
  String? shape;
  bool? useImage;
  String? imagePath;
  String? imageName;
  String? downloadUrl;
  DateTime? createdAt;
  DateTime? updatedAt;

  ItemRepresentationModel({
    this.id,
    this.color,
    this.shape,
    this.imagePath,
    this.imageName,
    this.createdAt,
    this.updatedAt,
    this.useImage,
    this.downloadUrl,
  });

  ItemRepresentationModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    color = FormatUtils.parseToString(json['color']);
    useImage = FormatUtils.parseToBool(json['use_image']);
    shape = json['shape'].toString();
    imagePath = FormatUtils.parseToString(json['image_path']);
    imageName = FormatUtils.parseToString(json['image_name']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
    downloadUrl = FormatUtils.parseToString(json['download_url']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['color'] = color;
    data['shape'] = shape;
    data['image_path'] = imagePath;
    data['image_name'] = imageName;
    data['download_url'] = downloadUrl;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    data['use_image'] = FormatUtils.boolToInt(useImage);
    return data;
  }

  // copy with
  ItemRepresentationModel copyWith({
    String? id,
    String? color,
    String? shape,
    String? imagePath,
    String? imageName,
    String? downloadUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? useImage,
  }) {
    return ItemRepresentationModel(
      id: id ?? this.id,
      color: color ?? this.color,
      shape: shape ?? this.shape,
      imagePath: imagePath ?? this.imagePath,
      imageName: imageName ?? this.imageName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      useImage: useImage ?? this.useImage,
      downloadUrl: downloadUrl ?? this.downloadUrl,
    );
  }
}
