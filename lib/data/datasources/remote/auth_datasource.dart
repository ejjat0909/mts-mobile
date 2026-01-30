import 'dart:convert';

import 'package:mts/core/network/api_client.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/default_response_model.dart';
import 'package:mts/data/models/user/user_response_model.dart';

/// Authentication datasource
class AuthDatasource {
  final ApiClient _apiClient;
  final SecureStorageApi _secureStorage;

  /// Constructor
  AuthDatasource({
    required ApiClient apiClient,
    required SecureStorageApi secureStorage,
  }) : _apiClient = apiClient,
       _secureStorage = secureStorage;

  /// Login with email and password
  Resource login(String email, String password) {
    try {
      return Resource(
        url: 'login',
        data: {'email': email, 'password': password},
        parse: (response) {
          return UserResponseModel(json.decode(response.body));
        },
      );
    } catch (e) {
      throw Exception('Failed to login: ${e.toString()}');
    }
  }

  /// Logout
  Future<Resource> logout() async {
    try {
      return Resource(
        url: 'logout',
        parse: (response) {
          return DefaultResponseModel(json.decode(response.body));
        },
      );
    } catch (e) {
      // Delete token from secure storage even if API call fails
      final success = await _secureStorage.deleteToken();
      if (!success) {
        throw Exception('Failed to delete token');
      }
      throw Exception('Failed to logout: ${e.toString()}');
    }
  }

  /// Check if user is logged in
  // Future<bool> isLoggedIn() async {
  //   try {
  //     // First check if token exists
  //     final token = await _secureStorage.getToken();
  //     if (token == null) {
  //       return false;
  //     }

  //     // Then verify token with API
  //     final response = await _apiClient.get('/auth/check');

  //     if (response.statusCode == 200) {
  //       return true;
  //     }

  //     // If API check fails, delete token
  //     final success = await _secureStorage.deleteToken();
  //     if (!success) {
  //       throw Exception('Failed to delete token');
  //     }
  //     return false;
  //   } catch (e) {
  //     // If API check throws error, delete token
  //     final success = await _secureStorage.deleteToken();
  //     if (!success) {
  //       // Just log the error, don't throw
  //       prints('Failed to delete token');
  //     }
  //     return false;
  //   }
  // }

  /// Get user data
  Future<Map<String, dynamic>> getUserData() async {
    try {
      final response = await _apiClient.get('/auth/user');

      if (response.statusCode == 200) {
        return response.data;
      }

      throw Exception('Failed to get user data');
    } catch (e) {
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }
}
