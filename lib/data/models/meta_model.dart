import 'package:mts/core/utils/date_time_utils.dart';

class MetaModel {
  DateTime? lastSync;

  MetaModel({this.lastSync});

  MetaModel.fromJson(Map<String, dynamic> json) {
    lastSync =
        json['last_sync'] != null ? DateTime.parse(json['last_sync']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    if (lastSync != null) {
      data['last_sync'] = DateTimeUtils.getDateTimeFormat(lastSync);
    }

    return data;
  }
}
