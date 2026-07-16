import 'dart:async';
import '../../core/utils/logger.dart';
import '../../core/error/failure.dart';
import 'package:flutter/foundation.dart';
import '../../core/error/exceptions.dart';
import '../../core/config/api_config.dart';
import '../../core/error/error_handler.dart';
import '../../data/models/payment_model.dart';
import '../../data/services/api_service.dart';
import '../../core/security/payment_guard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/mercadopago_service.dart';
// lib/presentation/providers/payment_provider.dart

class PaymentProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final _guard = PaymentGuard.instance;
  final _mp = MercadoPagoService.instance;

  static const int _maxPayments = 500;
  static const double _minValidAmount = 1.0;
  static const double _maxValidAmount = 100000.0;
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const int _maxRetries = 1;
  static const Duration _retryDelay = Duration(seconds: 1);

  List<Payment> _payments = [];
  bool isLoading = false;
  String? _errorMsg;

  List<Payment> get payments => List.unmodifiable(_payments);
  String? get errorMsg => _errorMsg;

  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMsg = msg;
    notifyListeners();
  }

  void _clearError() => _errorMsg = null;

  List<Payment> _parsePayments(dynamic response) {
    if (response is! List) return [];

    final parsed = <Payment>[];
    for (final item in response) {
      if (item is! Map<String, dynamic>) continue;
      try {
        parsed.add(Payment.fromJson(item));
      } catch (_) {
        continue;
      }
    }
    return parsed;
  }

  void _handleFailure(Failure failure) {
    _setError(failure.message);
    if (kDebugMode) AppLogger.error('PaymentProvider: ${failure.message}');
  }

  bool _isValidAmount(double amount) =>
      amount >= _minValidAmount && amount <= _maxValidAmount;

  String? _currentUserId() => FirebaseAuth.instance.currentUser?.uid;

  Future<T> _safeRequest<T>(Future<T> Function() request) async {
    int attempt = 0;
    while (true) {
      try {
        return await request().timeout(_requestTimeout);
      } on TimeoutException {
        if (attempt >= _maxRetries) {
          throw NetworkException('Tiempo de espera agotado');
        }
        await Future.delayed(_retryDelay * (attempt + 1));
        attempt++;
      } on Exception catch (e) {
        final msg = e.toString().toLowerCase();
        final isNetworkError =
            msg.contains('socket') || msg.contains('network');
        if (isNetworkError && attempt < _maxRetries) {
          await Future.delayed(_retryDelay * (attempt + 1));
          attempt++;
          continue;
        }
        rethrow;
      }
    }
  }

  // ────────────────────────────────────────────────────────────────
  // FETCH PAYMENTS
  // ────────────────────────────────────────────────────────────────
  Future<void> fetchPayments() async {
    _clearError();
    _setLoading(true);

    try {
      final response =
          await _safeRequest(() => _api.get(ApiConfig.paymentsMyEndpoint));

      if (response is! List) {
        throw ServerException(message: 'Respuesta inválida');
      }

      final truncated = response.length > _maxPayments
          ? response.sublist(0, _maxPayments)
          : response;

      _payments = _parsePayments(truncated);
      notifyListeners();

      if (kDebugMode) {
        AppLogger.debug('PaymentProvider: Cargados ${_payments.length} pagos');
      }
    } catch (e) {
      _handleFailure(ErrorHandler.handleError(e));
    } finally {
      _setLoading(false);
    }
  }

  // ────────────────────────────────────────────────────────────────
  // CREATE MERCADO PAGO PREFERENCE (NUEVO: recibe orderData)
  // ────────────────────────────────────────────────────────────────
  Future<MercadoPagoPreference> createMercadoPagoPreference({
    required Map<String, dynamic> orderData,
  }) async {
    _clearError();

    // 1️⃣ Validar monto
    final total = (orderData['total'] as num?)?.toDouble() ?? 0;
    if (!_isValidAmount(total)) {
      const msg = 'Monto de pago inválido';
      _setError(msg);
      throw ServerException(message: msg);
    }

    // 2️⃣ Usuario autenticado
    final userId = _currentUserId();
    if (userId == null) {
      const msg = 'Debes iniciar sesión para pagar';
      _setError(msg);
      throw ServerException(message: msg);
    }

    // Asegurar que el userId coincida
    orderData['user_id'] = userId;

    // 3️⃣ Construir idempotency key
    final idempotencyKey = _guard.buildKey(
      orderId: DateTime.now().millisecondsSinceEpoch,
      userId: userId,
      amount: total,
    );

    // 4️⃣ Bloquear duplicados
    if (!_guard.acquire(idempotencyKey)) {
      const msg = 'Este pago ya está siendo procesado. Espera un momento.';
      _setError(msg);
      throw ServerException(message: msg);
    }

    _setLoading(true);

    try {
      final preference = await _mp.createPreference(
        orderData: orderData,
        idempotencyKey: idempotencyKey,
      );

      if (kDebugMode) {
        AppLogger.debug(
            'PaymentProvider: Preferencia creada ${preference.preferenceId}');
      }

      return preference;
    } catch (e) {
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Liberar el lock
  void releasePaymentLock({
    required int orderId,
    required String userId,
    required double amount,
  }) {
    final key = _guard.buildKey(
      orderId: orderId,
      userId: userId,
      amount: amount,
    );
    _guard.release(key);
  }

  // ────────────────────────────────────────────────────────────────
  // CREATE PAYMENT (legacy)
  // ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> createPayment(Map<String, dynamic> data) async {
    _clearError();

    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    if (!_isValidAmount(amount)) {
      const msg = 'Datos de pago inválidos';
      _setError(msg);
      throw ServerException(message: msg);
    }

    final method = data['payment_method']?.toString().toLowerCase() ?? '';
    const validMethods = ['card', 'oxxo', 'bank_transfer', 'cash'];
    if (!validMethods.contains(method)) {
      const msg = 'Método de pago no válido';
      _setError(msg);
      throw ServerException(message: msg);
    }

    final userId = _currentUserId();
    if (userId == null) {
      const msg = 'Debes iniciar sesión para pagar';
      _setError(msg);
      throw ServerException(message: msg);
    }

    final minuteBucket = DateTime.now().millisecondsSinceEpoch ~/ 60000;
    final idempotencyKey = _guard.buildKey(
      orderId: minuteBucket,
      userId: userId,
      amount: amount,
    );

    if (!_guard.acquire(idempotencyKey)) {
      const msg = 'Este pago ya está siendo procesado';
      _setError(msg);
      throw ServerException(message: msg);
    }

    _setLoading(true);

    try {
      final payload = Map<String, dynamic>.from(data);
      payload
        ..remove('id')
        ..remove('created_at')
        ..remove('user_id')
        ..['idempotency_key'] = idempotencyKey;

      final response = await _safeRequest(
          () => _api.post(ApiConfig.paymentsCreateEndpoint, payload));

      if (response is! Map<String, dynamic>) {
        throw ServerException(message: 'Respuesta inválida');
      }

      if (response['payment'] is Map<String, dynamic>) {
        try {
          final newPayment =
              Payment.fromJson(response['payment'] as Map<String, dynamic>);
          _payments.insert(0, newPayment);
          if (_payments.length > _maxPayments) {
            _payments = _payments.sublist(0, _maxPayments);
          }
          notifyListeners();
        } catch (_) {}
      }

      return response;
    } catch (e) {
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
      rethrow;
    } finally {
      _setLoading(false);
      _guard.release(idempotencyKey);
    }
  }

  // lib/presentation/providers/payment_provider.dart

// ═══════════════════════════════════════════════════════════════════
// 🔍 VERIFICAR PAGO DIRECTAMENTE EN MERCADO PAGO
// ═══════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> verifyPayment(String preferenceId) async {
    try {
      final result = await _api.verifyPayment(preferenceId);
      return result;
    } catch (e) {
      if (kDebugMode) AppLogger.error('verifyPayment', e);
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ────────────────────────────────────────────────────────────────
  // CLEAR (logout)
  // ────────────────────────────────────────────────────────────────
  void clear() {
    _payments = [];
    _guard.clear();
    _errorMsg = null;
    notifyListeners();
  }
}
