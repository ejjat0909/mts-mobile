import 'package:mts/core/storage/secure_storage_api.dart';

/// API datasource for making HTTP requests
class ApiDatasource {
  /// Constructor with dependency injection
  ApiDatasource({required SecureStorageApi secureStorage});

  /// Get headers for Pusher
  // Future<Map<String, String>> getPusherHeaders() async {
  //   String? token = await _secureStorage.getToken();

  //   return {
  //     // API key
  //     'X-Authorization': apiKey,
  //     // To only accept JSON response from server
  //     'Accept': 'application/json',
  //     // User Authorization
  //     'Authorization': 'Bearer $token',
  //     // To help Laravel API recognize the body type of the request
  //     'content-type': 'application/json',
  //   };
  // }

  /// API request using POST method
  // Future post(
  //   Resource resource, {
  //   bool hasImage = false,
  //   List<String>? imageKeys,
  //   String url = versionApiUrl,
  // }) async {
  //   // To authenticate user
  //   String? token = await _secureStorage.getToken();

  //   if (!hasImage) {
  //     // Create Uri from the url define in resource file. Then add the query parameters
  //     Uri uri = Uri.parse(
  //       url + resource.url!,
  //     ).replace(queryParameters: resource.params);

  //     http.Response response = await http.post(
  //       uri,
  //       body: jsonEncode(resource.data),
  //       headers: {
  //         // API key
  //         'X-Authorization': apiKey,
  //         // To only accept JSON response from server
  //         'Accept': 'application/json',
  //         // User Authorization
  //         'Authorization': 'Bearer $token',
  //         // To help Laravel API recognize the body type of the request
  //         'content-type': 'application/json',
  //       },
  //     );

  //     return resource.parse!(response);
  //   } else {
  //     var headers = {
  //       // API key
  //       'X-Authorization': apiKey,
  //       // To only accept JSON response from server
  //       'Accept': 'application/json',
  //       // User Authorization
  //       'Authorization': 'Bearer $token',
  //     };

  //     Dio dio = Dio(BaseOptions(baseUrl: versionApiUrl, headers: headers));
  //     // imageKey is JSON path of file path
  //     // eg. : imageKeys = ['photo_path','parent.photo_path']
  //     for (String imageKey in imageKeys!) {
  //       // Can be improved to fully support deep nested model
  //       if (imageKey.contains('.')) {
  //         String parent = imageKey.split('.')[0];
  //         String child = imageKey.split('.')[1];
  //         resource.data![parent][child] = await MultipartFile.fromFile(
  //           resource.data![parent][child],
  //         );
  //       } else {
  //         resource.data![imageKey] = await MultipartFile.fromFile(
  //           resource.data![imageKey],
  //         );
  //       }
  //     }
  //     FormData data = FormData.fromMap(resource.data!);

  //     Response response = await dio.post(resource.url!, data: data);

  //     return resource.parseDio!(response);
  //   }
  // }

  /// API request using GET method
  // Future get(Resource resource) async {
  //   // To authenticate user
  //   String? token = await _secureStorage.getToken();

  //   // Create Uri from the url define in resource file. Then add the query parameters
  //   Uri uri = Uri.parse(
  //     versionApiUrl + resource.url!,
  //   ).replace(queryParameters: resource.params);

  //   http.Response response = await http.get(
  //     uri,
  //     headers: {
  //       // API key
  //       'X-Authorization': apiKey,
  //       // To only accept JSON response from server
  //       'Accept': 'application/json',
  //       // User Authorization
  //       'Authorization': 'Bearer $token',
  //     },
  //   );
  //   return resource.parse!(response);
  // }

  /// API request using PUT method
  // Future put(Resource resource) async {
  //   // To authenticate user
  //   String? token = await _secureStorage.getToken();

  //   // Create Uri from the url define in resource file. Then add the query parameters
  //   Uri uri = Uri.parse(
  //     versionApiUrl + resource.url!,
  //   ).replace(queryParameters: resource.params);

  //   http.Response response = await http.put(
  //     uri,
  //     body: jsonEncode(resource.data),
  //     headers: {
  //       // API key
  //       'X-Authorization': apiKey,
  //       // To only accept JSON response from server
  //       'Accept': 'application/json',
  //       // User Authorization
  //       'Authorization': 'Bearer $token',
  //       // To help Laravel API recognize the body type of the request
  //       'content-type': 'application/json',
  //     },
  //   );

  //   return resource.parse!(response);
  // }

  /// API request using DELETE method
  //   Future delete(Resource resource) async {
  //     // To authenticate user
  //     String? token = await _secureStorage.getToken();

  //     Uri uri = Uri.parse(
  //       versionApiUrl + resource.url!,
  //     ).replace(queryParameters: resource.params);

  //     http.Response response = await http.delete(
  //       uri,
  //       headers: {
  //         // API key
  //         'X-Authorization': apiKey,
  //         // To only accept JSON response from server
  //         'Accept': 'application/json',
  //         // User Authorization
  //         'Authorization': 'Bearer $token',
  //       },
  //     );

  //     return resource.parse!(response);
  //   }
}
