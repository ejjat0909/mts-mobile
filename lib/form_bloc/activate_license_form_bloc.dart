import 'package:flutter/foundation.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/network/http_response.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/validation_utils.dart';
import 'package:mts/data/models/license/license_form_error_model.dart';
import 'package:mts/data/models/license/license_response_model.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/providers/user/user_providers.dart';

class ActivateLicenseFormBloc extends FormBloc<String, String> {
  static final SecureStorageApi _secureStorageApi =
      ServiceLocator.get<SecureStorageApi>();
  final UserNotifier _userNotifier;

  final license = TextFieldBloc(
    initialValue: kDebugMode ? '12345-12345-12345-12345' : "",
    // initialValue: kDebugMode ? '22222-22222-22222-22222' : "",
    validators: [ValidationUtils.validateRequired],
  );

  ActivateLicenseFormBloc(this._userNotifier) {
    addFieldBlocs(fieldBlocs: [license]);
  }

  @override
  Future<void> onSubmitting() async {
    try {
      // // Declare BLOC
      // UserBloc loginBloc = UserBloc();
      // Call API
      prints('validating license key ${license.value} ...');
      LicenseResponseModel responseModel = await _userNotifier.validateLicense(
        license.value,
      );

      if (responseModel.isSuccess) {
        // assign license key
        await _secureStorageApi.write(
          'license_key',
          responseModel.data!.licenseKey!,
        );
        // assign locale
        await _secureStorageApi.write('locale', responseModel.data!.locale!);
        emitSuccess(successResponse: 'Success Activate License');
      } else {
        prints(responseModel.toJson());
        prints('status code ${responseModel.statusCode}');
        if (responseModel.statusCode ==
            HttpResponse.HTTP_UNPROCESSABLE_ENTITY) {
          /// code [422]
          if (responseModel.errors != null) {
            LicenseFormErrorModel errorModel = responseModel.errors!;

            if (errorModel.licenseKey != null) {
              license.addFieldError(errorModel.licenseKey![0]);
              emitFailure(failureResponse: errorModel.licenseKey![0]);
              prints(errorModel.licenseKey![0]);
            } else {
              emitFailure(failureResponse: responseModel.message);
              prints(responseModel.message);
            }
          } else {
            String errorMessage = 'Invalid License Key. Please try again.';
            license.addFieldError(errorMessage);
            emitFailure(failureResponse: errorMessage);
          }
        } else {
          prints('case 3');
          emitFailure(failureResponse: responseModel.message);
        }

        // if (responseModel.statusCode ==
        //     HttpResponse.HTTP_INTERNAL_SERVER_ERROR) {
        //   /// code [500]
        //   ///
        //   String errorMessage = "Invalid License Key. Please try again.";
        //   license.addFieldError(errorMessage);
        //   emitFailure(failureResponse: errorMessage);
        // } else {
        //   emitFailure(failureResponse: responseModel.message);
        // }
      }

      // // Handle API response
      // if (response.statusCode == HttpResponse.HTTP_OK) {
      //   //save in secured storage
      //   await _secureStorageApi.write(
      //       key: "tenant_token", value: response.data!.tenantToken!);

      //   await _secureStorageApi.write(
      //       key: "tenant_url",
      //       value: "https://${response.data!.domain}.mysztech-pos.com/api/v1/");

      //   await _secureStorageApi.write(
      //       key: "locale", value: response.data!.locale!);

      //   await _secureStorageApi.write(
      //       key: "company_name", value: response.data!.companyName!);

      //   // await _secureStorageApi.write(
      //   // key: "company_id", value: response.data!.companyId!.toString());

      //   emitSuccess();
      // } else {
      //   // Put error to the field
      //   LicenseFormErrorModel errorModel = response.errors!;

      //   if (errorModel.licenseKey != null) {
      //     license.addFieldError(errorModel.licenseKey![0]);
      //     emitFailure();
      //   } else {
      //     emitFailure(failureResponse: response.message);
      //   }
      // }
    } catch (exception) {
      prints('catch error ${exception.toString()}');
      emitFailure(failureResponse: 'Server error');
    }
  }
}
