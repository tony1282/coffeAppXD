import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

class AdminProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<Order> _orders = [];
  bool isLoading = false;
  double _todaySales = 0;
  int _pendingOrders = 0;

  List<Order> get orders => _orders;
  double get todaySales => _todaySales;
  int get pendingOrders => _pendingOrders;

  Future<void> fetchAllOrders() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get('/orders/');
      _orders = (response as List).map((o) => Order.fromJson(o)).toList();
      _pendingOrders = _orders.where((o) => o.status == 'pending').length;
      _todaySales = _orders
          .where((o) => o.status == 'delivered')
          .fold(0.0, (sum, o) => sum + o.total);
    } catch (e) {
      print(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      await _api.patch('/orders/$orderId/status/', {'status': status});
      await fetchAllOrders();
    } catch (e) {
      rethrow;
    }
  }
}