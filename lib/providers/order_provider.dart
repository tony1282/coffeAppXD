// lib/providers/order_provider.dart

import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _service = OrderService();

  List<Order> _orders = [];
  List<Order> _activeOrders = [];
  Order? _currentOrder;
  bool isLoading = false;
  String? errorMsg;

  List<Order> get orders => _orders;
  List<Order> get activeOrders => _activeOrders;
  Order? get currentOrder => _currentOrder;

  void _setLoading(bool v) { isLoading = v; notifyListeners(); }
  void _setError(String? msg) { errorMsg = msg; notifyListeners(); }

  // ── FETCH todos los pedidos ───────────────────────────────────
  Future<void> fetchOrders() async {
    _setLoading(true);
    _setError(null);
    
    try {
      _orders = await _service.getOrders();
      _activeOrders = _orders.where((o) => 
          o.status != 'delivered' && o.status != 'cancelled').toList();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ── FETCH un pedido específico ─────────────────────────────────
  Future<void> fetchOrderById(int id) async {  // ← CAMBIADO a int
    _setLoading(true);
    
    try {
      _currentOrder = await _service.getOrderById(id);  // ← int
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ── CREAR pedido ──────────────────────────────────────────────
  Future<bool> createOrder(Map<String, dynamic> orderData) async {
    _setLoading(true);
    
    try {
      final newOrder = await _service.createOrder(orderData);
      _orders.insert(0, newOrder);
      _activeOrders = _orders.where((o) => 
          o.status != 'delivered' && o.status != 'cancelled').toList();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── ACTUALIZAR estado del pedido ──────────────────────────────
  Future<bool> updateOrderStatus(int id, String status) async {  // ← CAMBIADO a int
    try {
      final updated = await _service.updateOrderStatus(id, status);  // ← int
      
      // Actualizar en las listas locales
      final idx = _orders.indexWhere((o) => o.id == id);  // ← int con int (sin .toString())
      if (idx != -1) _orders[idx] = updated;
      
      _activeOrders = _orders.where((o) => 
          o.status != 'delivered' && o.status != 'cancelled').toList();
      
      if (_currentOrder?.id == id) {  // ← int con int
        _currentOrder = updated;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── CANCELAR pedido ───────────────────────────────────────────
  Future<bool> cancelOrder(int id) async {  // ← CAMBIADO a int
    try {
      await _service.cancelOrder(id);  // ← int
      await fetchOrders(); // Recargar lista
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── FILTROS de conveniencia ───────────────────────────────────
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