// lib/data/services/mercadopago_service.dart

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

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final token = await user.getIdToken(false);
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ──────────────────────────────────────────────────────────────
  // NUEVO: createPreference con orderData
  // ──────────────────────────────────────────────────────────────
  Future<MercadoPagoPreference> createPreference({
    required Map<String, dynamic> orderData,
    required String idempotencyKey,
  }) async {
    final headers = await _authHeaders();
    headers['X-Idempotency-Key'] = idempotencyKey;

    final body = jsonEncode({
      'order_data': orderData,
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

    if (response.statusCode == 401) {
      throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
    }
    if (response.statusCode == 403) {
      throw Exception('No tienes permiso para pagar este pedido.');
    }
    if (response.statusCode == 409) {
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