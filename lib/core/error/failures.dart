import 'package:equatable/equatable.dart';

/// Base failure
abstract class Failure extends Equatable {
  /// Message
  final String message;

  /// Constructor
  const Failure({required this.message});

  @override
  List<Object> get props => [message];
}

/// Server failure
class ServerFailure extends Failure {
  /// Status code
  final int statusCode;

  /// Constructor
  const ServerFailure({required super.message, required this.statusCode});

  @override
  List<Object> get props => [message, statusCode];
}

/// Cache failure
class CacheFailure extends Failure {
  /// Constructor
  const CacheFailure({required super.message});
}

/// Network failure
class NetworkFailure extends Failure {
  /// Constructor
  const NetworkFailure({required super.message});
}

/// Authentication failure
class AuthenticationFailure extends Failure {
  /// Constructor
  const AuthenticationFailure({required super.message});
}

/// Validation failure
class ValidationFailure extends Failure {
  /// Errors
  final Map<String, dynamic> errors;

  /// Constructor
  const ValidationFailure({required super.message, required this.errors});

  @override
  List<Object> get props => [message, errors];
}
