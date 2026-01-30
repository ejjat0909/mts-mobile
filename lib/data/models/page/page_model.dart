import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class PageModel {
  static const String modelName = 'Page';
  static const String modelBoxName = 'page_box';
  String? id;
  String? outletId;
  String? pageName;
  DateTime? createdAt;
  DateTime? updatedAt;

  PageModel({
    this.id,
    this.outletId,
    this.pageName,
    this.createdAt,
    this.updatedAt,
  });

  PageModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    outletId = FormatUtils.parseToString(json['outlet_id']);
    pageName = FormatUtils.parseToString(json['page_name']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['outlet_id'] = outletId;
    data['page_name'] = pageName;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt!);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }
}
