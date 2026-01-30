import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/default_response_model.dart';
import 'package:mts/data/models/license/license_response_model.dart';
import 'package:mts/data/models/user/user_list_response_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/data/models/user/user_response_model.dart';
import 'package:mts/domain/repositories/remote/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  // Validate License API
  @override
  Resource validateLicense(String licenseKey) {
    return Resource(
      url: 'validate-license-key',
      data: {'license_key': licenseKey},
      parse: (response) {
        return LicenseResponseModel(json.decode(response.body));
      },
    );
  }

  // get list user
  @override
  Resource getListUsers() {
    return Resource(
      modelName: UserModel.modelName,
      url: 'users/list',
      parse: (response) {
        return UserListResponseModel(json.decode(response.body));
      },
    );
  }

  // get list user with pagination
  @override
  Resource getListUsersWithPagination(String page) {
    return Resource(
      modelName: UserModel.modelName,
      url: 'users/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return UserListResponseModel(json.decode(response.body));
      },
    );
  }

  // To get the latest user data for current user
  @override
  Resource me() {
    return Resource(
      url: 'me',
      parse: (response) {
        return UserModel.fromJson(json.decode(response.body));
      },
    );
  }

  // Call Logout API to revoke the token
  @override
  Resource logout() {
    return Resource(
      url: 'logout',
      parse: (response) {
        try {
          return DefaultResponseModel(json.decode(response.body));
        } catch (e) {
          return DefaultResponseModel({
            'is_success': false,
            'message': 'Server error. Please try again later',
            'status_code': response.statusCode,
          });
        }
      },
    );
  }

  // Call Login API
  @override
  Resource login(String email, String password, String licenseKey) {
    // use base url
    return Resource(
      url: 'login',
      data: {'email': email, 'password': password, 'license_key': licenseKey},
      parse: (response) {
        return UserResponseModel(json.decode(response.body));
      },
    );
  }

  // Call Login Using API
  @override
  Resource loginUsingPin(String pin) {
    return Resource(
      url: 'login-pin',
      data: {'pin': pin},
      parse: (response) {
        return UserResponseModel(json.decode(response.body));
      },
    );
  }

  // Call verify Email API
  @override
  Resource verifyEmail(String username, String otp) {
    return Resource(
      url: 'email/verify',
      data: {'username': username, 'otp': otp},
      parse: (response) {
        return DefaultResponseModel(json.decode(response.body));
      },
    );
  }

  // Call Resend email verification
  @override
  Resource resendEmail(String username) {
    return Resource(
      url: 'email/resend',
      data: {'username': username},
      parse: (response) {
        return DefaultResponseModel(json.decode(response.body));
      },
    );
  }

  @override
  Resource userDetails(int userId) {
    return Resource(
      url: 'user/$userId',
      parse: (response) {
        return UserResponseModel(json.decode(response.body));
      },
    );
  }
}
