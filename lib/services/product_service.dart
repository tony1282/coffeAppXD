// lib/services/product_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../config/api_config.dart';

class ProductService {
  // ── Obtener headers con token ──────────────────────────────────
  Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── GET /products ──────────────────────────────────────────────
  Future<List<Product>> getProducts() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener productos: ${response.statusCode}');
    }
  }

  // ── GET /products/:id ──────────────────────────────────────────
  Future<Product> getProductById(int id) async {  // ← CAMBIADO a int
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/$id'),  // int se convierte solo
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Producto no encontrado: ${response.statusCode}');
    }
  }

  // ── POST /products ─────────────────────────────────────────────
  Future<Product> createProduct(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/products'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
          error['message'] ?? 'Error al crear producto: ${response.statusCode}');
    }
  }

  // ── PUT /products/:id ──────────────────────────────────────────
  Future<Product> updateProduct(int id, Map<String, dynamic> data) async {  // ← CAMBIADO a int
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/products/$id'),  // int se convierte solo
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
          error['message'] ?? 'Error al actualizar producto: ${response.statusCode}');
    }
  }

  // ── DELETE /products/:id ───────────────────────────────────────
  Future<void> deleteProduct(int id) async {  // ← CAMBIADO a int
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/products/$id'),  // int se convierte solo
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar producto: ${response.statusCode}');
    }
  }

  // ── PATCH /products/:id/availability ──────────────────────────
  Future<Product> toggleAvailability(int id, bool available) async {  // ← CAMBIADO a int
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/products/$id/availability'),  // int se convierte solo
      headers: await _getHeaders(),
      body: jsonEncode({'available': available}),
    );

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Error al cambiar disponibilidad: ${response.statusCode}');
    }
  }
}