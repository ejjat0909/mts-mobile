class LicenseFormErrorModel {
  List<String>? licenseKey;

  LicenseFormErrorModel({this.licenseKey});

  LicenseFormErrorModel.fromJson(Map<String, dynamic> json) {
    licenseKey = json['license_key'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['license_key'] = licenseKey;
    return data;
  }
}
