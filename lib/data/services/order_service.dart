import 'dart:io';
import 'dart:async';
import 'dart:convert';
import '../models/order_model.dart';
import '../../core/utils/logger.dart';
import 'package:http/http.dart' as http;
import '../../core/error/exceptions.dart';
import '../../core/config/api_config.dart';
import '../../core/error/error_messages.dart';
import 'package:firebase_auth/firebase_auth.dart';
// lib/data/services/order_service.dart

class OrderService {
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
      if ((e.code == 'user-token-expired' || e.code == 'id-token-expired') &&
          maxRetries > 0) {
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
      throw ServerException(
          message: ErrorMessages.serverError, statusCode: response.statusCode);
    }

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      throw ServerException(message: ErrorMessages.invalidResponse);
    }

    if (response.statusCode >= 500) {
      throw ServerException(
          message: ErrorMessages.serverError, statusCode: response.statusCode);
    }
    if (response.statusCode >= 400) {
      throw ServerException(
          message: ErrorMessages.unknown, statusCode: response.statusCode);
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ServerException(
        message: ErrorMessages.unknown, statusCode: response.statusCode);
  }

  int _validateOrderId(int? id) {
    if (id == null || id <= 0) {
      throw ServerException(message: ErrorMessages.notFound);
    }
    return id;
  }

  // ✅ SOLO INGLÉS
  String _validateStatus(String status) {
    const validStatuses = {
      'pending',
      'confirmed',
      'preparing',
      'shipped',
      'delivered',
      'cancelled',
    };
    final normalized = status.trim().toLowerCase();
    if (!validStatuses.contains(normalized)) {
      throw ServerException(message: ErrorMessages.badRequest);
    }
    return normalized;
  }

  // ============================================================
  // GET /orders (SIN FILTRO, EL BACKEND USA EL TOKEN)
  // ============================================================
  Future<List<Order>> getOrders() async {
    try {
      final headers = await _getSecureHeaders();

      // ✅ SIEMPRE USAR /orders/ SIN FILTRO
      // El backend ya filtra por usuario usando el token
      final url = ApiConfig.buildUrl(ApiConfig.ordersEndpoint);

      print('🔍 [SERVICE] GET /orders - URL: $url');

      final response = await _safeRequest(
        () => http.get(
          Uri.parse(url),
          headers: headers,
        ),
        'GET /orders',
      );

      final body = _validateResponse(response, 'GET /orders/');

      if (body == null) return [];

      if (body is! List) {
        throw ServerException(message: ErrorMessages.invalidResponse);
      }

      final List<Order> orders = [];
      for (final item in body) {
        if (item is Map<String, dynamic>) {
          try {
            orders.add(Order.fromJson(item));
          } catch (e) {
            AppLogger.error('getOrders: failed to parse order', e);
            continue;
          }
        }
      }

      print('📦 [SERVICE] Pedidos obtenidos: ${orders.length}');
      return orders;
    } catch (e) {
      AppLogger.error('getOrders', e);
      rethrow;
    }
  }

  // ============================================================
  // GET /orders/:id
  // ============================================================
  Future<Order> getOrderById(int id) async {
    final validId = _validateOrderId(id);

    try {
      final headers = await _getSecureHeaders();
      final response = await _safeRequest(
        () => http.get(
          ApiConfig.buildUri(ApiConfig.orderPath(validId)),
          headers: headers,
        ),
        'GET /orders/$validId',
      );

      final body = _validateResponse(response, 'GET /orders/$validId/');

      if (body == null || body is! Map<String, dynamic>) {
        throw ServerException(message: ErrorMessages.notFound);
      }

      return Order.fromJson(body);
    } catch (e) {
      AppLogger.error('getOrderById($id)', e);
      rethrow;
    }
  }

  // ============================================================
  // POST /orders
  // ============================================================
  Future<Order> createOrder(Map<String, dynamic> data) async {
    if (data == null) {
      throw ServerException(message: ErrorMessages.badRequest);
    }

    const allowedKeys = {
      'user_id',
      'items',
      'payment_method',
      'delivery_address'
    };
    final filteredData = Map<String, dynamic>.from(data);
    filteredData.removeWhere((key, value) => !allowedKeys.contains(key));

    if (filteredData.containsKey('items')) {
      final items = filteredData['items'];
      if (items is! List || items.isEmpty) {
        throw ServerException(message: ErrorMessages.badRequest);
      }
    }

    try {
      final headers = await _getSecureHeaders();
      final response = await _safeRequest(
        () => http.post(
          ApiConfig.buildUri(ApiConfig.ordersEndpoint),
          headers: headers,
          body: jsonEncode(filteredData),
        ),
        'POST /orders',
      );

      final body = _validateResponse(response, 'POST /orders/');

      if (body == null || body is! Map<String, dynamic>) {
        throw ServerException(message: ErrorMessages.serverError);
      }

      return Order.fromJson(body);
    } catch (e) {
      AppLogger.error('createOrder', e);
      rethrow;
    }
  }

  // ============================================================
  // PATCH /orders/:id/status
  // ============================================================
  Future<Order> updateOrderStatus(int id, String status) async {
    print('🔍 [SERVICE] updateOrderStatus: id=$id, status="$status"');

    final validId = _validateOrderId(id);
    final validStatus = _validateStatus(status);

    try {
      final headers = await _getSecureHeaders();
      print('🔍 [SERVICE] Headers obtenidos, enviando PATCH...');

      final response = await _safeRequest(
        () => http.patch(
          ApiConfig.buildUri(ApiConfig.orderStatusPath(validId)),
          headers: headers,
          body: jsonEncode({'status': validStatus}),
        ),
        'PATCH /orders/$validId/status',
      );

      print('🔍 [SERVICE] Respuesta recibida: ${response.statusCode}');

      final body = _validateResponse(response, 'PATCH /orders/$validId/status');

      if (body == null || body is! Map<String, dynamic>) {
        throw ServerException(message: ErrorMessages.serverError);
      }

      return Order.fromJson(body);
    } catch (e) {
      print('❌ [SERVICE] Error: $e');
      AppLogger.error('updateOrderStatus($id, $status)', e);
      rethrow;
    }
  }

  // ============================================================
  // CANCEL ORDER (POST en lugar de DELETE)
  // ============================================================
  Future<void> cancelOrder(int id) async {
    final validId = _validateOrderId(id);

    try {
      final headers = await _getSecureHeaders();
      print('🔍 [SERVICE] Cancelando pedido $validId...');

      // ✅ CAMBIAR A POST (coincide con el backend)
      final response = await _safeRequest(
        () => http.post(
          ApiConfig.buildUri(ApiConfig.orderCancelPath(validId)),
          headers: headers,
        ),
        'POST /orders/$validId/cancel',
      );

      print('🔍 [SERVICE] Respuesta cancelación: ${response.statusCode}');

      if (response.statusCode == 404) {
        return;
      }

      _validateResponse(response, 'POST /orders/$validId/cancel');
    } catch (e) {
      print('❌ [SERVICE] Error cancelando pedido: $e');
      AppLogger.error('cancelOrder($id)', e);
      rethrow;
    }
  }
}
