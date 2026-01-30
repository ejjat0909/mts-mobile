class ForgotPasswordFormErrorModel {
  List<String>? password;
  List<String>? otp;

  ForgotPasswordFormErrorModel({this.password, this.otp});

  ForgotPasswordFormErrorModel.fromJson(Map<String, dynamic> json) {
    password = json['password']?.cast<String>();
    otp = json['otp']?.cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['password'] = password;
    data['otp'] = otp;
    return data;
  }
}
