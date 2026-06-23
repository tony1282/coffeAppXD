// core/network/api_client.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../config/api_config.dart';
import '../error/exceptions.dart';
import '../error/error_messages.dart';

class ApiClient {
  static final List<DateTime> _requestLog = [];
  static const int _requestTimeoutSeconds = 15;
  static const int _maxRequestsPerMinute = 60;
  
  static http.Client createSecureClient() {
    final ioClient = HttpClient(context: SecurityContext.defaultContext)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return false;
      }
      ..connectionTimeout = const Duration(seconds: _requestTimeoutSeconds);
    return IOClient(ioClient);
  }
  
  static void checkRateLimit() {
    final now = DateTime.now();
    _requestLog.removeWhere((timestamp) => now.difference(timestamp).inSeconds > 60);
    if (_requestLog.length >= _maxRequestsPerMinute) {
      throw RateLimitException(ErrorMessages.rateLimited);
    }
    _requestLog.add(now);
  }
  
  static Map<String, String> getSecurityHeaders() {
    return {
      'X-Content-Type-Options': 'nosniff',
    };
  }
}