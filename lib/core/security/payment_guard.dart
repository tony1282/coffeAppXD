// lib/core/security/payment_guard.dart
//
// NUEVO — singleton centralizado para protección de pagos.
// Garantiza idempotencia real: la key se basa en orden+usuario+monto,
// NO en el timestamp (que varía con cada tap).

import 'dart:convert';
import 'package:crypto/crypto.dart';

class PaymentGuard {
  PaymentGuard._();
  static final PaymentGuard instance = PaymentGuard._();

  // Keys activas en vuelo: { idempotencyKey → DateTime de inicio }
  final Map<String, DateTime> _activeKeys = {};

  // Tiempo máximo que una key bloquea (cubre timeouts de red)
  static const Duration _keyTtl = Duration(minutes: 5);

  // ──────────────────────────────────────────────────────────────
  // Genera una key determinista: mismo orderId+userId+amount
  // siempre produce la misma key → reintentos seguros, doble-tap bloqueado.
  // ──────────────────────────────────────────────────────────────
  String buildKey({
    required int orderId,
    required String userId,
    required double amount,
  }) {
    // Redondear a 2 decimales para evitar diferencias de floating point
    final amountCents = (amount * 100).round();
    final raw = 'order:$orderId|user:$userId|amount:$amountCents';
    final bytes = utf8.encode(raw);
    return sha256.convert(bytes).toString().substring(0, 32);
  }

  // ──────────────────────────────────────────────────────────────
  // Intenta adquirir el lock para una key.
  // Retorna true si se adquirió (se puede proceder).
  // Retorna false si ya hay un pago en vuelo con esa key.
  // ──────────────────────────────────────────────────────────────
  bool acquire(String key) {
    _pruneExpired();

    if (_activeKeys.containsKey(key)) {
      return false; // pago ya en curso
    }

    _activeKeys[key] = DateTime.now();
    return true;
  }

  // Libera el lock (llamar siempre en finally)
  void release(String key) {
    _activeKeys.remove(key);
  }

  // ──────────────────────────────────────────────────────────────
  // Limpia keys caducadas para no acumular en memoria
  // ──────────────────────────────────────────────────────────────
  void _pruneExpired() {
    final now = DateTime.now();
    _activeKeys.removeWhere(
      (_, createdAt) => now.difference(createdAt) > _keyTtl,
    );
  }

  // Para tests / logout
  void clear() => _activeKeys.clear();
}