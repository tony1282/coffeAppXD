// lib/services/order_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import '../models/order_model.dart';

class OrderService {
  Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── GET /orders ──────────────────────────────────────────────
  Future<List<Order>> getOrders() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/orders'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener pedidos: ${response.statusCode}');
    }
  }

  // ── GET /orders/:id ──────────────────────────────────────────
  Future<Order> getOrderById(int id) async {  // ← CAMBIADO a int
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/orders/$id'),  // int funciona
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Pedido no encontrado: ${response.statusCode}');
    }
  }

  // ── POST /orders ─────────────────────────────────────────────
  Future<Order> createOrder(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/orders'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Error al crear pedido: ${response.statusCode}');
    }
  }

  // ── PATCH /orders/:id/status ─────────────────────────────────
  Future<Order> updateOrderStatus(int id, String status) async {  // ← CAMBIADO a int
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/orders/$id/status'),  // int funciona
      headers: await _getHeaders(),
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al actualizar estado: ${response.statusCode}');
    }
  }

  // ── DELETE /orders/:id ───────────────────────────────────────
  Future<void> cancelOrder(int id) async {  // ← CAMBIADO a int
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/orders/$id'),  // int funciona
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al cancelar pedido: ${response.statusCode}');
    }
  }
}