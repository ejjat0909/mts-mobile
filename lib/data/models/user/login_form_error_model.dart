class LoginFormErrorModel {
  List<String>? email;
  List<String>? password;
  List<String>? licenseKey;

  LoginFormErrorModel({this.email, this.password, this.licenseKey});

  LoginFormErrorModel.fromJson(Map<String, dynamic> json) {
    email = json['email']?.cast<String>();
    password = json['password']?.cast<String>();
    licenseKey = json['license_key']?.cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (email != null) data['email'] = email;
    if (password != null) data['password'] = password;
    if (licenseKey != null) data['license_key'] = licenseKey;
    return data;
  }

  /// Get the first error message for email field
  String? get emailError => email?.isNotEmpty == true ? email!.first : null;

  /// Get the first error message for password field
  String? get passwordError => password?.isNotEmpty == true ? password!.first : null;

  /// Get the first error message for license key field
  String? get licenseKeyError => licenseKey?.isNotEmpty == true ? licenseKey!.first : null;

  /// Check if there are any errors
  bool get hasErrors => email != null || password != null || licenseKey != null;
}