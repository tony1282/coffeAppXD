// presentation/providers/admin_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/error/error_handler.dart';
import '../../core/error/failure.dart';
import '../../core/utils/logger.dart';
import '../../data/models/order_model.dart';
import '../../data/services/api_service.dart';

class AdminProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  // ============================================================
  // SEGURIDAD Y ROBUSTEZ
  // ============================================================
  static const int _maxOrdersAllowed = 2000;
  static const double _maxOrderTotal = 10000;
  static const Duration _requestTimeout = Duration(seconds: 15);
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  static const List<String> _validStatuses = [
    'pending', 'confirmed', 'preparing', 'shipped', 'delivered', 'cancelled',
  ];

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
  bool isLoading = false;
  double _todaySales = 0;
  int _pendingOrders = 0;
  String? _errorMsg;

  final Set<int> _updatingOrderIds = {};

  List<Order> get orders => List.unmodifiable(_orders);
  double get todaySales => _todaySales;
  int get pendingOrders => _pendingOrders;
  String? get errorMsg => _errorMsg;

  void _clearError() {
    _errorMsg = null;
  }

  void _handleFailure(Failure failure) {
    _errorMsg = failure.message;
    if (kDebugMode) {
      AppLogger.error('AdminProvider: ${failure.message}');
    }
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
  // FETCH
  // ============================================================
  Future<void> fetchAllOrders() async {
    _clearError();
    isLoading = true;
    notifyListeners();

    try {
      final response = await _withNetworkFallback(() => _api.get('/admin/orders'));

      if (response is! List) throw Exception('invalid_response');

      final truncated = response.length > _maxOrdersAllowed
          ? response.sublist(0, _maxOrdersAllowed)
          : response;

      final List<Order> parsed = [];
      for (final item in truncated) {
        if (item is! Map<String, dynamic>) continue;
        try {
          final order = Order.fromJson(item);
          if (order.id != null &&
              order.id! > 0 &&
              order.total >= 0 &&
              order.total <= _maxOrderTotal &&
              _validStatuses.contains(order.status)) {
            parsed.add(order);
          }
        } catch (_) {}
      }

      _orders = parsed;
      _pendingOrders = _orders.where((o) => o.status == 'pending').length;
      _todaySales = _orders
          .where((o) => o.status == 'delivered')
          .fold(0.0, (s, o) => s + (o.total.isFinite ? o.total : 0));

      if (_todaySales.isNaN || _todaySales.isInfinite) _todaySales = 0.0;

      if (kDebugMode) {
        AppLogger.debug('AdminProvider: Admin cargó ${_orders.length} pedidos');
      }
    } catch (e) {
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
      if (kDebugMode) {
        AppLogger.error('AdminProvider: Error cargando pedidos: $e');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================
  Future<bool> updateOrderStatus(int orderId, String status) async {
    _clearError();

    if (orderId <= 0) {
      _errorMsg = 'ID inválido';
      notifyListeners();
      return false;
    }

    final normalized = status.trim().toLowerCase();
    if (!_validStatuses.contains(normalized)) {
      _errorMsg = 'Estado inválido';
      notifyListeners();
      return false;
    }

    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      _errorMsg = 'Pedido no encontrado';
      notifyListeners();
      return false;
    }

    final current = _orders[index];

    if (!(_allowedTransitions[current.status]?.contains(normalized) ?? false)) {
      _errorMsg = 'Transición no permitida: ${current.status} → $normalized';
      notifyListeners();
      return false;
    }

    if (_updatingOrderIds.contains(orderId)) {
      _errorMsg = 'El pedido ya está siendo actualizado';
      notifyListeners();
      return false;
    }

    _updatingOrderIds.add(orderId);

    final originalOrder = current;
    _orders[index] = current.copyWith(status: normalized);
    _pendingOrders = _orders.where((o) => o.status == 'pending').length;
    _todaySales = _orders
        .where((o) => o.status == 'delivered')
        .fold(0.0, (s, o) => s + (o.total.isFinite ? o.total : 0));
    notifyListeners();

    try {
      await _withNetworkFallback(() => _api.patch(
        '/admin/orders/$orderId/status',
        {'status': normalized},
      ));

      if (kDebugMode) {
        AppLogger.debug('AdminProvider: Admin actualizó pedido #$orderId a $normalized');
      }
      return true;
    } catch (e) {
      // Rollback
      _orders[index] = originalOrder;
      _pendingOrders = _orders.where((o) => o.status == 'pending').length;
      _todaySales = _orders
          .where((o) => o.status == 'delivered')
          .fold(0.0, (s, o) => s + (o.total.isFinite ? o.total : 0));
      
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
      if (kDebugMode) {
        AppLogger.error('AdminProvider: Error actualizando pedido #$orderId: $e');
      }
      notifyListeners();
      return false;
    } finally {
      _updatingOrderIds.remove(orderId);
    }
  }

  // ============================================================
  // DASHBOARD
  // ============================================================
  Map<String, dynamic> getDashboardStats() {
    return {
      'totalOrders': _orders.length,
      'pendingOrders': _pendingOrders,
      'todaySales': _todaySales,
      'completedOrders': _orders.where((o) => o.status == 'delivered').length,
    };
  }

  void clear() {
    _updatingOrderIds.clear();
    _orders = [];
    _todaySales = 0;
    _pendingOrders = 0;
    _errorMsg = null;
    notifyListeners();
  }
}