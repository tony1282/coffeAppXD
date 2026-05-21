import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/io_client.dart';

import '../config/api_config.dart';

// ─── CONSTANTES DE SEGURIDAD ────────────────────────────────────
// Centralizadas aquí para fácil auditoría y ajuste en producción.
class _SecurityConfig {
  static const int requestTimeoutSeconds = 15;
  static const int maxRequestsPerMinute = 60;
  static const int maxRetries = 1; // Solo 1 reintento por 401
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];
  static const List<String> allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
}

// ─── ERRORES INTERNOS SEGUROS ────────────────────────────────────
// Nunca exponemos mensajes del backend al usuario.
// Los logs internos sí pueden tener detalle para debugging.
class _SafeErrors {
  static const String noInternet       = 'Sin conexión a internet';
  static const String sessionExpired   = 'Tu sesión expiró. Por favor inicia sesión nuevamente';
  static const String forbidden        = 'No tienes permiso para realizar esta acción';
  static const String notFound         = 'El recurso solicitado no fue encontrado';
  static const String badRequest       = 'La solicitud no es válida';
  static const String tooManyRequests  = 'Demasiadas solicitudes. Intenta en un momento';
  static const String serverError      = 'Error en el servidor. Intenta más tarde';
  static const String unknown          = 'Ocurrió un error inesperado. Intenta de nuevo';
  static const String uploadFailed     = 'No se pudo subir la imagen. Intenta de nuevo';
  static const String imageTooLarge    = 'La imagen excede el tamaño máximo permitido (5 MB)';
  static const String imageInvalidType = 'Tipo de archivo no permitido. Usa JPG, PNG o WebP';
  static const String timeout          = 'La solicitud tardó demasiado. Verifica tu conexión';
  static const String rateLimited      = 'Demasiadas solicitudes. Espera un momento';
  static const String invalidResponse  = 'Respuesta del servidor no válida';
}

class ApiService {
  // ─── RATE LIMITING ──────────────────────────────────────────────
  // Lista estática para persistir entre instancias.
  static final List<DateTime> _requestLog = [];

  // ─── SECURE HTTP CLIENT ─────────────────────────────────────────
  // Rechaza cualquier certificado SSL inválido.
  // badCertificateCallback = false → NUNCA acepta certs inválidos.
  // En producción, agrega certificate pinning comparando el fingerprint
  // exacto de tu servidor para máxima protección MITM.
  static http.Client _buildSecureClient() {
    final ioClient = HttpClient(context: SecurityContext.defaultContext)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // ⚠️ PRODUCTION HARDENING: descomentar para certificate pinning real
        // final expectedFingerprint = ApiConfig.certificateFingerprint;
        // final actualFingerprint = _computeFingerprint(cert);
        // return actualFingerprint == expectedFingerprint;

        // Por ahora: rechaza cualquier cert inválido (false = rechazar)
        return false;
      }
      ..connectionTimeout = const Duration(seconds: _SecurityConfig.requestTimeoutSeconds);
    return IOClient(ioClient);
  }

  // ─── RATE LIMITING ──────────────────────────────────────────────
  // Previene abuso de la API desde el cliente.
  // Lanza excepción antes de siquiera hacer la petición si se excede el límite.
  void _checkRateLimit() {
    final now = DateTime.now();

    // Limpiar entradas fuera de la ventana de 1 minuto
    _requestLog.removeWhere(
      (timestamp) => now.difference(timestamp).inSeconds > 60,
    );

    if (_requestLog.length >= _SecurityConfig.maxRequestsPerMinute) {
      // Log interno seguro — nunca exponer al usuario el límite exacto
      _logSecure('RATE_LIMIT_HIT', 'Requests: ${_requestLog.length}/60 en 60s');
      throw Exception(_SafeErrors.rateLimited);
    }

    _requestLog.add(now);
  }

  // ─── TOKEN MANAGEMENT ───────────────────────────────────────────
  // forceRefresh = true fuerza renovación del token con Firebase.
  // Se usa en el retry automático cuando el servidor responde 401.
  Future<Map<String, String>> _getHeaders({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;

    // Verificación defensiva: usuario puede haber cerrado sesión
    if (user == null) {
      throw Exception(_SafeErrors.sessionExpired);
    }

    String? token;
    try {
      token = await user.getIdToken(forceRefresh);
    } on FirebaseAuthException catch (e) {
      _logSecure('TOKEN_FETCH_ERROR', 'FirebaseAuthException: ${e.code}');
      throw Exception(_SafeErrors.sessionExpired);
    } catch (e) {
      _logSecure('TOKEN_FETCH_ERROR', 'Unexpected: ${e.runtimeType}');
      throw Exception(_SafeErrors.sessionExpired);
    }

    // Token nunca debería ser nulo si el usuario existe, pero defensive check
    if (token == null || token.isEmpty) {
      _logSecure('TOKEN_NULL', 'Token is null/empty for uid: ${user.uid}');
      throw Exception(_SafeErrors.sessionExpired);
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      // ✅ Header anti-MIME sniffing
      'X-Content-Type-Options': 'nosniff',
    };
  }

  // ─── SANITIZACIÓN DE ERRORES HTTP ───────────────────────────────
  // NUNCA expone body interno del servidor al usuario.
  // Solo loggea internamente para debugging.
  String _sanitizeError(dynamic body, int statusCode, String endpoint) {
    // Log interno seguro con contexto suficiente para debugging
    _logSecure(
      'HTTP_ERROR',
      'Status: $statusCode | Endpoint: $endpoint | Body type: ${body.runtimeType}',
    );

    switch (statusCode) {
      case 400: return _SafeErrors.badRequest;
      case 401: return _SafeErrors.sessionExpired;
      case 403: return _SafeErrors.forbidden;
      case 404: return _SafeErrors.notFound;
      case 429: return _SafeErrors.tooManyRequests;
      case 500:
      case 502:
      case 503:
      case 504: return _SafeErrors.serverError;
      default:  return _SafeErrors.unknown;
    }
  }

  // ─── VALIDACIÓN DE RESPUESTA JSON ───────────────────────────────
  // Previene crashes por respuestas malformadas o inesperadas del servidor.
  dynamic _parseBody(String rawBody, String endpoint) {
    if (rawBody.isEmpty) return null;

    // Límite de tamaño de respuesta (previene ataques de body bombing)
    if (rawBody.length > 10 * 1024 * 1024) { // 10 MB máximo
      _logSecure('RESPONSE_TOO_LARGE', 'Endpoint: $endpoint | Size: ${rawBody.length}');
      throw Exception(_SafeErrors.serverError);
    }

    try {
      return jsonDecode(rawBody);
    } on FormatException catch (e) {
      _logSecure('JSON_PARSE_ERROR', 'Endpoint: $endpoint | Error: ${e.message}');
      throw Exception(_SafeErrors.invalidResponse);
    }
  }

  // ─── RETRY CON TOKEN RENOVADO ───────────────────────────────────
  // Patrón: intenta → si 401 → renueva token → reintenta (1 vez máximo).
  // Previene loops infinitos con maxRetries = 1.
  Future<dynamic> _executeWithRetry(
    Future<http.Response> Function(Map<String, String> headers) requestFn,
    String endpoint,
  ) async {
    _checkRateLimit();

    http.Response res;
    Map<String, String> headers;

    try {
      headers = await _getHeaders();
      res = await requestFn(headers);
    } on SocketException {
      throw Exception(_SafeErrors.noInternet);
    } on TimeoutException {
      throw Exception(_SafeErrors.timeout);
    } on TlsException catch (e) {
      // Error SSL — no exponer detalle
      _logSecure('TLS_ERROR', e.runtimeType.toString());
      throw Exception(_SafeErrors.serverError);
    }

    // Retry automático en 401: token pudo haber expirado justo antes del request
    if (res.statusCode == 401) {
      _logSecure('TOKEN_EXPIRED', 'Retrying with fresh token for: $endpoint');
      try {
        headers = await _getHeaders(forceRefresh: true);
        res = await requestFn(headers);
      } on SocketException {
        throw Exception(_SafeErrors.noInternet);
      } on TimeoutException {
        throw Exception(_SafeErrors.timeout);
      }

      // Si sigue en 401 después del retry, la sesión realmente expiró
      if (res.statusCode == 401) {
        _logSecure('AUTH_FAILED_AFTER_RETRY', 'Endpoint: $endpoint');
        throw Exception(_SafeErrors.sessionExpired);
      }
    }

    return _handleResponse(res, endpoint);
  }

  // ─── VALIDACIÓN DE IMAGEN ────────────────────────────────────────
  // Previene subida de archivos maliciosos o inesperadamente grandes.
  Future<void> _validateImageFile(File imageFile) async {
    // 1. Verificar que el archivo exista
    if (!await imageFile.exists()) {
      throw Exception(_SafeErrors.uploadFailed);
    }

    // 2. Verificar tamaño máximo
    final size = await imageFile.length();
    if (size > _SecurityConfig.maxImageSizeBytes) {
      throw Exception(_SafeErrors.imageTooLarge);
    }

    // 3. Verificar extensión del archivo
    final extension = imageFile.path
        .split('.')
        .last
        .toLowerCase();
    if (!_SecurityConfig.allowedExtensions.contains('.$extension')) {
      throw Exception(_SafeErrors.imageInvalidType);
    }

    // 4. Verificar magic bytes (firma real del archivo, no solo extensión)
    // Previene que un archivo .exe renombrado a .jpg sea aceptado.
    final bytes = await imageFile.openRead(0, 12).first;
    if (!_isValidImageMagicBytes(bytes)) {
      _logSecure('INVALID_MAGIC_BYTES', 'File: ${imageFile.path.split('/').last}');
      throw Exception(_SafeErrors.imageInvalidType);
    }
  }

  // Verifica la firma real del archivo (magic bytes)
  bool _isValidImageMagicBytes(List<int> bytes) {
    if (bytes.length < 4) return false;

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes[0] == 0x89 && bytes[1] == 0x50 &&
        bytes[2] == 0x4E && bytes[3] == 0x47) return true;

    // WebP: 52 49 46 46 (RIFF)
    if (bytes[0] == 0x52 && bytes[1] == 0x49 &&
        bytes[2] == 0x46 && bytes[3] == 0x46) return true;

    return false;
  }

  // ─── LOG INTERNO SEGURO ──────────────────────────────────────────
  // NUNCA loggea tokens, API keys, datos personales, ni body completo.
  // Solo metadata suficiente para debugging.
  void _logSecure(String event, String detail) {
    assert(() {
      // Solo en modo debug — en release estos prints no aparecen
      // En producción, reemplazar con tu servicio de logging (Crashlytics, etc.)
      // ignore: avoid_print
      print('[ApiService][$event] $detail');
      return true;
    }());
  }

  // ════════════════════════════════════════════════════════════════
  // MÉTODOS PÚBLICOS — misma firma, misma lógica, mayor seguridad
  // ════════════════════════════════════════════════════════════════

  Future<dynamic> get(String endpoint) async {
    try {
      return await _executeWithRetry(
        (headers) => _buildSecureClient()
            .get(
              Uri.parse('${ApiConfig.baseUrl}$endpoint'),
              headers: headers,
            )
            .timeout(const Duration(seconds: _SecurityConfig.requestTimeoutSeconds)),
        endpoint,
      );
    } on SocketException {
      throw Exception(_SafeErrors.noInternet);
    } on TimeoutException {
      throw Exception(_SafeErrors.timeout);
    }
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      return await _executeWithRetry(
        (headers) => _buildSecureClient()
            .post(
              Uri.parse('${ApiConfig.baseUrl}$endpoint'),
              headers: headers,
              body: jsonEncode(data),
            )
            .timeout(const Duration(seconds: _SecurityConfig.requestTimeoutSeconds)),
        endpoint,
      );
    } on SocketException {
      throw Exception(_SafeErrors.noInternet);
    } on TimeoutException {
      throw Exception(_SafeErrors.timeout);
    }
  }

  Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      return await _executeWithRetry(
        (headers) => _buildSecureClient()
            .put(
              Uri.parse('${ApiConfig.baseUrl}$endpoint'),
              headers: headers,
              body: jsonEncode(data),
            )
            .timeout(const Duration(seconds: _SecurityConfig.requestTimeoutSeconds)),
        endpoint,
      );
    } on SocketException {
      throw Exception(_SafeErrors.noInternet);
    } on TimeoutException {
      throw Exception(_SafeErrors.timeout);
    }
  }

  Future<dynamic> patch(String endpoint, dynamic data) async {
    try {
      return await _executeWithRetry(
        (headers) => _buildSecureClient()
            .patch(
              Uri.parse('${ApiConfig.baseUrl}$endpoint'),
              headers: headers,
              body: jsonEncode(data),
            )
            .timeout(const Duration(seconds: _SecurityConfig.requestTimeoutSeconds)),
        endpoint,
      );
    } on SocketException {
      throw Exception(_SafeErrors.noInternet);
    } on TimeoutException {
      throw Exception(_SafeErrors.timeout);
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      return await _executeWithRetry(
        (headers) => _buildSecureClient()
            .delete(
              Uri.parse('${ApiConfig.baseUrl}$endpoint'),
              headers: headers,
            )
            .timeout(const Duration(seconds: _SecurityConfig.requestTimeoutSeconds)),
        endpoint,
      );
    } on SocketException {
      throw Exception(_SafeErrors.noInternet);
    } on TimeoutException {
      throw Exception(_SafeErrors.timeout);
    }
  }

  // ─── SUBIR IMAGEN ──────────────────────────────────────────────

  Future<String> uploadImage(File imageFile) async {
    // 1. Validación completa del archivo antes de cualquier request
    await _validateImageFile(imageFile);

    // 2. Rate limit
    _checkRateLimit();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception(_SafeErrors.sessionExpired);

    final uri = Uri.parse('${ApiConfig.baseUrl}/products/upload-image');

    // Función interna para reutilizar en el retry
    Future<http.Response> sendRequest(String? token) async {
      final request = http.MultipartRequest('POST', uri);

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
        request.headers['X-Content-Type-Options'] = 'nosniff';
      }

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      try {
        final streamed = await request.send()
            .timeout(const Duration(seconds: 30)); // timeout mayor para uploads
        return http.Response.fromStream(streamed);
      } on TimeoutException {
        throw Exception(_SafeErrors.timeout);
      }
    }

    try {
      String? token = await user.getIdToken();
      var response = await sendRequest(token);

      // Retry con token renovado si expiró
      if (response.statusCode == 401) {
        _logSecure('UPLOAD_TOKEN_EXPIRED', 'Retrying with fresh token');
        token = await user.getIdToken(true);
        response = await sendRequest(token);
      }

      // Parsear respuesta de forma segura
      final body = _parseBody(response.body, '/products/upload-image');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final imageUrl = body?['imageUrl'] ?? body?['url'] ?? '';
        if (imageUrl is! String || imageUrl.isEmpty) {
          _logSecure('UPLOAD_INVALID_URL', 'Response missing imageUrl/url');
          throw Exception(_SafeErrors.uploadFailed);
        }
        return imageUrl;
      }

      throw Exception(
        _sanitizeError(body, response.statusCode, '/products/upload-image'),
      );
    } on SocketException {
      throw Exception(_SafeErrors.noInternet);
    } on FirebaseAuthException catch (e) {
      _logSecure('UPLOAD_AUTH_ERROR', e.code);
      throw Exception(_SafeErrors.sessionExpired);
    }
  }

  // ─── HANDLE RESPONSE ─────────────────────────────────────────────

  dynamic _handleResponse(http.Response res, String endpoint) {
    final body = _parseBody(res.body, endpoint);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    // Errores sanitizados — jamás expone body interno
    throw Exception(_sanitizeError(body, res.statusCode, endpoint));
  }
}