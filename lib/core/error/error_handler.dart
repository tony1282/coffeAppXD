import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

import 'exceptions.dart';
import 'failure.dart';
import 'error_messages.dart';

class ErrorHandler {
  static Failure handleError(dynamic error) {
    if (error is SocketException || error is IOException) {
      return NetworkFailure();
    }

    if (error is TimeoutException) {
      return ServerFailure(
        message: ErrorMessages.timeout,
        statusCode: 408,
      );
    }

    if (error is AuthException) {
      return AuthFailure(
        message: error.message,
      );
    }

    if (error is CacheException) {
      return CacheFailure(
        message: error.message,
      );
    }

    if (error is RateLimitException) {
      return RateLimitFailure();
    }

    if (error is ServerException) {
      return ServerFailure(
        message: error.message,
        statusCode: error.statusCode,
      );
    }

    if (error is FirebaseException) {
      return ServerFailure(
        message: error.message ?? ErrorMessages.serverError,
      );
    }

    return UnknownFailure();
  }

  static String getUserFriendlyMessage(Failure failure) {
    return failure.message;
  }
}