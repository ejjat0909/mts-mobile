import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/validation_utils.dart';
import 'package:mts/data/models/user/user_response_model.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/providers/user/user_providers.dart';

class LoginFormBloc extends FormBloc<String, String> {
  final UserNotifier _userNotifier;
  final email = TextFieldBloc(
    initialValue: kDebugMode ? 'izzat@email.com' : '',
    // initialValue: kDebugMode ? 'smkalshafa@gmail.com' : '',
    validators: [
      ValidationUtils.validateRequired,
      ValidationUtils.validateEmail,
    ],
  );
  final password = TextFieldBloc(
    // initialValue: kDebugMode ? 'AShafa1001' : '',
    initialValue: kDebugMode ? 'password' : '',
    validators: [ValidationUtils.validateRequired],
  );

  LoginFormBloc(this._userNotifier) {
    addFieldBlocs(fieldBlocs: [email, password]);
  }

  @override
  Future<void> onSubmitting() async {
    try {
      // Call API to Login
      UserResponseModel userResponseModel = await _userNotifier.login(
        email.value.trim(),
        password.value,
      );

      if (userResponseModel.isSuccess &&
          userResponseModel.data!.accessToken != null) {
        emitSuccess(canSubmitAgain: true);
      } else {
        // Check if there are specific field errors
        if (userResponseModel.errors != null) {
          // Add specific field errors
          if (userResponseModel.errors!.emailError != null) {
            email.addFieldError(userResponseModel.errors!.emailError!);
          }
          if (userResponseModel.errors!.passwordError != null) {
            password.addFieldError(userResponseModel.errors!.passwordError!);
          }
          if (userResponseModel.errors!.licenseKeyError != null) {
            // If there's a license key error but no specific field, add to email field
            email.addFieldError(userResponseModel.errors!.licenseKeyError!);
          }

          // If no specific field errors were found, add general message to email
          if (!userResponseModel.errors!.hasErrors) {
            email.addFieldError(userResponseModel.message);
          }
        } else {
          // Fallback to general error message
          email.addFieldError(userResponseModel.message);
        }

        prints(jsonEncode(userResponseModel));
        emitFailure();
      }
    } catch (e) {
      emitFailure(failureResponse: e.toString());
    }
  }
}
