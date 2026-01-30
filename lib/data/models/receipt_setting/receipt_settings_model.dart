import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class ReceiptSettingsModel {
  static const String modelName = 'ReceiptSetting';
  static const String modelBoxName = 'receipt_settings_box';
  static const emailEntity = '${modelName}Email';
  static const printedEntity = '${modelName}Printed';
  String? id;
  String? outletId;
  String? emailedLogo;
  String? emailedLogoName;
  String? printedLogoName;
  String? printedLogo;
  String? header;
  String? footer;
  String? emailLogoUrl;
  String? printLogoUrl;
  String? companyName;
  String? outletName;
  DateTime? createdAt;
  DateTime? updatedAt;

  ReceiptSettingsModel({
    this.id,
    this.outletId,
    this.emailedLogo,
    this.emailedLogoName,
    this.printedLogoName,
    this.printedLogo,
    this.header,
    this.footer,
    this.emailLogoUrl,
    this.printLogoUrl,
    this.companyName,
    this.outletName,
    this.createdAt,
    this.updatedAt,
  });

  ReceiptSettingsModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    outletId = FormatUtils.parseToString(json['outlet_id']);
    emailedLogo = FormatUtils.parseToString(json['emailed_logo']);
    emailedLogoName = FormatUtils.parseToString(json['emailed_logo_name']);
    printedLogoName = FormatUtils.parseToString(json['printed_logo_name']);
    printedLogo = FormatUtils.parseToString(json['printed_logo']);
    emailLogoUrl = FormatUtils.parseToString(json['email_logo_url']);
    printLogoUrl = FormatUtils.parseToString(json['print_logo_url']);
    header = FormatUtils.parseToString(json['header']);
    footer = FormatUtils.parseToString(json['footer']);
    companyName = FormatUtils.parseToString(json['company_name']);
    outletName = FormatUtils.parseToString(json['outlet_name']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['outlet_id'] = outletId;
    data['emailed_logo'] = emailedLogo;
    data['emailed_logo_name'] = emailedLogoName;
    data['printed_logo_name'] = printedLogoName;
    data['printed_logo'] = printedLogo;
    data['email_logo_url'] = emailLogoUrl;
    data['print_logo_url'] = printLogoUrl;
    data['company_name'] = companyName;
    data['outlet_name'] = outletName;
    data['header'] = header;
    data['footer'] = footer;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  // copy with
  ReceiptSettingsModel copyWith({
    String? id,
    String? outletId,
    String? emailedLogo,
    String? emailedLogoName,
    String? printedLogoName,
    String? printedLogo,
    String? header,
    String? footer,
    String? emailLogoUrl,
    String? printLogoUrl,
    String? companyName,
    String? outletName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReceiptSettingsModel(
      id: id ?? this.id,
      outletId: outletId ?? this.outletId,
      emailedLogo: emailedLogo ?? this.emailedLogo,
      emailedLogoName: emailedLogoName ?? this.emailedLogoName,
      printedLogoName: printedLogoName ?? this.printedLogoName,
      printedLogo: printedLogo ?? this.printedLogo,
      header: header ?? this.header,
      footer: footer ?? this.footer,
      emailLogoUrl: emailLogoUrl ?? this.emailLogoUrl,
      printLogoUrl: printLogoUrl ?? this.printLogoUrl,
      companyName: companyName ?? this.companyName,
      outletName: outletName ?? this.outletName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
