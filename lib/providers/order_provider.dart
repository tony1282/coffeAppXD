import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _service = OrderService();

  // ============================================================
  // CONFIGURACIÓN DE SEGURIDAD
  // ============================================================
  static const int _maxOrders = 2000;
  static const Duration _requestTimeout = Duration(seconds: 20);
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  static const List<String> _validStatuses = [
    'pending', 'confirmed', 'preparing', 'shipped', 'delivered', 'cancelled'
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
  List<Order> _activeOrders = [];
  Order? _currentOrder;
  bool isLoading = false;
  String? errorMsg;

  // Prevenir race conditions UI
  final Set<int> _updatingOrderIds = {};

  List<Order> get orders => List.unmodifiable(_orders);
  List<Order> get activeOrders => List.unmodifiable(_activeOrders);
  Order? get currentOrder => _currentOrder;

  void _setLoading(bool v) { isLoading = v; notifyListeners(); }
  void _setError(String? msg) { errorMsg = msg; notifyListeners(); }

  String _sanitizeError(dynamic error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('socket') || raw.contains('network')) return 'Sin conexión a internet';
    if (raw.contains('timeout')) return 'Tiempo de espera agotado';
    if (raw.contains('401') || raw.contains('403')) return 'Sesión expirada';
    if (raw.contains('404')) return 'Pedido no encontrado';
    return 'Error inesperado';
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
  // FETCH ORDERS
  // ============================================================
Future<void> fetchOrders() async {
  _setLoading(true);
  _setError(null);
  
  print('📦 [OrderProvider] fetchOrders - INICIO');

  try {
    final fetched = await _withNetworkFallback(() => _service.getOrders());
    print('📦 [OrderProvider] fetched count: ${fetched.length}');
    
    // Mostrar primeros 2 pedidos para debug
    if (fetched.isNotEmpty) {
      print('📦 [OrderProvider] Primer pedido: ${fetched.first.id} - ${fetched.first.status}');
      print('📦 [OrderProvider] Items del primer pedido: ${fetched.first.items.length}');
    }

    final truncated = fetched.length > _maxOrders
        ? fetched.sublist(0, _maxOrders)
        : fetched;

    _orders = truncated;
    _activeOrders = _orders.where((o) =>
        o.status != 'delivered' && o.status != 'cancelled').toList();
    
    print('📦 [OrderProvider] _orders final length: ${_orders.length}');
    print('📦 [OrderProvider] _activeOrders final length: ${_activeOrders.length}');

    notifyListeners();
  } catch (e) {
    print('❌ [OrderProvider] Error: $e');
    _setError(_sanitizeError(e));
  } finally {
    _setLoading(false);
    print('📦 [OrderProvider] fetchOrders - FIN');
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
      _setError(_sanitizeError(e));
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // CREATE ORDER
  // ============================================================
  Future<bool> createOrder(Map<String, dynamic> orderData) async {
    _setLoading(true);

    try {
      final newOrder = await _withNetworkFallback(() => _service.createOrder(orderData));

      _orders.insert(0, newOrder);
      _activeOrders = _orders.where((o) =>
          o.status != 'delivered' && o.status != 'cancelled').toList();

      notifyListeners();
      return true;
    } catch (e) {
      _setError(_sanitizeError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // UPDATE ORDER STATUS
  // ============================================================
  Future<bool> updateOrderStatus(int id, String status) async {
    if (!_isValidOrderId(id)) {
      _setError('ID de pedido inválido');
      return false;
    }

    final normalizedStatus = status.trim().toLowerCase();

    if (!_isValidStatus(normalizedStatus)) {
      _setError('Estado inválido');
      return false;
    }

    // Buscar orden actual
    final idx = _orders.indexWhere((o) => o.id == id);
    if (idx == -1) {
      _setError('Pedido no encontrado');
      return false;
    }

    final currentOrder = _orders[idx];

    if (!_isValidTransition(currentOrder.status, normalizedStatus)) {
      _setError('No se puede cambiar de ${currentOrder.status} a $normalizedStatus');
      return false;
    }

    // Prevenir race conditions UI
    if (_updatingOrderIds.contains(id)) {
      _setError('El pedido ya está siendo actualizado');
      return false;
    }

    _updatingOrderIds.add(id);

    // Snapshot para rollback
    final originalOrder = currentOrder;

    // Optimistic update
    final updatedOrder = currentOrder.copyWith(status: normalizedStatus);
    _orders[idx] = updatedOrder;
    _activeOrders = _orders.where((o) =>
        o.status != 'delivered' && o.status != 'cancelled').toList();
    if (_currentOrder?.id == id) _currentOrder = updatedOrder;
    notifyListeners();

    try {
      final result = await _withNetworkFallback(
        () => _service.updateOrderStatus(id, normalizedStatus)
      );

      // Actualizar con respuesta del server (por si cambió más campos)
      final finalIdx = _orders.indexWhere((o) => o.id == id);
      if (finalIdx != -1) _orders[finalIdx] = result;
      _activeOrders = _orders.where((o) =>
          o.status != 'delivered' && o.status != 'cancelled').toList();
      if (_currentOrder?.id == id) _currentOrder = result;
      notifyListeners();

      return true;
    } catch (e) {
      // Rollback
      _orders[idx] = originalOrder;
      _activeOrders = _orders.where((o) =>
          o.status != 'delivered' && o.status != 'cancelled').toList();
      if (_currentOrder?.id == id) _currentOrder = originalOrder;
      _setError(_sanitizeError(e));
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
      await fetchOrders(); // Recargar lista
      return true;
    } catch (e) {
      _setError(_sanitizeError(e));
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