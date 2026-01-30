import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';

/// Interface for the web service client
abstract class IWebService {
  /// Get authentication headers for pusher
  Future<Map<String, String>> getPusherHeaders();

  /// Perform a POST request
  Future<dynamic> post(
    Resource resource, {
    bool hasImage,
    List<String>? imageKeys,
    String url,
  });

  /// Perform a GET request
  Future<dynamic> get(Resource resource);

  /// Perform a PUT request
  Future<dynamic> put(Resource resource);

  /// Perform a DELETE request
  Future<dynamic> delete(Resource resource);
}

/// Implementation of the web service client
class WebService implements IWebService {
  final SecureStorageApi _secureStorage;
  final String _baseUrl;
  final String _apiKey;

  /// Constructor with dependency injection
  WebService({
    required SecureStorageApi secureStorage,
    required String baseUrl,
    required String apiKey,
  }) : _secureStorage = secureStorage,
       _baseUrl = baseUrl,
       _apiKey = apiKey;

  /// Get authentication headers for requests
  Future<Map<String, String>> _getAuthHeaders({
    bool includeContentType = true,
    Resource? resource,
  }) async {
    String userToken = await _secureStorage.read(key: 'access_token');
    String staffToken = await _secureStorage.read(key: 'staff_access_token');
    // staff token is the priority, so we check the staff token first
    final token =
        staffToken.isNotEmpty
            ? staffToken
            : (userToken.isNotEmpty ? userToken : '');
    // Get current device model from ServiceLocator (registered at startup/selection)
    final PosDeviceModel deviceModel = ServiceLocator.get<PosDeviceModel>();

    final headers = {
      // api key
      'X-Authorization': _apiKey,
      // To only accept json response from server
      'Accept': 'application/json',
      // User Authorization
      'Authorization': 'Bearer $token',
      // device info
      'pos-device-id': deviceModel.id ?? '',
    };

    if (includeContentType) {
      // To help laravel api recognize the body type of the request
      headers['content-type'] = 'application/json';
    }

    if (resource != null && resource.modelName != null) {
      headers['last-sync-at'] = DateTimeUtils.formatToISO8601(
        await SyncService.getLastSyncTime(resource.modelName!),
      );
    }

    return headers;
  }

  @override
  Future<Map<String, String>> getPusherHeaders() async {
    return await _getAuthHeaders();
  }

  @override
  Future<dynamic> post(
    Resource resource, {
    bool hasImage = false,
    List<String>? imageKeys,
    String url = versionApiUrl,
  }) async {
    if (!hasImage) {
      // Create Uri from the url define in resource file. Then add the query parameters
      Uri uri = Uri.parse(
        url + resource.url!,
      ).replace(queryParameters: resource.params);

      http.Response response = await http.post(
        uri,
        body: jsonEncode(resource.data),
        headers: await _getAuthHeaders(),
      );

      // 🔍 DIAGNOSTIC: Log sync check response details
      if (resource.url?.contains('sync/check') ?? false) {
        // prints('📡 sync/check response status: ${response.statusCode}');
        // prints('📡 sync/check response headers: ${response.headers}');
        // if (response.statusCode != 200) {
        //   prints('⚠️ sync/check returned non-200 status');
        // }
      }

      return resource.parse!(response);
    } else {
      var headers = await _getAuthHeaders(includeContentType: false);

      Dio dio = Dio(BaseOptions(baseUrl: url, headers: headers));

      // Process image files
      for (String imageKey in imageKeys!) {
        // Handle nested image paths
        if (imageKey.contains('.')) {
          String parent = imageKey.split('.')[0];
          String child = imageKey.split('.')[1];
          resource.data![parent][child] = await MultipartFile.fromFile(
            resource.data![parent][child],
          );
        } else {
          resource.data![imageKey] = await MultipartFile.fromFile(
            resource.data![imageKey],
          );
        }
      }

      FormData data = FormData.fromMap(resource.data!);

      Response response = await dio.post(resource.url!, data: data);

      return resource.parseDio!(response);
    }
  }

  @override
  Future<dynamic> get(Resource resource) async {
    // Create Uri from the url define in resource file. Then add the query parameters
    Uri uri = Uri.parse(
      _baseUrl + resource.url!,
    ).replace(queryParameters: resource.params);

    http.Response response = await http.get(
      uri,
      headers: await _getAuthHeaders(
        includeContentType: false,
        resource: resource,
      ),
    );

    return resource.parse!(response);
  }

  @override
  Future<dynamic> put(Resource resource) async {
    // Create Uri from the url define in resource file. Then add the query parameters
    Uri uri = Uri.parse(
      _baseUrl + resource.url!,
    ).replace(queryParameters: resource.params);

    http.Response response = await http.put(
      uri,
      body: jsonEncode(resource.data),
      headers: await _getAuthHeaders(),
    );

    return resource.parse!(response);
  }

  @override
  Future<dynamic> delete(Resource resource) async {
    Uri uri = Uri.parse(
      _baseUrl + resource.url!,
    ).replace(queryParameters: resource.params);

    http.Response response = await http.delete(
      uri,
      headers: await _getAuthHeaders(includeContentType: false),
    );

    return resource.parse!(response);
  }
}
