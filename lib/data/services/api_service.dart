// data/services/api_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/config/api_config.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/error_messages.dart';
import '../../core/network/api_client.dart';
import '../../core/network/retry_policy.dart';
import '../../core/utils/logger.dart';

class ApiService {
  Future<Map<String, String>> _getHeaders({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw AuthException(ErrorMessages.sessionExpired);
    }

    String? token;
    try {
      token = await user.getIdToken(forceRefresh);
    } catch (e) {
      throw AuthException(ErrorMessages.sessionExpired);
    }

    if (token == null || token.isEmpty) {
      throw AuthException(ErrorMessages.sessionExpired);
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      ...ApiClient.getSecurityHeaders(),
    };
  }

  dynamic _parseBody(String rawBody, String endpoint) {
    if (rawBody.isEmpty) return null;
    if (rawBody.length > 10 * 1024 * 1024) {
      throw ServerException(message: ErrorMessages.serverError);
    }
    try {
      return jsonDecode(rawBody);
    } on FormatException {
      throw ServerException(message: ErrorMessages.invalidResponse);
    }
  }

  String _sanitizeError(dynamic body, int statusCode, String endpoint) {
    switch (statusCode) {
      case 400: return ErrorMessages.badRequest;
      case 401: return ErrorMessages.sessionExpired;
      case 403: return ErrorMessages.forbidden;
      case 404: return ErrorMessages.notFound;
      case 429: return ErrorMessages.tooManyRequests;
      case 500:
      case 502:
      case 503:
      case 504: return ErrorMessages.serverError;
      default: return ErrorMessages.unknown;
    }
  }

  dynamic _handleResponse(http.Response response, String endpoint) {
    final body = _parseBody(response.body, endpoint);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw ServerException(
      message: _sanitizeError(body, response.statusCode, endpoint),
      statusCode: response.statusCode,
    );
  }

  Future<dynamic> _executeWithRetry(
    Future<http.Response> Function(Map<String, String> headers) requestFn,
    String endpoint,
  ) async {
    ApiClient.checkRateLimit();

    http.Response response;
    Map<String, String> headers;

    try {
      headers = await _getHeaders();
      response = await requestFn(headers);
    } on SocketException {
      throw NetworkException(ErrorMessages.noInternet);
    } on TimeoutException {
      throw NetworkException(ErrorMessages.timeout);
    }

    if (RetryPolicy.shouldRetry(response.statusCode, 0)) {
      headers = await _getHeaders(forceRefresh: true);
      response = await requestFn(headers);
      if (response.statusCode == 401) {
        throw AuthException(ErrorMessages.sessionExpired);
      }
    }

    return _handleResponse(response, endpoint);
  }

  Future<dynamic> get(String endpoint) async {
    try {
      return await _executeWithRetry(
        (headers) => ApiClient.createSecureClient()
            .get(
              Uri.parse('${ApiConfig.baseUrl}$endpoint'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15)),
        endpoint,
      );
    } catch (e) {
      AppLogger.error('GET $endpoint', e);
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      return await _executeWithRetry(
        (headers) => ApiClient.createSecureClient()
            .post(
              Uri.parse('${ApiConfig.baseUrl}$endpoint'),
              headers: headers,
              body: jsonEncode(data),
            )
            .timeout(const Duration(seconds: 15)),
        endpoint,
      );
    } catch (e) {
      AppLogger.error('POST $endpoint', e);
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      return await _executeWithRetry(
        (headers) => ApiClient.createSecureClient()
            .put(
              Uri.parse('${ApiConfig.baseUrl}$endpoint'),
              headers: headers,
              body: jsonEncode(data),
            )
            .timeout(const Duration(seconds: 15)),
        endpoint,
      );
    } catch (e) {
      AppLogger.error('PUT $endpoint', e);
      rethrow;
    }
  }

  Future<dynamic> patch(String endpoint, dynamic data) async {
    try {
      return await _executeWithRetry(
        (headers) => ApiClient.createSecureClient()
            .patch(
              Uri.parse('${ApiConfig.baseUrl}$endpoint'),
              headers: headers,
              body: jsonEncode(data),
            )
            .timeout(const Duration(seconds: 15)),
        endpoint,
      );
    } catch (e) {
      AppLogger.error('PATCH $endpoint', e);
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      return await _executeWithRetry(
        (headers) => ApiClient.createSecureClient()
            .delete(
              Uri.parse('${ApiConfig.baseUrl}$endpoint'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15)),
        endpoint,
      );
    } catch (e) {
      AppLogger.error('DELETE $endpoint', e);
      rethrow;
    }
  }

  Future<void> _validateImageFile(File imageFile) async {
    if (!await imageFile.exists()) {
      throw Exception(ErrorMessages.uploadFailed);
    }
    final size = await imageFile.length();
    if (size > 5 * 1024 * 1024) {
      throw Exception(ErrorMessages.imageTooLarge);
    }
    final extension = imageFile.path.split('.').last.toLowerCase();
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    if (!allowedExtensions.contains('.$extension')) {
      throw Exception(ErrorMessages.imageInvalidType);
    }
    final bytes = await imageFile.openRead(0, 12).first;
    if (!_isValidImageMagicBytes(bytes)) {
      throw Exception(ErrorMessages.imageInvalidType);
    }
  }

  bool _isValidImageMagicBytes(List<int> bytes) {
    if (bytes.length < 4) return false;
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return true;
    if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) return true;
    return false;
  }

  Future<String> uploadImage(File imageFile) async {
    await _validateImageFile(imageFile);
    ApiClient.checkRateLimit();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw AuthException(ErrorMessages.sessionExpired);

    final uri = Uri.parse('${ApiConfig.baseUrl}/products/upload-image');

    Future<http.Response> sendRequest(String? token) async {
      final request = http.MultipartRequest('POST', uri);
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
        request.headers['X-Content-Type-Options'] = 'nosniff';
      }
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      try {
        final streamed = await request.send().timeout(const Duration(seconds: 30));
        return await http.Response.fromStream(streamed);
      } on TimeoutException {
        throw NetworkException(ErrorMessages.timeout);
      }
    }

    try {
      String? token = await user.getIdToken();
      var response = await sendRequest(token);
      if (response.statusCode == 401) {
        token = await user.getIdToken(true);
        response = await sendRequest(token);
      }
      final body = _parseBody(response.body, '/products/upload-image');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final imageUrl = body?['imageUrl'] ?? body?['url'] ?? '';
        if (imageUrl.isEmpty) {
          throw Exception(ErrorMessages.uploadFailed);
        }
        return imageUrl;
      }
      throw ServerException(
        message: _sanitizeError(body, response.statusCode, '/products/upload-image'),
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw NetworkException(ErrorMessages.noInternet);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔥 NUEVO: CREATE MERCADO PAGO PREFERENCE (con orderData)
  // ═══════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> createMercadoPagoPreference({
    required Map<String, dynamic> orderData,
    required String idempotencyKey,
  }) async {
    try {
      final headers = await _getHeaders();
      headers['X-Idempotency-Key'] = idempotencyKey;

      final response = await ApiClient.createSecureClient()
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.mpCreatePreference}'),
            headers: headers,
            body: jsonEncode({
              'order_data': orderData,
              'idempotency_key': idempotencyKey,
            }),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response, ApiConfig.mpCreatePreference) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('POST ${ApiConfig.mpCreatePreference}', e);
      rethrow;
    }
  }

  // lib/data/services/api_service.dart

// ═══════════════════════════════════════════════════════════════════
// 🔍 VERIFICAR PAGO DIRECTAMENTE EN MERCADO PAGO
// ═══════════════════════════════════════════════════════════════════
Future<Map<String, dynamic>> verifyPayment(String preferenceId) async {
  try {
    final response = await get('/payments/verify/$preferenceId');
    return response as Map<String, dynamic>;
  } catch (e) {
    AppLogger.error('verifyPayment($preferenceId)', e);
    return {'status': 'error', 'message': e.toString()};
  }
}

}