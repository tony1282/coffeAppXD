// data/services/product_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/config/api_config.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/error_messages.dart';
import '../../core/utils/logger.dart';
import '../models/product_model.dart';

class ProductService {
  // ============================================================
  // HEADERS Y AUTENTICACIÓN
  // ============================================================
  Future<Map<String, String>> _getSecureHeaders() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw AuthException(ErrorMessages.sessionExpired);
    }

    if (user.uid.isEmpty) {
      throw AuthException(ErrorMessages.sessionExpired);
    }

    String? token;
    try {
      token = await user.getIdToken(false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-token-expired' || e.code == 'id-token-expired') {
        try {
          token = await user.getIdToken(true);
        } catch (_) {
          throw AuthException(ErrorMessages.sessionExpired);
        }
      } else {
        throw AuthException(ErrorMessages.sessionExpired);
      }
    } catch (_) {
      throw AuthException(ErrorMessages.sessionExpired);
    }

    if (token == null || token.isEmpty) {
      throw AuthException(ErrorMessages.sessionExpired);
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // REQUEST SEGURO CON RETRY
  // ============================================================
  Future<http.Response> _safeRequest(
    Future<http.Response> Function() requestFn,
    String endpoint,
  ) async {
    const maxRetries = 1;
    const timeoutSeconds = 15;

    try {
      final response = await requestFn().timeout(
        const Duration(seconds: timeoutSeconds),
        onTimeout: () => throw NetworkException(ErrorMessages.timeout),
      );

      final contentLength = response.contentLength;
      if (contentLength != null && contentLength > 5 * 1024 * 1024) {
        throw ServerException(message: ErrorMessages.serverError);
      }

      return response;
    } on SocketException {
      throw NetworkException(ErrorMessages.noInternet);
    } on TimeoutException {
      throw NetworkException(ErrorMessages.timeout);
    } on http.ClientException catch (e) {
      throw NetworkException(e.message ?? ErrorMessages.noInternet);
    } on FirebaseAuthException catch (e) {
      if ((e.code == 'user-token-expired' || e.code == 'id-token-expired') && maxRetries > 0) {
        final headers = await _getSecureHeaders();
        final response = await requestFn().timeout(
          const Duration(seconds: timeoutSeconds),
          onTimeout: () => throw NetworkException(ErrorMessages.timeout),
        );
        return response;
      }
      throw AuthException(ErrorMessages.sessionExpired);
    }
  }

  // ============================================================
  // VALIDACIÓN DE RESPUESTA
  // ============================================================
  dynamic _validateResponse(http.Response response, String endpoint) {
    if (response.statusCode == 401) {
      throw AuthException(ErrorMessages.sessionExpired);
    }
    if (response.statusCode == 403) {
      throw ServerException(message: ErrorMessages.forbidden, statusCode: 403);
    }
    if (response.statusCode == 404) {
      throw ServerException(message: ErrorMessages.notFound, statusCode: 404);
    }

    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }
      throw ServerException(message: ErrorMessages.serverError, statusCode: response.statusCode);
    }

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      throw ServerException(message: ErrorMessages.invalidResponse);
    }

    if (response.statusCode >= 500) {
      throw ServerException(message: ErrorMessages.serverError, statusCode: response.statusCode);
    }
    if (response.statusCode >= 400) {
      throw ServerException(message: ErrorMessages.unknown, statusCode: response.statusCode);
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ServerException(message: ErrorMessages.unknown, statusCode: response.statusCode);
  }

  // ============================================================
  // VALIDACIÓN DE ID
  // ============================================================
  int _validateProductId(int id) {
    if (id <= 0) {
      throw ServerException(message: ErrorMessages.notFound);
    }
    return id;
  }

  // ============================================================
  // SANITIZACIÓN DE PAYLOAD (mass assignment prevention)
  // ============================================================
  Map<String, dynamic> _sanitizeProductData(Map<String, dynamic> data) {
    if (data == null) {
      throw ServerException(message: ErrorMessages.badRequest);
    }

    const allowedFields = {
      'name', 'description', 'price', 'category',
      'image_url', 'available', 'stock'
    };
    const maxNameLength = 100;
    const maxDescriptionLength = 1000;

    final sanitized = <String, dynamic>{};

    for (final entry in data.entries) {
      if (!allowedFields.contains(entry.key)) {
        continue;
      }

      switch (entry.key) {
        case 'name':
          if (entry.value is! String || entry.value.trim().isEmpty) {
            throw ServerException(message: ErrorMessages.badRequest);
          }
          if (entry.value.length > maxNameLength) {
            throw ServerException(message: ErrorMessages.badRequest);
          }
          sanitized[entry.key] = entry.value.trim();
          break;

        case 'description':
          if (entry.value != null) {
            final desc = entry.value.toString();
            if (desc.length > maxDescriptionLength) {
              throw ServerException(message: ErrorMessages.badRequest);
            }
            sanitized[entry.key] = desc.trim();
          }
          break;

        case 'price':
          if (entry.value is! num) {
            throw ServerException(message: ErrorMessages.badRequest);
          }
          final price = (entry.value as num).toDouble();
          if (price <= 0 || price >= 10000) {
            throw ServerException(message: ErrorMessages.badRequest);
          }
          sanitized[entry.key] = price;
          break;

        case 'stock':
          if (entry.value != null) {
            if (entry.value is! int || entry.value < 0) {
              throw ServerException(message: ErrorMessages.badRequest);
            }
            sanitized[entry.key] = entry.value;
          }
          break;

        case 'available':
          if (entry.value is! bool) {
            throw ServerException(message: ErrorMessages.badRequest);
          }
          sanitized[entry.key] = entry.value;
          break;

        case 'image_url':
          if (entry.value != null && entry.value is! String) {
            throw ServerException(message: ErrorMessages.badRequest);
          }
          sanitized[entry.key] = entry.value?.toString() ?? '';
          break;

        default:
          sanitized[entry.key] = entry.value;
      }
    }

    return sanitized;
  }

  // ============================================================
  // PARSE SEGURO DE PRODUCTO
  // ============================================================
  ProductModel _parseProductSafely(dynamic body) {
    if (body == null || body is! Map<String, dynamic>) {
      throw ServerException(message: ErrorMessages.invalidResponse);
    }

    try {
      return ProductModel.fromJson(body);
    } catch (e) {
      throw ServerException(message: ErrorMessages.invalidResponse);
    }
  }

  // ============================================================
  // GET /products
  // ============================================================
  Future<List<ProductModel>> getProducts() async {
    try {
      final headers = await _getSecureHeaders();
      final response = await _safeRequest(
        () => http.get(
          Uri.parse('${ApiConfig.baseUrl}/products/'),
          headers: headers,
        ),
        'GET /products',
      );

      final body = _validateResponse(response, 'GET /products/');

      if (body == null) return [];

      if (body is! List) {
        throw ServerException(message: ErrorMessages.invalidResponse);
      }

      final List<ProductModel> products = [];
      for (final item in body) {
        if (item is Map<String, dynamic>) {
          try {
            products.add(ProductModel.fromJson(item));
          } catch (e) {
            AppLogger.error('getProducts: failed to parse product', e);
            continue;
          }
        }
      }
      return products;
    } catch (e) {
      AppLogger.error('getProducts', e);
      rethrow;
    }
  }

  // ============================================================
  // GET /products/:id
  // ============================================================
  Future<ProductModel> getProductById(int id) async {
    final validId = _validateProductId(id);

    try {
      final headers = await _getSecureHeaders();
      final response = await _safeRequest(
        () => http.get(
          Uri.parse('${ApiConfig.baseUrl}/products/$validId'),
          headers: headers,
        ),
        'GET /products/$validId',
      );

      final body = _validateResponse(response, 'GET /products/$validId');
      return _parseProductSafely(body);
    } catch (e) {
      AppLogger.error('getProductById($id)', e);
      rethrow;
    }
  }

  // ============================================================
  // POST /products
  // ============================================================
  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    final sanitizedData = _sanitizeProductData(data);

    try {
      final headers = await _getSecureHeaders();
      final response = await _safeRequest(
        () => http.post(
          Uri.parse('${ApiConfig.baseUrl}/products/'),
          headers: headers,
          body: jsonEncode(sanitizedData),
        ),
        'POST /products',
      );

      final body = _validateResponse(response, 'POST /products/');
      return _parseProductSafely(body);
    } catch (e) {
      AppLogger.error('createProduct', e);
      rethrow;
    }
  }

  // ============================================================
  // PUT /products/:id
  // ============================================================
  Future<ProductModel> updateProduct(int id, Map<String, dynamic> data) async {
    final validId = _validateProductId(id);
    final sanitizedData = _sanitizeProductData(data);

    try {
      final headers = await _getSecureHeaders();
      final response = await _safeRequest(
        () => http.put(
          Uri.parse('${ApiConfig.baseUrl}/products/$validId'),
          headers: headers,
          body: jsonEncode(sanitizedData),
        ),
        'PUT /products/$validId',
      );

      final body = _validateResponse(response, 'PUT /products/$validId');
      return _parseProductSafely(body);
    } catch (e) {
      AppLogger.error('updateProduct($id)', e);
      rethrow;
    }
  }

  // ============================================================
  // DELETE /products/:id
  // ============================================================
  Future<void> deleteProduct(int id) async {
    final validId = _validateProductId(id);

    try {
      final headers = await _getSecureHeaders();
      final response = await _safeRequest(
        () => http.delete(
          Uri.parse('${ApiConfig.baseUrl}/products/$validId'),
          headers: headers,
        ),
        'DELETE /products/$validId',
      );

      if (response.statusCode == 404) {
        return;
      }

      _validateResponse(response, 'DELETE /products/$validId');
    } catch (e) {
      AppLogger.error('deleteProduct($id)', e);
      rethrow;
    }
  }

  // ============================================================
  // PATCH /products/:id/availability
  // ============================================================
  Future<ProductModel> toggleAvailability(int id, bool available) async {
    final validId = _validateProductId(id);

    try {
      final headers = await _getSecureHeaders();
      final response = await _safeRequest(
        () => http.patch(
          Uri.parse('${ApiConfig.baseUrl}/products/$validId/availability'),
          headers: headers,
          body: jsonEncode({'available': available}),
        ),
        'PATCH /products/$validId/availability',
      );

      final body = _validateResponse(response, 'PATCH /products/$validId/availability');
      return _parseProductSafely(body);
    } catch (e) {
      AppLogger.error('toggleAvailability($id, $available)', e);
      rethrow;
    }
  }
}