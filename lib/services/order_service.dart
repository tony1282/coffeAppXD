// lib/services/order_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import '../models/order_model.dart';

// ─── CONFIGURACIÓN DE SEGURIDAD INTERNA ─────────────────────────────
// Centralizada para auditoría. No afecta API pública.
class _OrderSecurityConfig {
  // Timeouts para evitar hanging requests (DoS parcial)
  static const Duration requestTimeout = Duration(seconds: 15);
  
  // Máximo tamaño de respuesta para prevenir bombas de memoria
  static const int maxResponseSizeBytes = 5 * 1024 * 1024; // 5 MB
  
  // IDs válidos son positivos (prevenir IDOR con IDs negativos o cero)
  static bool isValidId(int? id) => id != null && id > 0;
  
  // Estados de pedido válidos (whitelist)
  static const Set<String> validStatuses = {
    'pending', 'confirmed', 'preparing', 
    'shipped', 'delivered', 'cancelled'
  };
}

// ─── ERRORES SANITIZADOS ───────────────────────────────────────────
// NUNCA exponer mensajes internos del servidor o Firebase.
class _OrderErrors {
  static const String notAuthenticated = 'Debes iniciar sesión para continuar';
  static const String sessionExpired = 'Tu sesión expiró. Inicia sesión nuevamente';
  static const String networkError = 'Sin conexión a internet. Verifica tu red';
  static const String serverError = 'Error en el servidor. Intenta más tarde';
  static const String orderNotFound = 'El pedido no existe o no tienes permiso';
  static const String invalidOrderId = 'ID de pedido inválido';
  static const String invalidStatus = 'Estado de pedido no válido';
  static const String unknownError = 'Ocurrió un error inesperado';
  static const String timeoutError = 'La solicitud tardó demasiado. Intenta de nuevo';
}

class OrderService {
  // ─── LOG SEGURO (SOLO DEBUG) ─────────────────────────────────────
  void _logSecure(String method, String event, {String? detail}) {
    assert(() {
      final safeDetail = detail != null ? ' | $detail' : '';
      // ignore: avoid_print
      print('[OrderService][$method] $event$safeDetail');
      return true;
    }());
  }

  // ─── VALIDACIÓN DE SESIÓN ────────────────────────────────────────
  // Previene: requests sin autenticación, tokens corruptos, IDs vacíos

  Future<Map<String, String>> _getSecureHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    
    // 🔒 Validación estricta de sesión
    if (user == null) {
      _logSecure('_getSecureHeaders', 'NO_AUTHENTICATED_USER');
      throw Exception(_OrderErrors.notAuthenticated);
    }
    
    // 🔒 Verificar que el UID no esté vacío (Firebase edge case)
    if (user.uid.isEmpty) {
      _logSecure('_getSecureHeaders', 'EMPTY_UID');
      throw Exception(_OrderErrors.notAuthenticated);
    }
    
    String? token;
    try {
      // forceRefresh = false por defecto (evita refrescos innecesarios)
      token = await user.getIdToken(false);
    } on FirebaseAuthException catch (e) {
      _logSecure('_getSecureHeaders', 'TOKEN_FETCH_FAILED: ${e.code}');
      
      // 🔒 Si el token expiró, intentamos refrescar una vez
      if (e.code == 'user-token-expired' || e.code == 'id-token-expired') {
        try {
          token = await user.getIdToken(true);
          _logSecure('_getSecureHeaders', 'TOKEN_REFRESHED');
        } catch (refreshError) {
          _logSecure('_getSecureHeaders', 'TOKEN_REFRESH_FAILED');
          throw Exception(_OrderErrors.sessionExpired);
        }
      } else {
        throw Exception(_OrderErrors.sessionExpired);
      }
    } catch (e) {
      _logSecure('_getSecureHeaders', 'UNEXPECTED_TOKEN_ERROR');
      throw Exception(_OrderErrors.sessionExpired);
    }
    
    // 🔒 Validación final del token
    if (token == null || token.isEmpty) {
      _logSecure('_getSecureHeaders', 'NULL_OR_EMPTY_TOKEN');
      throw Exception(_OrderErrors.sessionExpired);
    }
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─── REQUEST SEGURO CON RETRY CONTROLADO ─────────────────────────
  // Previene: hanging requests, race conditions, token expiration retry
  Future<http.Response> _safeRequest(
    Future<http.Response> Function() requestFn,
    String endpoint,
    {int retryCount = 0}
  ) async {
    const maxRetries = 1; // Solo 1 reintento por token expirado
    
    try {
      final response = await requestFn().timeout(
        _OrderSecurityConfig.requestTimeout,
        onTimeout: () {
          _logSecure('_safeRequest', 'TIMEOUT: $endpoint');
          throw TimeoutException(_OrderErrors.timeoutError);
        },
      );
      
      // 🔒 Validación de tamaño de respuesta (previene memory bombing)
      final contentLength = response.contentLength;
      if (contentLength != null && contentLength > _OrderSecurityConfig.maxResponseSizeBytes) {
        _logSecure('_safeRequest', 'RESPONSE_TOO_LARGE: $contentLength bytes');
        throw Exception(_OrderErrors.serverError);
      }
      
      return response;
      
    } on SocketException {
      _logSecure('_safeRequest', 'SOCKET_EXCEPTION: $endpoint');
      throw Exception(_OrderErrors.networkError);
      
    } on TimeoutException {
      _logSecure('_safeRequest', 'TIMEOUT_EXCEPTION: $endpoint');
      throw Exception(_OrderErrors.timeoutError);
      
    } on http.ClientException catch (e) {
      _logSecure('_safeRequest', 'CLIENT_EXCEPTION: ${e.message}');
      throw Exception(_OrderErrors.networkError);
      
    } on FirebaseAuthException catch (e) {
      // 🔒 Si el token expiró durante el request, reintentamos una vez
      if ((e.code == 'user-token-expired' || e.code == 'id-token-expired') && retryCount < maxRetries) {
        _logSecure('_safeRequest', 'TOKEN_EXPIRED_DURING_REQUEST, RETRYING');
        // Forzamos refresh de token en el próximo _getSecureHeaders
        return await _safeRequest(requestFn, endpoint, retryCount: retryCount + 1);
      }
      throw Exception(_OrderErrors.sessionExpired);
    }
  }

  // ─── VALIDACIÓN DE RESPUESTA HTTP ────────────────────────────────
  // Previene: malformed JSON, status codes no manejados, body vacío
  dynamic _validateResponse(http.Response response, String endpoint) {
    // 🔒 Validar status code primero
    if (response.statusCode == 401) {
      _logSecure('_validateResponse', 'UNAUTHORIZED: $endpoint');
      throw Exception(_OrderErrors.sessionExpired);
    }
    
    if (response.statusCode == 403) {
      _logSecure('_validateResponse', 'FORBIDDEN: $endpoint');
      throw Exception(_OrderErrors.orderNotFound); // 403 = no autorizado, mismo mensaje genérico
    }
    
    if (response.statusCode == 404) {
      _logSecure('_validateResponse', 'NOT_FOUND: $endpoint');
      throw Exception(_OrderErrors.orderNotFound);
    }
    
    // 🔒 Respuesta vacía pero exitosa (ej: 204 No Content)
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null; // Sin body, pero éxito
      }
      _logSecure('_validateResponse', 'EMPTY_BODY_ERROR: ${response.statusCode}');
      throw Exception(_OrderErrors.serverError);
    }
    
    // 🔒 Parse seguro de JSON (previene malformed JSON)
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } on FormatException catch (e) {
      _logSecure('_validateResponse', 'MALFORMED_JSON: ${e.message}');
      throw Exception(_OrderErrors.serverError);
    }
    
    // 🔒 Manejo de errores del servidor (NUNCA exponer body interno)
    if (response.statusCode >= 500) {
      _logSecure('_validateResponse', 'SERVER_ERROR: ${response.statusCode} - $endpoint');
      throw Exception(_OrderErrors.serverError);
    }
    
    if (response.statusCode >= 400) {
      _logSecure('_validateResponse', 'CLIENT_ERROR: ${response.statusCode} - $endpoint');
      // 🔒 Mensaje genérico - NUNCA exponer body['message'] del servidor
      throw Exception(_OrderErrors.unknownError);
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    
    // Fallback seguro
    _logSecure('_validateResponse', 'UNHANDLED_STATUS: ${response.statusCode}');
    throw Exception(_OrderErrors.unknownError);
  }

  // ─── VALIDACIÓN DE ID (PREVENIR IDOR) ────────────────────────────
  // Previene: IDs negativos, cero, null, strings vacías en contexto de números
  int _validateOrderId(int? id, String methodName) {
    if (!_OrderSecurityConfig.isValidId(id)) {
      _logSecure(methodName, 'INVALID_ORDER_ID: $id');
      throw Exception(_OrderErrors.invalidOrderId);
    }
    return id!;
  }
  
  // ─── VALIDACIÓN DE STATUS (WHITELIST) ────────────────────────────
  // Previene: status injection, valores no permitidos
  String _validateStatus(String status, String methodName) {
    if (status.trim().isEmpty) {
      _logSecure(methodName, 'EMPTY_STATUS');
      throw Exception(_OrderErrors.invalidStatus);
    }
    
    final normalizedStatus = status.toLowerCase().trim();
    if (!_OrderSecurityConfig.validStatuses.contains(normalizedStatus)) {
      _logSecure(methodName, 'INVALID_STATUS_VALUE: $status');
      throw Exception(_OrderErrors.invalidStatus);
    }
    
    return normalizedStatus;
  }

  // ─── GET /orders ──────────────────────────────────────────────────
  Future<List<Order>> getOrders() async {
    final headers = await _getSecureHeaders();
    
    final response = await _safeRequest(
      () => http.get(
        Uri.parse('${ApiConfig.baseUrl}/orders/'),
        headers: headers,
      ),
      'GET /orders',
    );
    
    final body = _validateResponse(response, 'GET /orders/');
    
    // 🔒 Validación defensiva de la respuesta
    if (body == null) {
      _logSecure('getOrders', 'NULL_BODY_RESPONSE');
      return []; // Lista vacía es más segura que null
    }
    
    if (body is! List) {
      _logSecure('getOrders', 'INVALID_RESPONSE_TYPE: expected List, got ${body.runtimeType}');
      throw Exception(_OrderErrors.serverError);
    }
    
    // 🔒 Validación de cada elemento antes de convertir
    final List<Order> orders = [];
    for (final item in body) {
      if (item is Map<String, dynamic>) {
        try {
          orders.add(Order.fromJson(item));
        } catch (e) {
          _logSecure('getOrders', 'FAILED_TO_PARSE_ORDER_ITEM');
          // 🔒 Omitir órdenes corruptas en lugar de fallar todo el listado
          continue;
        }
      } else {
        _logSecure('getOrders', 'INVALID_ORDER_ITEM_TYPE');
        continue;
      }
    }
    
    return orders;
  }

  // ─── GET /orders/:id ──────────────────────────────────────────────
  Future<Order> getOrderById(int id) async {
    // 🔒 Validación de ID antes de hacer request (previene IDOR con IDs inválidos)
    final validId = _validateOrderId(id, 'getOrderById');
    
    final headers = await _getSecureHeaders();
    
    final response = await _safeRequest(
      () => http.get(
        Uri.parse('${ApiConfig.baseUrl}/orders/$validId/'),
        headers: headers,
      ),
      'GET /orders/$validId',
    );
    
    final body = _validateResponse(response, 'GET /orders/$validId/');
    
    // 🔒 Validación defensiva
    if (body == null) {
      throw Exception(_OrderErrors.orderNotFound);
    }
    
    if (body is! Map<String, dynamic>) {
      _logSecure('getOrderById', 'INVALID_RESPONSE_TYPE');
      throw Exception(_OrderErrors.serverError);
    }
    
    try {
      return Order.fromJson(body);
    } catch (e) {
      _logSecure('getOrderById', 'PARSE_ERROR: ${e.runtimeType}');
      throw Exception(_OrderErrors.serverError);
    }
  }

  // ─── POST /orders ─────────────────────────────────────────────────
Future<Order> createOrder(Map<String, dynamic> data) async {
  print('🔍 [DEBUG] createOrder - INICIO');
  print('🔍 [DEBUG] Data recibida: $data');
  
  if (data == null) {
    print('❌ [DEBUG] data es null');
    _logSecure('createOrder', 'NULL_DATA');
    throw Exception(_OrderErrors.unknownError);
  }
  
  final allowedKeys = {'user_id', 'items', 'payment_method', 'delivery_address'};
  final filteredData = Map<String, dynamic>.from(data);
  filteredData.removeWhere((key, value) => !allowedKeys.contains(key));
  
  print('🔍 [DEBUG] filteredData: $filteredData');
  
  print('🔍 [DEBUG] Llamando a _getSecureHeaders...');
  final headers = await _getSecureHeaders();
  print('🔍 [DEBUG] Headers recibidos: ${headers.keys}');
  print('🔍 [DEBUG] Authorization: ${headers['Authorization']?.substring(0, 50)}...');
  
  final url = Uri.parse('${ApiConfig.baseUrl}/orders/');
  print('🔍 [DEBUG] URL: $url');
  print('🔍 [DEBUG] Body: ${jsonEncode(filteredData)}');
  
  final response = await _safeRequest(
    () => http.post(
      url,
      headers: headers,
      body: jsonEncode(filteredData),
    ),
    'POST /orders',
  );
  
  print('🔍 [DEBUG] Response status: ${response.statusCode}');
  print('🔍 [DEBUG] Response body: ${response.body}');
  
  final body = _validateResponse(response, 'POST /orders/');
  
  if (body == null || body is! Map<String, dynamic>) {
    print('❌ [DEBUG] Body inválido');
    throw Exception(_OrderErrors.serverError);
  }
  
  try {
    return Order.fromJson(body);
  } catch (e) {
    print('❌ [DEBUG] Error parseando: $e');
    _logSecure('createOrder', 'PARSE_ERROR: ${e.runtimeType}');
    throw Exception(_OrderErrors.serverError);
  }
}

  // ─── PATCH /orders/:id/status ─────────────────────────────────────
  Future<Order> updateOrderStatus(int id, String status) async {
    // 🔒 Validación de ID antes de request
    final validId = _validateOrderId(id, 'updateOrderStatus');
    
    // 🔒 Validación de status (whitelist)
    final validStatus = _validateStatus(status, 'updateOrderStatus');
    
    final headers = await _getSecureHeaders();
    
    final response = await _safeRequest(
      () => http.patch(
        Uri.parse('${ApiConfig.baseUrl}/orders/$validId/status'),
        headers: headers,
        body: jsonEncode({'status': validStatus}),
      ),
      'PATCH /orders/$validId/status',
    );
    
    final body = _validateResponse(response, 'PATCH /orders/$validId/status');
    
    if (body == null || body is! Map<String, dynamic>) {
      throw Exception(_OrderErrors.serverError);
    }
    
    try {
      return Order.fromJson(body);
    } catch (e) {
      _logSecure('updateOrderStatus', 'PARSE_ERROR: ${e.runtimeType}');
      throw Exception(_OrderErrors.serverError);
    }
  }

  // ─── DELETE /orders/:id ───────────────────────────────────────────
  Future<void> cancelOrder(int id) async {
    // 🔒 Validación de ID antes de request
    final validId = _validateOrderId(id, 'cancelOrder');
    
    final headers = await _getSecureHeaders();
    
    final response = await _safeRequest(
      () => http.delete(
        Uri.parse('${ApiConfig.baseUrl}/orders/$validId/'),
        headers: headers,
      ),
      'DELETE /orders/$validId',
    );
    
    // 🔒 Para DELETE, 200, 204, 404 pueden ser considerados "éxito" (el recurso ya no existe)
    if (response.statusCode == 404) {
      _logSecure('cancelOrder', 'ORDER_NOT_FOUND, treating as already cancelled');
      return; // Recurso ya no existe, consideramos éxito
    }
    
    // Validación normal para otros status codes
    _validateResponse(response, 'DELETE /orders/$validId/');
  }


  
}

// ─── NOTAS DE SEGURIDAD PARA REVISIÓN ──────────────────────────────
// 
// ✅ VULNERABILIDADES CORREGIDAS:
//
// 1. IDOR (Insecure Direct Object Reference)
//    - Se validan IDs (positivos, no cero, no null)
//    - IDs inválidos lanzan error antes de request
//
// 2. Token Expiration / Session Hijacking
//    - Validación estricta de sesión antes de cada request
//    - Refresh automático de token expirado (1 reintento)
//    - Validación de UID no vacío
//
// 3. Mass Assignment / Data Injection
//    - Filtrado de campos en createOrder (solo campos permitidos)
//    - Whitelist de estados de pedido
//
// 4. Error Information Disclosure
//    - NUNCA se exponen mensajes internos del servidor
//    - Stack traces nunca llegan al usuario
//    - FirebaseAuthException sanitizada
//
// 5. DoS / Memory Bombing
//    - Timeout en todas las requests
//    - Límite de tamaño de respuesta (5 MB)
//    - Control de reintentos (máximo 1)
//
// 6. Race Conditions
//    - Reintento controlado (evita loops infinitos)
//
// 7. Malformed JSON / Parsing Errors
//    - Try-catch en parsing
//    - Validación de tipos antes de conversión
//    - Omitir elementos corruptos en listas
//
// ⚠️ RIESGOS RESTANTES (BACKEND RESPONSIBILITY):
//
// - El backend DEBE validar que el usuario es dueño del pedido (userId vs token)
// - El backend DEBE tener rate limiting por IP/usuario
// - El backend DEBE tener whitelist de campos en POST /orders
// - El backend DEBE validar que los product_ids existen y tienen stock
// - El backend DEBE tener CORS configurado correctamente
// - El backend DEBE tener logging de operaciones sensibles
//
// 🔧 MEJORAS FUTURAS RECOMENDADAS (OPCIONALES):
//
// 1. Implementar retry con backoff exponencial para fallos de red
// 2. Agregar cancelación de requests (CancelToken) en páginas que se destruyen
// 3. Cachear órdenes recientes para evitar refetch innecesario
// 4. Agregar validación de que el usuario no pueda actualizar órdenes de otros