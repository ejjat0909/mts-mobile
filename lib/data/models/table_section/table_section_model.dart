import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class TableSectionModel {
  static const String modelName = "TableSection";
  static const String modelBoxName = 'table_section_box';
  String? id;
  String? name;
  String? outletId;
  DateTime? createdAt;
  DateTime? updatedAt;

  TableSectionModel({
    this.id,
    this.name,
    this.outletId,
    this.createdAt,
    this.updatedAt,
  });

  //needed for deep copy
  TableSectionModel copyWith({
    String? id,
    String? name,
    String? outletId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TableSectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      outletId: outletId ?? this.outletId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  TableSectionModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    name = FormatUtils.parseToString(json['name']);
    outletId = FormatUtils.parseToString(json['outlet_id']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['id'] = id;
    data['outlet_id'] = outletId;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }
}
