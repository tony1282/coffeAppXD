// lib/data/services/mercadopago_service.dart
//
// NUEVO — encapsula todas las llamadas a tu backend relacionadas con MP.
// El cart_screen ya no hace http.post directo; delega aquí.

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../core/utils/logger.dart';

class MercadoPagoPreference {
  final String initPoint;
  final String preferenceId;

  const MercadoPagoPreference({
    required this.initPoint,
    required this.preferenceId,
  });
}

class MercadoPagoService {
  MercadoPagoService._();
  static final MercadoPagoService instance = MercadoPagoService._();

  static const Duration _timeout = Duration(seconds: 20);

  // ──────────────────────────────────────────────────────────────
  // Headers con Firebase ID token (expira en 1 h, se renueva solo)
  // ──────────────────────────────────────────────────────────────
  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // forceRefresh:false → usa caché; Firebase renueva automáticamente
    final token = await user.getIdToken(false);
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ──────────────────────────────────────────────────────────────
  // Crea la preferencia en TU backend.
  // IMPORTANTE: el backend recalcula el total desde la BD —
  // aquí solo mandamos order_id e idempotency_key.
  // ──────────────────────────────────────────────────────────────
  Future<MercadoPagoPreference> createPreference({
    required int orderId,
    required String idempotencyKey,
  }) async {
    final headers = await _authHeaders();

    // Agregamos la idempotency key también como header HTTP estándar
    // (tu backend puede leerla de aquí o del body, como prefieras)
    headers['X-Idempotency-Key'] = idempotencyKey;

    final body = jsonEncode({
      'order_id': orderId,
      // ❌ NO mandamos 'total' — el backend lo calcula desde la BD
      'idempotency_key': idempotencyKey,
    });

    late http.Response response;

    try {
      response = await http
          .post(
            Uri.parse(ApiConfig.mpCreatePreference),
            headers: headers,
            body: body,
          )
          .timeout(_timeout);
    } on Exception catch (e) {
      if (kDebugMode) AppLogger.error('MP createPreference network error: $e');
      throw Exception('Error de conexión al crear el pago');
    }

    // ── Validar status HTTP ──
    if (response.statusCode == 401) {
      throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
    }
    if (response.statusCode == 403) {
      throw Exception('No tienes permiso para pagar este pedido.');
    }
    if (response.statusCode == 409) {
      // Conflicto: el backend ya procesó esta idempotency key
      // → retornamos la preferencia existente en lugar de fallar
      final data = _parseBody(response.body);
      return _buildPreference(data);
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      if (kDebugMode) {
        AppLogger.error('MP createPreference HTTP ${response.statusCode}: ${response.body}');
      }
      throw Exception('Error al crear el pago (${response.statusCode})');
    }

    final data = _parseBody(response.body);
    return _buildPreference(data);
  }

  // ──────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────
  Map<String, dynamic> _parseBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Respuesta inesperada del servidor');
      }
      return decoded;
    } catch (_) {
      throw Exception('Respuesta inválida del servidor');
    }
  }

  MercadoPagoPreference _buildPreference(Map<String, dynamic> data) {

    debugPrint('📦 Respuesta MP completa: $data');

    final initPoint = data['init_point'] as String?;
    final preferenceId = data['preference_id'] as String?;

    debugPrint('📦 init_point: $initPoint');
  debugPrint('📦 preference_id: $preferenceId');

    if (initPoint == null || initPoint.isEmpty) {
      throw Exception('URL de pago no recibida del servidor');
    }

    // Validar que la URL sea de Mercado Pago (no una URL inyectada)
    final uri = Uri.tryParse(initPoint);
    if (uri == null ||
    (!uri.host.endsWith('mercadopago.com') &&
     !uri.host.endsWith('mercadopago.com.mx') &&
     !uri.host.endsWith('mercadolibre.com'))) {
  throw Exception('URL de pago inválida');
}

    return MercadoPagoPreference(
      initPoint: initPoint,
      preferenceId: preferenceId ?? '',
    );
  }
}