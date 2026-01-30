import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class DepartmentPrinterModel {
  static const String modelName = 'DepartmentPrinter';
  static const String modelBoxName = 'department_printer_box';
  String? id;
  String? categories;
  String? name;
  String? companyId;
  DateTime? createdAt;
  DateTime? updatedAt;

  DepartmentPrinterModel({
    this.id,
    this.categories,
    this.name,
    this.companyId,
    this.createdAt,
    this.updatedAt,
  });

  DepartmentPrinterModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    categories = FormatUtils.parseToString(json['categories']);
    companyId = FormatUtils.parseToString(json['company_id']);
    name = FormatUtils.parseToString(json['name']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['categories'] = categories;
    data['company_id'] = companyId;
    data['name'] = name;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }

    return data;
  }
}
