import 'package:mts/core/utils/format_utils.dart';

class PrinterInterfaceModel {
  String? id;
  String? name;

  PrinterInterfaceModel({this.id, this.name});

  PrinterInterfaceModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    name = FormatUtils.parseToString(json['name']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;

    return data;
  }
}
