import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart';

/// Resource class for API requests
class Resource {
  /// URL endpoint
  String? url;

  /// Authentication token
  String? token;

  /// last-sync-at
  String? modelName;

  /// Function to parse HTTP response
  Function(Response response)? parse;

  /// Request data
  final Map<String, dynamic>? data;

  /// Query parameters
  final Map<String, dynamic>? params;

  /// Function to parse Dio response
  Function(dio.Response response)? parseDio;

  /// Constructor
  Resource({
    this.url,
    this.parse,
    this.data,
    this.token,
    this.params,
    this.parseDio,
    this.modelName,
  });
}
