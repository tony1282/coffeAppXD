// lib/presentation/providers/order_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/error/error_handler.dart';
import '../../core/error/failure.dart';
import '../../core/utils/logger.dart';
import '../../core/config/order_status_config.dart';
import '../../data/models/order_model.dart';
import '../../data/services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _service = OrderService();

  // ============================================================
  // CONFIGURACIÓN DE SEGURIDAD (SOLO INGLÉS)
  // ============================================================
  static const int _maxOrders = 2000;
  static const Duration _requestTimeout = Duration(seconds: 20);
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  // ✅ SOLO INGLÉS
  static const List<String> _validStatuses = [
    'pending', 'confirmed', 'preparing', 'shipped', 'delivered', 'cancelled',
  ];

  // ✅ TRANSICIONES EN INGLÉS
  static const Map<String, List<String>> _allowedTransitions = {
    'pending': ['confirmed', 'cancelled'],
    'confirmed': ['preparing', 'cancelled'],
    'preparing': ['shipped', 'cancelled'],
    'shipped': ['delivered', 'cancelled'],
    'delivered': [],
    'cancelled': [],
  };

  // ============================================================
  // ESTADO
  // ============================================================
  List<Order> _orders = [];
  List<Order> _activeOrders = [];
  Order? _currentOrder;
  bool isLoading = false;
  String? errorMsg;

  final Set<int> _updatingOrderIds = {};
  bool _isFetching = false;

  List<Order> get orders => List.unmodifiable(_orders);
  List<Order> get activeOrders => List.unmodifiable(_activeOrders);
  Order? get currentOrder => _currentOrder;

  void _setLoading(bool v) { isLoading = v; notifyListeners(); }
  void _setError(String? msg) { errorMsg = msg; notifyListeners(); }
  void _clearError() { errorMsg = null; }

  void _handleFailure(Failure failure) {
    _setError(failure.message);
    if (kDebugMode) {
      AppLogger.error('OrderProvider: ${failure.message}');
    }
  }

  bool _isValidOrderId(int id) => id > 0;
  bool _isValidStatus(String status) => _validStatuses.contains(status);

  bool _isValidTransition(String current, String next) {
    return _allowedTransitions[current]?.contains(next) ?? false;
  }

  Future<T> _withNetworkFallback<T>(Future<T> Function() request) async {
    int attempt = 0;
    while (true) {
      try {
        return await request().timeout(_requestTimeout);
      } catch (e) {
        final isNetwork = e.toString().toLowerCase().contains('socket') ||
            e.toString().toLowerCase().contains('timeout');
        if (!isNetwork || attempt >= _maxRetries) rethrow;
        attempt++;
        await Future.delayed(_retryDelay * attempt);
      }
    }
  }

  // ============================================================
  // FETCH ORDERS (SIN PASAR userId, EL BACKEND USA EL TOKEN)
  // ============================================================
  Future<void> fetchOrders({String? userId}) async {
    if (_isFetching) {
      if (kDebugMode) {
        AppLogger.debug('OrderProvider: fetchOrders - YA EN PROCESO, IGNORANDO');
      }
      return;
    }

    _isFetching = true;
    _clearError();
    _setLoading(true);

    if (kDebugMode) {
      AppLogger.debug('OrderProvider: fetchOrders - INICIO');
    }

    try {
      // ✅ NO PASAR userId, el backend usa el token
      final fetched = await _withNetworkFallback(
        () => _service.getOrders()
      );

      if (kDebugMode) {
        AppLogger.debug('OrderProvider: fetched count: ${fetched.length}');
      }

      final truncated = fetched.length > _maxOrders
          ? fetched.sublist(0, _maxOrders)
          : fetched;

      _orders = truncated;
      _activeOrders = _orders.where((o) =>
          o.status != 'delivered' && o.status != 'cancelled').toList();

      notifyListeners();
    } catch (e) {
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
      if (kDebugMode) {
        AppLogger.error('OrderProvider: Error en fetchOrders: $e');
      }
    } finally {
      _setLoading(false);
      _isFetching = false;
    }
  }

  // ============================================================
  // FETCH ORDER BY ID
  // ============================================================
  Future<void> fetchOrderById(int id) async {
    if (!_isValidOrderId(id)) {
      _setError('ID de pedido inválido');
      return;
    }

    _setLoading(true);

    try {
      _currentOrder = await _withNetworkFallback(() => _service.getOrderById(id));
      notifyListeners();
    } catch (e) {
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // CREATE ORDER
  // ============================================================
  Future<bool> createOrder(Map<String, dynamic> orderData) async {
    _clearError();
    _setLoading(true);

    try {
      final newOrder = await _withNetworkFallback(() => _service.createOrder(orderData));

      _orders.insert(0, newOrder);
      _activeOrders = _orders.where((o) =>
          o.status != 'delivered' && o.status != 'cancelled').toList();

      notifyListeners();
      return true;
    } catch (e) {
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // UPDATE ORDER STATUS
  // ============================================================
  Future<bool> updateOrderStatus(int id, String status) async {
    print('🔍 [PROVIDER] updateOrderStatus: id=$id, status="$status"');

    _clearError();

    if (!_isValidOrderId(id)) {
      _setError('ID de pedido inválido');
      print('❌ [PROVIDER] ID inválido');
      return false;
    }

    final normalizedStatus = status.trim().toLowerCase();

    if (!_isValidStatus(normalizedStatus)) {
      _setError('Estado inválido');
      print('❌ [PROVIDER] Estado inválido: $normalizedStatus');
      return false;
    }

    final idx = _orders.indexWhere((o) => o.id == id);
    if (idx == -1) {
      _setError('Pedido no encontrado');
      print('❌ [PROVIDER] Pedido no encontrado: $id');
      return false;
    }

    final currentOrder = _orders[idx];
    print('🔍 [PROVIDER] Estado actual: ${currentOrder.status}');

    if (!_isValidTransition(currentOrder.status, normalizedStatus)) {
      _setError('No se puede cambiar de ${currentOrder.status} a $normalizedStatus');
      print('❌ [PROVIDER] Transición inválida: ${currentOrder.status} → $normalizedStatus');
      return false;
    }

    if (_updatingOrderIds.contains(id)) {
      _setError('El pedido ya está siendo actualizado');
      print('❌ [PROVIDER] Ya está actualizando: $id');
      return false;
    }

    _updatingOrderIds.add(id);

    final originalOrder = currentOrder;

    final updatedOrder = currentOrder.copyWith(status: normalizedStatus);
    _orders[idx] = updatedOrder;
    _activeOrders = _orders.where((o) =>
        o.status != 'delivered' && o.status != 'cancelled').toList();
    if (_currentOrder?.id == id) _currentOrder = updatedOrder;
    notifyListeners();

    try {
      print('🔍 [PROVIDER] Llamando a service.updateOrderStatus...');
      final result = await _withNetworkFallback(
        () => _service.updateOrderStatus(id, normalizedStatus)
      );
      print('✅ [PROVIDER] service.updateOrderStatus exitoso');

      final finalIdx = _orders.indexWhere((o) => o.id == id);
      if (finalIdx != -1) _orders[finalIdx] = result;
      _activeOrders = _orders.where((o) =>
          o.status != 'delivered' && o.status != 'cancelled').toList();
      if (_currentOrder?.id == id) _currentOrder = result;
      notifyListeners();

      return true;
    } catch (e) {
      print('❌ [PROVIDER] Error en updateOrderStatus: $e');
      _orders[idx] = originalOrder;
      _activeOrders = _orders.where((o) =>
          o.status != 'delivered' && o.status != 'cancelled').toList();
      if (_currentOrder?.id == id) _currentOrder = originalOrder;
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
      notifyListeners();
      return false;
    } finally {
      _updatingOrderIds.remove(id);
    }
  }

  // ============================================================
  // CANCEL ORDER
  // ============================================================
  Future<bool> cancelOrder(int id) async {
    if (!_isValidOrderId(id)) {
      _setError('ID de pedido inválido');
      return false;
    }

    try {
      await _withNetworkFallback(() => _service.cancelOrder(id));
      await fetchOrders();
      return true;
    } catch (e) {
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
      return false;
    }
  }

  // ============================================================
  // FILTROS
  // ============================================================
  List<Order> getOrdersByStatus(String status) {
    return _orders.where((o) => o.status == status).toList();
  }

  List<Order> getOrdersByDate(DateTime date) {
    return _orders.where((o) =>
        o.createdAt.year == date.year &&
        o.createdAt.month == date.month &&
        o.createdAt.day == date.day
    ).toList();
  }
}