/// Server exception
class ServerException implements Exception {
  /// Message
  final String message;

  /// Status code
  final int statusCode;

  /// Constructor
  ServerException({required this.message, required this.statusCode});
}

/// Cache exception
class CacheException implements Exception {
  /// Message
  final String message;

  /// Constructor
  CacheException({required this.message});
}

/// Network exception
class NetworkException implements Exception {
  /// Message
  final String message;

  /// Constructor
  NetworkException({required this.message});
}

/// Authentication exception
class AuthenticationException implements Exception {
  /// Message
  final String message;

  /// Constructor
  AuthenticationException({required this.message});
}

/// Validation exception
class ValidationException implements Exception {
  /// Errors
  final Map<String, dynamic> errors;

  /// Message
  final String message;

  /// Constructor
  ValidationException({required this.errors, required this.message});
}
