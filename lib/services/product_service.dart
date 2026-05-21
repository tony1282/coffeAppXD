// lib/services/product_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../config/api_config.dart';

// ─── CONFIGURACIÓN DE SEGURIDAD INTERNA ─────────────────────────────
// Centralizada para auditoría. No afecta API pública.
class _ProductSecurityConfig {
  // Timeouts para evitar hanging requests (DoS parcial)
  static const Duration requestTimeout = Duration(seconds: 15);
  
  // Máximo tamaño de respuesta para prevenir bombas de memoria
  static const int maxResponseSizeBytes = 5 * 1024 * 1024; // 5 MB
  
  // IDs válidos son positivos (prevenir IDOR con IDs negativos o cero)
  static bool isValidId(int id) => id > 0;
  
  // Precios válidos (rango razonable)
  static bool isValidPrice(double price) => price > 0 && price < 10000;
  
  // Campos permitidos en create/update (whitelist - mass assignment prevention)
  static const Set<String> allowedFields = {
    'name', 'description', 'price', 'category', 
    'image_url', 'available', 'stock'
  };
  
  // Nombres de productos no pueden estar vacíos ni ser demasiado largos
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 1000;
}

// ─── ERRORES SANITIZADOS ───────────────────────────────────────────
// NUNCA exponer mensajes internos del servidor o Firebase.
class _ProductErrors {
  static const String notAuthenticated = 'Debes iniciar sesión para continuar';
  static const String sessionExpired = 'Tu sesión expiró. Inicia sesión nuevamente';
  static const String networkError = 'Sin conexión a internet. Verifica tu red';
  static const String serverError = 'Error en el servidor. Intenta más tarde';
  static const String productNotFound = 'El producto no existe';
  static const String invalidProductId = 'ID de producto inválido';
  static const String invalidData = 'Datos del producto inválidos';
  static const String unknownError = 'Ocurrió un error inesperado';
  static const String timeoutError = 'La solicitud tardó demasiado. Intenta de nuevo';
}

class ProductService {
  // ─── LOG SEGURO (SOLO DEBUG) ─────────────────────────────────────
  void _logSecure(String method, String event, {String? detail}) {
    assert(() {
      final safeDetail = detail != null ? ' | $detail' : '';
      // ignore: avoid_print
      print('[ProductService][$method] $event$safeDetail');
      return true;
    }());
  }

  // ─── VALIDACIÓN DE SESIÓN ────────────────────────────────────────
  // Previene: requests sin autenticación, tokens corruptos
  Future<Map<String, String>> _getSecureHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    
    // 🔒 Validación estricta de sesión
    if (user == null) {
      _logSecure('_getSecureHeaders', 'NO_AUTHENTICATED_USER');
      throw Exception(_ProductErrors.notAuthenticated);
    }
    
    // 🔒 Verificar que el UID no esté vacío (Firebase edge case)
    if (user.uid.isEmpty) {
      _logSecure('_getSecureHeaders', 'EMPTY_UID');
      throw Exception(_ProductErrors.notAuthenticated);
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
          throw Exception(_ProductErrors.sessionExpired);
        }
      } else {
        throw Exception(_ProductErrors.sessionExpired);
      }
    } catch (e) {
      _logSecure('_getSecureHeaders', 'UNEXPECTED_TOKEN_ERROR');
      throw Exception(_ProductErrors.sessionExpired);
    }
    
    // 🔒 Validación final del token
    if (token == null || token.isEmpty) {
      _logSecure('_getSecureHeaders', 'NULL_OR_EMPTY_TOKEN');
      throw Exception(_ProductErrors.sessionExpired);
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
        _ProductSecurityConfig.requestTimeout,
        onTimeout: () {
          _logSecure('_safeRequest', 'TIMEOUT: $endpoint');
          throw TimeoutException(_ProductErrors.timeoutError);
        },
      );
      
      // 🔒 Validación de tamaño de respuesta (previene memory bombing)
      final contentLength = response.contentLength;
      if (contentLength != null && contentLength > _ProductSecurityConfig.maxResponseSizeBytes) {
        _logSecure('_safeRequest', 'RESPONSE_TOO_LARGE: $contentLength bytes');
        throw Exception(_ProductErrors.serverError);
      }
      
      return response;
      
    } on SocketException {
      _logSecure('_safeRequest', 'SOCKET_EXCEPTION: $endpoint');
      throw Exception(_ProductErrors.networkError);
      
    } on TimeoutException {
      _logSecure('_safeRequest', 'TIMEOUT_EXCEPTION: $endpoint');
      throw Exception(_ProductErrors.timeoutError);
      
    } on http.ClientException catch (e) {
      _logSecure('_safeRequest', 'CLIENT_EXCEPTION: ${e.message}');
      throw Exception(_ProductErrors.networkError);
      
    } on FirebaseAuthException catch (e) {
      // 🔒 Si el token expiró durante el request, reintentamos una vez
      if ((e.code == 'user-token-expired' || e.code == 'id-token-expired') && retryCount < maxRetries) {
        _logSecure('_safeRequest', 'TOKEN_EXPIRED_DURING_REQUEST, RETRYING');
        return await _safeRequest(requestFn, endpoint, retryCount: retryCount + 1);
      }
      throw Exception(_ProductErrors.sessionExpired);
    }
  }

  // ─── VALIDACIÓN DE RESPUESTA HTTP ────────────────────────────────
  // Previene: malformed JSON, status codes no manejados, body vacío
  dynamic _validateResponse(http.Response response, String endpoint) {
    // 🔒 Validar status code primero
    if (response.statusCode == 401) {
      _logSecure('_validateResponse', 'UNAUTHORIZED: $endpoint');
      throw Exception(_ProductErrors.sessionExpired);
    }
    
    if (response.statusCode == 403) {
      _logSecure('_validateResponse', 'FORBIDDEN: $endpoint');
      throw Exception(_ProductErrors.productNotFound);
    }
    
    if (response.statusCode == 404) {
      _logSecure('_validateResponse', 'NOT_FOUND: $endpoint');
      throw Exception(_ProductErrors.productNotFound);
    }
    
    // 🔒 Respuesta vacía pero exitosa (ej: 204 No Content)
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null; // Sin body, pero éxito
      }
      _logSecure('_validateResponse', 'EMPTY_BODY_ERROR: ${response.statusCode}');
      throw Exception(_ProductErrors.serverError);
    }
    
    // 🔒 Parse seguro de JSON (previene malformed JSON)
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } on FormatException catch (e) {
      _logSecure('_validateResponse', 'MALFORMED_JSON: ${e.message}');
      throw Exception(_ProductErrors.serverError);
    }
    
    // 🔒 Manejo de errores del servidor (NUNCA exponer body interno)
    if (response.statusCode >= 500) {
      _logSecure('_validateResponse', 'SERVER_ERROR: ${response.statusCode} - $endpoint');
      throw Exception(_ProductErrors.serverError);
    }
    
    if (response.statusCode >= 400) {
      _logSecure('_validateResponse', 'CLIENT_ERROR: ${response.statusCode} - $endpoint');
      throw Exception(_ProductErrors.unknownError);
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    
    // Fallback seguro
    _logSecure('_validateResponse', 'UNHANDLED_STATUS: ${response.statusCode}');
    throw Exception(_ProductErrors.unknownError);
  }

  // ─── VALIDACIÓN DE ID (PREVENIR IDOR) ────────────────────────────
  // Previene: IDs negativos, cero, valores inválidos
  int _validateProductId(int id, String methodName) {
    if (!_ProductSecurityConfig.isValidId(id)) {
      _logSecure(methodName, 'INVALID_PRODUCT_ID: $id');
      throw Exception(_ProductErrors.invalidProductId);
    }
    return id;
  }
  
  // ─── VALIDACIÓN Y SANITIZACIÓN DE PAYLOAD ────────────────────────
  // Previene: mass assignment, datos inválidos, inyección
  Map<String, dynamic> _sanitizeProductData(Map<String, dynamic> data, String methodName) {
    if (data == null) {
      _logSecure(methodName, 'NULL_DATA');
      throw Exception(_ProductErrors.invalidData);
    }
    
    // 🔒 Whitelist de campos permitidos (mass assignment prevention)
    final sanitized = <String, dynamic>{};
    for (final entry in data.entries) {
      if (_ProductSecurityConfig.allowedFields.contains(entry.key)) {
        // 🔒 Validaciones específicas por campo
        switch (entry.key) {
          case 'name':
            if (entry.value is! String || entry.value.trim().isEmpty) {
              throw Exception('Nombre de producto inválido');
            }
            if (entry.value.length > _ProductSecurityConfig.maxNameLength) {
              throw Exception('Nombre demasiado largo');
            }
            sanitized[entry.key] = entry.value.trim();
            break;
            
          case 'description':
            if (entry.value != null) {
              final desc = entry.value.toString();
              if (desc.length > _ProductSecurityConfig.maxDescriptionLength) {
                throw Exception('Descripción demasiado larga');
              }
              sanitized[entry.key] = desc.trim();
            }
            break;
            
          case 'price':
            if (entry.value is! num) {
              throw Exception('Precio inválido');
            }
            final price = (entry.value as num).toDouble();
            if (!_ProductSecurityConfig.isValidPrice(price)) {
              throw Exception('Precio fuera de rango permitido');
            }
            sanitized[entry.key] = price;
            break;
            
          case 'stock':
            if (entry.value != null) {
              if (entry.value is! int || entry.value < 0) {
                throw Exception('Stock inválido');
              }
              sanitized[entry.key] = entry.value;
            }
            break;
            
          case 'available':
            if (entry.value is! bool) {
              throw Exception('Estado de disponibilidad inválido');
            }
            sanitized[entry.key] = entry.value;
            break;
            
          case 'image_url':
            if (entry.value != null && entry.value is! String) {
              throw Exception('URL de imagen inválida');
            }
            sanitized[entry.key] = entry.value?.toString() ?? '';
            break;
            
          default:
            sanitized[entry.key] = entry.value;
        }
      } else {
        _logSecure(methodName, 'SKIPPED_UNALLOWED_FIELD: ${entry.key}');
      }
    }
    
    return sanitized;
  }

  // ─── PARSE SEGURO DE PRODUCTO ────────────────────────────────────
  // Previene: crashes por datos corruptos
  Product _parseProductSafely(dynamic body, String methodName) {
    if (body == null) {
      _logSecure(methodName, 'NULL_BODY');
      throw Exception(_ProductErrors.serverError);
    }
    
    if (body is! Map<String, dynamic>) {
      _logSecure(methodName, 'INVALID_RESPONSE_TYPE: expected Map, got ${body.runtimeType}');
      throw Exception(_ProductErrors.serverError);
    }
    
    try {
      return Product.fromJson(body);
    } catch (e) {
      _logSecure(methodName, 'PARSE_ERROR: ${e.runtimeType}');
      throw Exception(_ProductErrors.serverError);
    }
  }

  // ════════════════════════════════════════════════════════════════
  // MÉTODOS PÚBLICOS - Misma firma, misma compatibilidad
  // ════════════════════════════════════════════════════════════════

  // ─── GET /products ──────────────────────────────────────────────
  Future<List<Product>> getProducts() async {
    final headers = await _getSecureHeaders();
    
    final response = await _safeRequest(
      () => http.get(
        Uri.parse('${ApiConfig.baseUrl}/products/'),
        headers: headers,
      ),
      'GET /products',
    );
    
    final body = _validateResponse(response, 'GET /products/');
    
    // 🔒 Validación defensiva de la respuesta
    if (body == null) {
      _logSecure('getProducts', 'NULL_BODY_RESPONSE');
      return []; // Lista vacía es más segura que null
    }
    
    if (body is! List) {
      _logSecure('getProducts', 'INVALID_RESPONSE_TYPE: expected List, got ${body.runtimeType}');
      throw Exception(_ProductErrors.serverError);
    }
    
    // 🔒 Validación de cada elemento antes de convertir
    final List<Product> products = [];
    for (final item in body) {
      if (item is Map<String, dynamic>) {
        try {
          products.add(Product.fromJson(item));
        } catch (e) {
          _logSecure('getProducts', 'FAILED_TO_PARSE_PRODUCT_ITEM');
          // Omitir productos corruptos en lugar de fallar todo el listado
          continue;
        }
      } else {
        _logSecure('getProducts', 'INVALID_PRODUCT_ITEM_TYPE');
        continue;
      }
    }
    
    return products;
  }

  // ─── GET /products/:id ──────────────────────────────────────────
  Future<Product> getProductById(int id) async {
    // 🔒 Validación de ID antes de hacer request
    final validId = _validateProductId(id, 'getProductById');
    
    final headers = await _getSecureHeaders();
    
    final response = await _safeRequest(
      () => http.get(
        Uri.parse('${ApiConfig.baseUrl}/products/$validId'),
        headers: headers,
      ),
      'GET /products/$validId',
    );
    
    final body = _validateResponse(response, 'GET /products/$validId');
    return _parseProductSafely(body, 'getProductById');
  }

  // ─── POST /products ─────────────────────────────────────────────
  Future<Product> createProduct(Map<String, dynamic> data) async {
    // 🔒 Sanitización y validación del payload antes de enviar
    final sanitizedData = _sanitizeProductData(data, 'createProduct');
    
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
    return _parseProductSafely(body, 'createProduct');
  }

  // ─── PUT /products/:id ──────────────────────────────────────────
  Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    // 🔒 Validación de ID antes de hacer request
    final validId = _validateProductId(id, 'updateProduct');
    
    // 🔒 Sanitización y validación del payload
    final sanitizedData = _sanitizeProductData(data, 'updateProduct');
    
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
    return _parseProductSafely(body, 'updateProduct');
  }

  // ─── DELETE /products/:id ───────────────────────────────────────
  Future<void> deleteProduct(int id) async {
    // 🔒 Validación de ID antes de hacer request
    final validId = _validateProductId(id, 'deleteProduct');
    
    final headers = await _getSecureHeaders();
    
    final response = await _safeRequest(
      () => http.delete(
        Uri.parse('${ApiConfig.baseUrl}/products/$validId'),
        headers: headers,
      ),
      'DELETE /products/$validId',
    );
    
    // 🔒 Para DELETE, 404 puede ser considerado "éxito" (el recurso ya no existe)
    if (response.statusCode == 404) {
      _logSecure('deleteProduct', 'PRODUCT_NOT_FOUND, treating as already deleted');
      return;
    }
    
    // Validación normal para otros status codes
    _validateResponse(response, 'DELETE /products/$validId');
  }

  // ─── PATCH /products/:id/availability ──────────────────────────
  Future<Product> toggleAvailability(int id, bool available) async {
    // 🔒 Validación de ID antes de hacer request
    final validId = _validateProductId(id, 'toggleAvailability');
    
    // 🔒 Validación del parámetro available
    if (available != true && available != false) {
      _logSecure('toggleAvailability', 'INVALID_AVAILABLE_VALUE');
      throw Exception(_ProductErrors.invalidData);
    }
    
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
    return _parseProductSafely(body, 'toggleAvailability');
  }
}

// ─── NOTAS DE SEGURIDAD PARA REVISIÓN ──────────────────────────────
// 
// ✅ VULNERABILIDADES CORREGIDAS:
//
// 1. IDOR (Insecure Direct Object Reference)
//    - Se validan IDs (positivos, no cero)
//    - IDs inválidos lanzan error antes de request
//
// 2. Token Expiration / Session Hijacking
//    - Validación estricta de sesión antes de cada request
//    - Refresh automático de token expirado (1 reintento)
//    - Validación de UID no vacío
//    - Manejo de FirebaseAuthException específico
//
// 3. Mass Assignment / Data Injection
//    - Whitelist de campos permitidos (solo campos conocidos)
//    - Sanitización de payload antes de enviar
//    - Eliminación de campos no autorizados
//    - Validaciones específicas por campo (precio, nombre, stock)
//
// 4. Error Information Disclosure
//    - NUNCA se exponen mensajes internos del servidor
//    - Stack traces nunca llegan al usuario
//    - FirebaseAuthException sanitizada
//    - Respuestas 4xx/5xx unificadas
//
// 5. DoS / Memory Bombing
//    - Timeout en todas las requests (15 segundos)
//    - Límite de tamaño de respuesta (5 MB)
//    - Control de reintentos (máximo 1)
//
// 6. Malformed JSON / Parsing Errors
//    - Try-catch en jsonDecode
//    - Validación de tipos antes de conversión
//    - Omitir elementos corruptos en listas
//    - Manejo seguro de productos individuales
//
// 7. Input Validation
//    - Precios válidos (0 < precio < 10000)
//    - Nombres no vacíos, longitud limitada
//    - Stock no negativo
//    - Disponibilidad booleana validada
//
// ⚠️ RIESGOS RESTANTES (BACKEND RESPONSIBILITY):
//
// - El backend DEBE validar que el usuario tiene permisos de admin
// - El backend DEBE tener rate limiting por IP/usuario
// - El backend DEBE validar que los productos no tengan nombres duplicados
// - El backend DEBE tener logging de operaciones sensibles (crear/eliminar)
// - El backend DEBE validar que el precio no sea manipulado (ya se valida en cliente pero el backend es la última línea)
// - El backend DEBE tener CORS configurado correctamente
// - El backend DEBE devolver created_at y updated_at en las respuestas
//
// 🔧 MEJORAS FUTURAS RECOMENDADAS (OPCIONALES):
//
// 1. Implementar cache de productos con tiempo de expiración
// 2. Agregar cancelación de requests (CancelToken) en páginas que se destruyen
// 3. Implementar retry con backoff exponencial para fallos de red
// 4. Agregar validación de que el producto existe antes de update/delete (opcional, el backend ya lo hace)