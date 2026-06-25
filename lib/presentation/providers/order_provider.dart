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

  static const int _maxOrders = 2000;
  static const Duration _requestTimeout = Duration(seconds: 20);
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  static const List<String> _validStatuses = [
    'pending', 'confirmed', 'preparing', 'shipped', 'delivered', 'cancelled',
  ];

  static const Map<String, List<String>> _allowedTransitions = {
    'pending':   ['confirmed', 'cancelled'],
    'confirmed': ['preparing', 'cancelled'],
    'preparing': ['shipped', 'cancelled'],
    'shipped':   ['delivered', 'cancelled'],
    'delivered': [],
    'cancelled': [],
  };

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
    if (kDebugMode) AppLogger.error('OrderProvider: ${failure.message}');
  }

  bool _isValidOrderId(int id) => id > 0;
  bool _isValidStatus(String status) => _validStatuses.contains(status);
  bool _isValidTransition(String current, String next) =>
      _allowedTransitions[current]?.contains(next) ?? false;

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

  // ────────────────────────────────────────────────────────────────
  // FETCH ORDERS
  // ────────────────────────────────────────────────────────────────
  Future<void> fetchOrders({String? userId}) async {
    if (_isFetching) return;
    _isFetching = true;
    _clearError();
    _setLoading(true);

    if (kDebugMode) AppLogger.debug('OrderProvider: fetchOrders - INICIO');

    try {
      final fetched = await _withNetworkFallback(() => _service.getOrders());

      if (kDebugMode) AppLogger.debug('OrderProvider: fetched count: ${fetched.length}');

      final truncated = fetched.length > _maxOrders
          ? fetched.sublist(0, _maxOrders)
          : fetched;

      _orders = truncated;
      _activeOrders = _orders
          .where((o) => o.status != 'delivered' && o.status != 'cancelled')
          .toList();

      notifyListeners();
    } catch (e) {
      _handleFailure(ErrorHandler.handleError(e));
      if (kDebugMode) AppLogger.error('OrderProvider: Error en fetchOrders: $e');
    } finally {
      _setLoading(false);
      _isFetching = false;
    }
  }

  // ────────────────────────────────────────────────────────────────
  // FETCH ORDER BY ID
  // ✅ FIX: también actualiza _orders para que updateOrderStatus
  // siga encontrando el pedido después de un fetchOrderById
  // ────────────────────────────────────────────────────────────────
  Future<void> fetchOrderById(int id) async {
    if (!_isValidOrderId(id)) {
      _setError('ID de pedido inválido');
      return;
    }

    _setLoading(true);

    try {
      final fresh = await _withNetworkFallback(() => _service.getOrderById(id));

      // Actualizar _currentOrder
      _currentOrder = fresh;

      // ✅ FIX: sincronizar también en _orders
      final idx = _orders.indexWhere((o) => o.id == id);
      if (idx != -1) {
        _orders[idx] = fresh;
      } else {
        // Si no estaba en la lista (ej. admin abrió pedido de otro usuario)
        // lo insertamos al inicio
        _orders.insert(0, fresh);
      }

      _activeOrders = _orders
          .where((o) => o.status != 'delivered' && o.status != 'cancelled')
          .toList();

      notifyListeners();
    } catch (e) {
      _handleFailure(ErrorHandler.handleError(e));
    } finally {
      _setLoading(false);
    }
  }

  // ────────────────────────────────────────────────────────────────
  // CREATE ORDER
  // ────────────────────────────────────────────────────────────────
  Future<bool> createOrder(Map<String, dynamic> orderData) async {
    _clearError();
    _setLoading(true);

    try {
      final newOrder =
          await _withNetworkFallback(() => _service.createOrder(orderData));

      _orders.insert(0, newOrder);
      _activeOrders = _orders
          .where((o) => o.status != 'delivered' && o.status != 'cancelled')
          .toList();

      notifyListeners();
      return true;
    } catch (e) {
      _handleFailure(ErrorHandler.handleError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ────────────────────────────────────────────────────────────────
  // UPDATE ORDER STATUS
  // ────────────────────────────────────────────────────────────────
  Future<bool> updateOrderStatus(int id, String status) async {
    _clearError();

    if (!_isValidOrderId(id)) {
      _setError('ID de pedido inválido');
      return false;
    }

    final normalizedStatus = status.trim().toLowerCase();

    if (!_isValidStatus(normalizedStatus)) {
      _setError('Estado inválido');
      return false;
    }

    final idx = _orders.indexWhere((o) => o.id == id);
    if (idx == -1) {
      _setError('Pedido no encontrado');
      if (kDebugMode) AppLogger.error('OrderProvider: Pedido $id no en _orders');
      return false;
    }

    final currentOrder = _orders[idx];

    if (!_isValidTransition(currentOrder.status, normalizedStatus)) {
      _setError(
          'No se puede cambiar de ${currentOrder.status} a $normalizedStatus');
      return false;
    }

    if (_updatingOrderIds.contains(id)) {
      _setError('El pedido ya está siendo actualizado');
      return false;
    }

    _updatingOrderIds.add(id);

    // Optimistic update
    final updatedOrder = currentOrder.copyWith(status: normalizedStatus);
    _orders[idx] = updatedOrder;
    _activeOrders = _orders
        .where((o) => o.status != 'delivered' && o.status != 'cancelled')
        .toList();
    if (_currentOrder?.id == id) _currentOrder = updatedOrder;
    notifyListeners();

    try {
      final result = await _withNetworkFallback(
          () => _service.updateOrderStatus(id, normalizedStatus));

      if (kDebugMode) AppLogger.debug('OrderProvider: updateOrderStatus exitoso');

      final finalIdx = _orders.indexWhere((o) => o.id == id);
      if (finalIdx != -1) _orders[finalIdx] = result;
      _activeOrders = _orders
          .where((o) => o.status != 'delivered' && o.status != 'cancelled')
          .toList();
      if (_currentOrder?.id == id) _currentOrder = result;
      notifyListeners();

      return true;
    } catch (e) {
      // Revert optimistic update
      _orders[idx] = currentOrder;
      _activeOrders = _orders
          .where((o) => o.status != 'delivered' && o.status != 'cancelled')
          .toList();
      if (_currentOrder?.id == id) _currentOrder = currentOrder;
      _handleFailure(ErrorHandler.handleError(e));
      notifyListeners();
      return false;
    } finally {
      _updatingOrderIds.remove(id);
    }
  }

  // ────────────────────────────────────────────────────────────────
  // CANCEL ORDER
  // ────────────────────────────────────────────────────────────────
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
      _handleFailure(ErrorHandler.handleError(e));
      return false;
    }
  }

  // ────────────────────────────────────────────────────────────────
  // FILTROS
  // ────────────────────────────────────────────────────────────────
  List<Order> getOrdersByStatus(String status) =>
      _orders.where((o) => o.status == status).toList();

  List<Order> getOrdersByDate(DateTime date) => _orders
      .where((o) =>
          o.createdAt.year == date.year &&
          o.createdAt.month == date.month &&
          o.createdAt.day == date.day)
      .toList();
}