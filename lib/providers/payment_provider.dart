import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/api_service.dart';

class PaymentProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<Payment> _payments = [];
  bool isLoading = false;

  List<Payment> get payments => _payments;

  Future<void> fetchPayments() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get('/payments/my/');
      _payments = (response as List).map((p) => Payment.fromJson(p)).toList();
    } catch (e) {
      print(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createPayment(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/payments/create/', data);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}