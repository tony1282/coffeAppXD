// lib/data/services/refund_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/error_messages.dart';
import '../../core/utils/logger.dart';
import '../models/payment_model.dart';

class RefundService {
  Future<Map<String, String>> _getSecureHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw AuthException(ErrorMessages.sessionExpired);
    }

    String? token;
    try {
      token = await user.getIdToken(false);
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

  // ──────────────────────────────────────────────────────────────
  // OBTENER PAGOS POR ID DE PEDIDO
  // ──────────────────────────────────────────────────────────────
  Future<List<Payment>> getPaymentsByOrder(int orderId) async {
    final headers = await _getSecureHeaders();

    try {
      // ✅ CORREGIDO: Cambiar /orders/$orderId/payments/ por /payments/order/$orderId/
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payments/order/$orderId/'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 401) {
        throw AuthException(ErrorMessages.sessionExpired);
      }
      if (response.statusCode == 404) {
        return [];
      }
      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Error al obtener pagos del pedido',
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body);
      
      // El backend devuelve una lista de pagos
      if (data is! List) {
        // Si devuelve un objeto, lo envolvemos en una lista
        if (data is Map<String, dynamic>) {
          return [Payment.fromJson(data)];
        }
        return [];
      }

      return data
          .where((item) => item is Map<String, dynamic>)
          .map((item) => Payment.fromJson(item))
          .toList();
    } on SocketException {
      throw NetworkException(ErrorMessages.noInternet);
    } on http.ClientException {
      throw NetworkException(ErrorMessages.noInternet);
    } catch (e) {
      AppLogger.error('RefundService.getPaymentsByOrder', e);
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // SOLICITAR REEMBOLSO DE UN PAGO
  // ──────────────────────────────────────────────────────────────
  Future<Payment> requestRefund({
    required int paymentId,
    required double amount,
    String? reason,
  }) async {
    if (amount <= 0) {
      throw ServerException(message: 'El monto a reembolsar debe ser mayor a 0');
    }

    final headers = await _getSecureHeaders();
    
    final body = jsonEncode({
      'payment_id': paymentId,
      'amount': amount,
      'reason': reason ?? 'Reembolso solicitado',
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payments/refund/'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 401) {
        throw AuthException(ErrorMessages.sessionExpired);
      }
      if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        throw ServerException(
          message: data['message'] ?? 'No se puede procesar el reembolso',
          statusCode: 400,
        );
      }
      if (response.statusCode == 404) {
        throw ServerException(
          message: 'Pago no encontrado',
          statusCode: 404,
        );
      }
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          message: 'Error al procesar el reembolso',
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body);
      
      if (data['payment'] is Map<String, dynamic>) {
        return Payment.fromJson(data['payment']);
      }
      
      if (data is Map<String, dynamic> && data.containsKey('id')) {
        return Payment.fromJson(data);
      }

      throw ServerException(message: 'Respuesta inesperada del servidor');
    } on SocketException {
      throw NetworkException(ErrorMessages.noInternet);
    } on http.ClientException {
      throw NetworkException(ErrorMessages.noInternet);
    } catch (e) {
      AppLogger.error('RefundService.requestRefund', e);
      rethrow;
    }
  }
}