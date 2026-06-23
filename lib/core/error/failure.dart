import 'package:equatable/equatable.dart';
import 'error_messages.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.statusCode,
  });
}

class NetworkFailure extends Failure {
  const NetworkFailure()
      : super(message: ErrorMessages.noInternet);
}

class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
  });
}

class RateLimitFailure extends Failure {
  const RateLimitFailure()
      : super(message: ErrorMessages.rateLimited);
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
  });
}

class UnknownFailure extends Failure {
  const UnknownFailure()
      : super(message: ErrorMessages.unknown);
}