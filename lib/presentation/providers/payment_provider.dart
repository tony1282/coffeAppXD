// lib/presentation/providers/payment_provider.dart
//
// Corregido:
//  - Idempotency key determinista (orderId+userId+amount) en lugar de timestamp
//  - Usa PaymentGuard para bloqueo de duplicados
//  - Usa MercadoPagoService (no http directo)
//  - El total NO se pasa al backend — el backend lo calcula desde la BD

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/error/error_handler.dart';
import '../../core/error/failure.dart';
import '../../core/error/exceptions.dart';
import '../../core/security/payment_guard.dart';
import '../../core/utils/logger.dart';
import '../../data/models/payment_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/mercadopago_service.dart';

class PaymentProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final _guard = PaymentGuard.instance;
  final _mp = MercadoPagoService.instance;

  // ── Límites de seguridad ──
  static const int _maxPayments = 500;
  static const double _minValidAmount = 1.0;
  static const double _maxValidAmount = 100000.0;
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const int _maxRetries = 1;
  static const Duration _retryDelay = Duration(seconds: 1);

  // ── Estado ──
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

  void _handleFailure(Failure failure) {
    _setError(failure.message);
    if (kDebugMode) AppLogger.error('PaymentProvider: ${failure.message}');
  }

  // ── Validaciones locales (pre-vuelo) ──
  bool _isValidAmount(double amount) =>
      amount >= _minValidAmount && amount <= _maxValidAmount;

  String? _currentUserId() =>
      FirebaseAuth.instance.currentUser?.uid;

  // ── Network wrapper con retry ──
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
      final response = await _safeRequest(() => _api.get('/payments/my/'));

      if (response is! List) {
        throw ServerException(message: 'Respuesta inválida');
      }

      final truncated = response.length > _maxPayments
          ? response.sublist(0, _maxPayments)
          : response;

      final safePayments = <Payment>[];
      for (final item in truncated) {
        if (item is! Map<String, dynamic>) continue;
        try {
          safePayments.add(Payment.fromJson(item));
        } catch (_) {
          continue;
        }
      }

      _payments = safePayments;
      notifyListeners();

      if (kDebugMode) {
        AppLogger.debug(
            'PaymentProvider: Cargados ${_payments.length} pagos');
      }
    } catch (e) {
      _handleFailure(ErrorHandler.handleError(e));
    } finally {
      _setLoading(false);
    }
  }

  // ────────────────────────────────────────────────────────────────
  // CREATE MERCADO PAGO PREFERENCE
  //
  // Retorna la MercadoPagoPreference lista para abrir en el WebView.
  // El total NO se envía al backend — el backend lo recalcula desde la BD.
  // ────────────────────────────────────────────────────────────────
  Future<MercadoPagoPreference> createMercadoPagoPreference({
    required int orderId,
    required double amountForValidation, // solo para validar localmente
  }) async {
    _clearError();

    // ── 1. Validación local de monto ──
    if (!_isValidAmount(amountForValidation)) {
      const msg = 'Monto de pago inválido';
      _setError(msg);
      throw ServerException(message: msg);
    }

    // ── 2. Usuario autenticado ──
    final userId = _currentUserId();
    if (userId == null) {
      const msg = 'Debes iniciar sesión para pagar';
      _setError(msg);
      throw ServerException(message: msg);
    }

    // ── 3. Construir idempotency key determinista ──
    final idempotencyKey = _guard.buildKey(
      orderId: orderId,
      userId: userId,
      amount: amountForValidation,
    );

    // ── 4. Bloquear duplicados ──
    if (!_guard.acquire(idempotencyKey)) {
      const msg = 'Este pago ya está siendo procesado. Espera un momento.';
      _setError(msg);
      throw ServerException(message: msg);
    }

    _setLoading(true);

    try {
      // ── 5. Llamar al backend (sin total, con idempotency key) ──
      final preference = await _mp.createPreference(
        orderId: orderId,
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
      // La key se mantiene activa en _guard hasta que el WebView
      // termine (éxito, fallo o cancelación). Se libera desde CartScreen.
    }
  }

  // Liberar el lock después de que el WebView termine
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
  // CREATE PAYMENT (pagos en general — efectivo, etc.)
  // ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> createPayment(
      Map<String, dynamic> data) async {
    _clearError();

    // Validar datos
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

    // Idempotency key para pagos genéricos (sin orderId fijo)
    // Usamos un hash de userId+monto+método+minuto actual
    final minuteBucket =
        DateTime.now().millisecondsSinceEpoch ~/ 60000; // ventana de 1 min
    final rawKey =
        'generic|user:$userId|amount:${(amount * 100).round()}|method:$method|bucket:$minuteBucket';
    final idempotencyKey = _guard.buildKey(
      orderId: minuteBucket, // proxy para evitar duplicados en la misma ventana
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
      // Limpiar campos que no debe mandar el cliente
      payload
        ..remove('id')
        ..remove('created_at')
        ..remove('user_id') // el backend lo extrae del token
        ..['idempotency_key'] = idempotencyKey;

      final response = await _safeRequest(
          () => _api.post('/payments/create/', payload));

      if (response is! Map<String, dynamic>) {
        throw ServerException(message: 'Respuesta inválida');
      }

      // Actualizar lista local si el backend devuelve el pago creado
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