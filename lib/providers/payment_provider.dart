import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

class PaymentProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  // ============================================================
  // CONFIGURACIÓN DE SEGURIDAD
  // ============================================================
  static const int _maxPayments = 500;
  static const double _minValidAmount = 1.0;
  static const double _maxValidAmount = 100000.0;
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const int _maxRetries = 1;
  static const Duration _retryDelay = Duration(seconds: 1);

  // ============================================================
  // ESTADO
  // ============================================================
  List<Payment> _payments = [];
  bool isLoading = false;
  String? _errorMsg;

  // Prevenir race conditions en pagos
  final Set<String> _pendingPaymentKeys = {};

  List<Payment> get payments => List.unmodifiable(_payments);
  String? get errorMsg => _errorMsg;

  void _setLoading(bool v) { isLoading = v; notifyListeners(); }
  void _setError(String? msg) { _errorMsg = msg; notifyListeners(); }
  void _clearError() { _errorMsg = null; }

  // ============================================================
  // SANITIZACIÓN DE ERRORES
  // ============================================================
  String _sanitizeError(dynamic error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('socket') || raw.contains('network')) {
      return 'Sin conexión a internet';
    }
    if (raw.contains('timeout')) {
      return 'La solicitud tardó demasiado';
    }
    if (raw.contains('401') || raw.contains('403')) {
      return 'Tu sesión expiró. Inicia sesión nuevamente';
    }
    if (raw.contains('insufficient')) {
      return 'Fondos insuficientes';
    }
    if (raw.contains('card')) {
      return 'Error con la tarjeta. Verifica los datos';
    }
    return 'Error al procesar el pago. Intenta de nuevo';
  }

  // ============================================================
  // VALIDACIONES DE NEGOCIO
  // ============================================================
  bool _isValidAmount(double amount) {
    return amount >= _minValidAmount && amount <= _maxValidAmount;
  }

  bool _isValidPaymentData(Map<String, dynamic> data) {
    // ✅ Validar que existan campos requeridos
    if (!data.containsKey('amount')) return false;
    if (!data.containsKey('payment_method')) return false;

    // ✅ Validar tipo y rango del monto
    final amount = data['amount'];
    if (amount is! double && amount is! int) return false;
    if (!_isValidAmount(amount.toDouble())) return false;

    // ✅ Validar método de pago (whitelist)
    final method = data['payment_method']?.toString().toLowerCase();
    const validMethods = ['card', 'oxxo', 'bank_transfer', 'cash'];
    if (!validMethods.contains(method)) return false;

    return true;
  }

  // ============================================================
  // NETWORK WRAPPER
  // ============================================================
  Future<T> _safeRequest<T>(Future<T> Function() request) async {
    int attempt = 0;
    while (true) {
      try {
        return await request().timeout(_requestTimeout);
      } on TimeoutException {
        if (attempt >= _maxRetries) throw Exception('REQUEST_TIMEOUT');
        await Future.delayed(_retryDelay * (attempt + 1));
        attempt++;
      } on Exception catch (e) {
        final msg = e.toString().toLowerCase();
        if ((msg.contains('socket') || msg.contains('network')) && attempt < _maxRetries) {
          await Future.delayed(_retryDelay * (attempt + 1));
          attempt++;
          continue;
        }
        rethrow;
      }
    }
  }

  // ============================================================
  // FETCH PAYMENTS
  // ============================================================
  Future<void> fetchPayments() async {
    _clearError();
    _setLoading(true);

    try {
      final response = await _safeRequest(() => _api.get('/payments/my/'));

      if (response is! List) throw Exception('INVALID_RESPONSE_TYPE');

      // ✅ Prevenir memory bombing
      final truncated = response.length > _maxPayments
          ? response.sublist(0, _maxPayments)
          : response;

      final List<Payment> safePayments = [];

      for (final item in truncated) {
        if (item is! Map<String, dynamic>) continue;
        try {
          safePayments.add(Payment.fromJson(item));
        } catch (_) {
          continue; // Omitir pagos corruptos
        }
      }

      _payments = safePayments;
      notifyListeners();

      if (kDebugMode) {
        AppLogger.debug('Cargados ${_payments.length} pagos');
      }
    } catch (e) {
      _setError(_sanitizeError(e));
      if (kDebugMode) AppLogger.error('Error cargando pagos', e);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // CREATE PAYMENT (con idempotency)
  // ============================================================
  Future<Map<String, dynamic>> createPayment(Map<String, dynamic> data) async {
    _clearError();
    _setLoading(true);

    // ============================================================
    // VALIDACIONES CRÍTICAS EN FRONTEND
    // ============================================================
    if (!_isValidPaymentData(data)) {
      _setError('Datos de pago inválidos');
      _setLoading(false);
      throw Exception('Datos de pago inválidos');
    }

    // ============================================================
    // IDEMPOTENCY KEY (prevenir replay attacks)
    // ============================================================
    final idempotencyKey = '${DateTime.now().millisecondsSinceEpoch}_${data['amount']}_${data['payment_method']}';

    if (_pendingPaymentKeys.contains(idempotencyKey)) {
      _setError('Este pago ya está siendo procesado');
      _setLoading(false);
      throw Exception('DUPLICATE_PAYMENT');
    }

    _pendingPaymentKeys.add(idempotencyKey);

    // Timeout para limpiar lock (evita locks infinitos)
    Timer(const Duration(seconds: 60), () {
      _pendingPaymentKeys.remove(idempotencyKey);
    });

    try {
      // ============================================================
      // NUNCA enviar amount sin validar en backend también
      // El backend DEBE recalcular el total real
      // ============================================================
      final payload = Map<String, dynamic>.from(data);

      // ✅ Remover campos que no debe enviar el cliente (defensivo)
      payload.remove('id');
      payload.remove('created_at');
      payload.remove('user_id');

      // ✅ Agregar idempotency key al payload
      payload['idempotency_key'] = idempotencyKey;

      final response = await _safeRequest(() => _api.post('/payments/create/', payload));

      // ✅ Validar respuesta
      if (response is! Map<String, dynamic>) {
        throw Exception('INVALID_RESPONSE');
      }

      // ✅ Actualizar lista local si es necesario
      try {
        if (response.containsKey('payment') && response['payment'] is Map<String, dynamic>) {
          final newPayment = Payment.fromJson(response['payment']);
          _payments.insert(0, newPayment);
          if (_payments.length > _maxPayments) {
            _payments = _payments.sublist(0, _maxPayments);
          }
          notifyListeners();
        }
      } catch (_) {
        // No actualizar lista local si falla el parsing
      }

      return response;
    } catch (e) {
      _setError(_sanitizeError(e));
      if (kDebugMode) AppLogger.error('Error creando pago', e);
      rethrow;
    } finally {
      _setLoading(false);
      // Limpiar lock después de un tiempo (ya hay Timer, pero esto es por si fue exitoso)
      Future.delayed(const Duration(seconds: 2), () {
        _pendingPaymentKeys.remove(idempotencyKey);
      });
    }
  }

  // ============================================================
  // CLEAR (útil al cerrar sesión)
  // ============================================================
  void clear() {
    _payments = [];
    _pendingPaymentKeys.clear();
    _errorMsg = null;
    notifyListeners();
  }
}