import 'package:mts/core/utils/format_utils.dart';

class ForgotPasswordRequestModel {
  String? password;
  String? passwordConfirmation;
  String? email;
  String? otp;

  ForgotPasswordRequestModel({
    this.password,
    this.passwordConfirmation,
    this.email,
    this.otp,
  });

  ForgotPasswordRequestModel.fromJson(Map<String, dynamic> json) {
    password = FormatUtils.parseToString(json['password']);
    passwordConfirmation = FormatUtils.parseToString(json['password_confirmation']);
    email = FormatUtils.parseToString(json['email']);
    otp = FormatUtils.parseToString(json['otp']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['password'] = password;
    data['password_confirmation'] = passwordConfirmation;
    data['email'] = email;
    data['otp'] = otp;
    return data;
  }
}
