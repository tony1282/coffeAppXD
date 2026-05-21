// lib/services/cart_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import '../models/cart_item_model.dart';

class CartService {
  Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // GET CART - Obtener carrito del usuario
  // ============================================================
  Future<List<CartItemModel>> getCart() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/cart/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['items'] ?? [];
        
        return items.map((item) => CartItemModel(
          productId: item['product_id'],
          productName: item['product_name'],
          price: (item['price'] as num).toDouble(),
          quantity: item['quantity'],
          imageUrl: item['image_url'] ?? '',
        )).toList();
      }
      return [];
    } catch (e) {
      print('Error getCart: $e');
      return [];
    }
  }

  // ============================================================
  // SYNC CART - Reemplazar todo el carrito (para sincronización inicial)
  // ============================================================
  Future<bool> syncCart(List<CartItemModel> items) async {
    try {
      final body = {
        'items': items.map((item) => {
          'product_id': item.productId,
          'product_name': item.productName,
          'price': item.price,
          'quantity': item.quantity,
          'image_url': item.imageUrl,
        }).toList()
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/cart/sync'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error syncCart: $e');
      return false;
    }
  }

  // ============================================================
  // ADD ITEM - Agregar un producto al carrito
  // ============================================================
  Future<bool> addItem(int productId, int quantity) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/cart/add'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'product_id': productId,
          'quantity': quantity,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error addItem: $e');
      return false;
    }
  }

  // ============================================================
  // UPDATE QUANTITY - Actualizar cantidad de un producto
  // ============================================================
  Future<bool> updateQuantity(int productId, int quantity) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/cart/$productId?quantity=$quantity'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updateQuantity: $e');
      return false;
    }
  }

  // ============================================================
  // REMOVE ITEM - Eliminar un producto del carrito
  // ============================================================
  Future<bool> removeItem(int productId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/cart/$productId'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error removeItem: $e');
      return false;
    }
  }

  // ============================================================
  // CLEAR CART - Vaciar todo el carrito
  // ============================================================
  Future<bool> clearCart() async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/cart/'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error clearCart: $e');
      return false;
    }
  }
}