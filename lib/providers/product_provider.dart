// lib/providers/product_provider.dart

import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _service = ProductService();

  List<Product> products = [];
  bool isLoading = false;
  String? errorMsg;

  // ── Helpers internos ───────────────────────────────────────────
  void _setLoading(bool v) { isLoading = v; notifyListeners(); }
  void _setError(String? msg) { errorMsg = msg; notifyListeners(); }
  void _clearError() { errorMsg = null; }

  // ── GET todos los productos ────────────────────────────────────
  Future<void> fetchProducts() async {
    _clearError();
    _setLoading(true);
    try {
      products = await _service.getProducts();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ── CREAR producto ─────────────────────────────────────────────
  Future<bool> createProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required String imageUrl,
    bool available = true,
    int? stock,
  }) async {
    _clearError();
    _setLoading(true);
    try {
      final newProduct = await _service.createProduct({
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'image_url': imageUrl,
        'available': available,
        if (stock != null) 'stock': stock,
      });
      products.add(newProduct);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── ACTUALIZAR producto ────────────────────────────────────────
  Future<bool> updateProduct({
    required int id,  // ← CAMBIADO a int
    required String name,
    required String description,
    required double price,
    required String category,
    required String imageUrl,
    required bool available,
    int? stock,
  }) async {
    _clearError();
    _setLoading(true);
    try {
      final updated = await _service.updateProduct(id, {  // ← int
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'image_url': imageUrl,
        'available': available,
        if (stock != null) 'stock': stock,
      });

      // Reemplaza en la lista local
      final idx = products.indexWhere((p) => p.id == id);  // ← int con int
      if (idx != -1) products[idx] = updated;

      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── ELIMINAR producto ──────────────────────────────────────────
  Future<bool> deleteProduct(int id) async {  // ← CAMBIADO a int
    _clearError();
    _setLoading(true);
    try {
      await _service.deleteProduct(id);  // ← int
      products.removeWhere((p) => p.id == id);  // ← int
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── TOGGLE disponibilidad ──────────────────────────────────────
  Future<bool> toggleAvailability(int id, bool available) async {  // ← CAMBIADO a int
    _clearError();
    try {
      final updated = await _service.toggleAvailability(id, available);  // ← int
      final idx = products.indexWhere((p) => p.id == id);  // ← int
      if (idx != -1) products[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── Filtros de conveniencia ────────────────────────────────────
  List<Product> get availableProducts =>
      products.where((p) => p.available).toList();

  List<Product> byCategory(String category) =>
      products.where((p) => p.category == category).toList();

  List<String> get categories =>
      products.map((p) => p.category).toSet().toList()..sort();
}