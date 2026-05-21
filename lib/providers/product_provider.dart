// lib/providers/product_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../utils/logger.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _service = ProductService();

  // ============================================================
  // CONFIGURACIÓN DE SEGURIDAD
  // ============================================================
  static const int _maxProducts = 5000;
  static const double _minValidPrice = 1.0;
  static const double _maxValidPrice = 10000.0;
  static const int _minStock = 0;
  static const int _maxStock = 99999;
  static const Duration _requestTimeout = Duration(seconds: 20);
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  // ============================================================
  // ESTADO
  // ============================================================
  List<Product> products = [];
  bool isLoading = false;
  String? errorMsg;

  // Prevenir race conditions UI
  final Set<int> _updatingProductIds = {};

  List<Product> get productsList => List.unmodifiable(products);

  // ============================================================
  // HELPERS INTERNOS
  // ============================================================
  void _setLoading(bool v) { isLoading = v; notifyListeners(); }
  void _setError(String? msg) { errorMsg = msg; notifyListeners(); }
  void _clearError() { errorMsg = null; }

  String _sanitizeError(dynamic error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('socket') || raw.contains('network')) {
      return 'Sin conexión a internet';
    }
    if (raw.contains('timeout')) {
      return 'La solicitud tardó demasiado';
    }
    if (raw.contains('401') || raw.contains('403')) {
      return 'Tu sesión expiró. Inicia sesión nuevamente';
    }
    if (raw.contains('404')) {
      return 'Producto no encontrado';
    }
    if (raw.contains('duplicate') || raw.contains('already exists')) {
      return 'Ya existe un producto con ese nombre';
    }
    return 'Error inesperado. Intenta de nuevo';
  }

  bool _isValidId(int id) => id > 0;

  bool _isValidPrice(double price) {
    return price >= _minValidPrice && price <= _maxValidPrice;
  }

  bool _isValidStock(int? stock) {
    if (stock == null) return true;
    return stock >= _minStock && stock <= _maxStock;
  }

  bool _isValidName(String name) {
    return name.trim().isNotEmpty && name.length <= 100;
  }

  // ============================================================
  // NETWORK WRAPPER
  // ============================================================
  Future<T> _withNetworkFallback<T>(Future<T> Function() request) async {
    int attempt = 0;
    while (true) {
      try {
        return await request().timeout(_requestTimeout);
      } on TimeoutException {
        if (attempt >= _maxRetries) throw Exception('REQUEST_TIMEOUT');
        await Future.delayed(_retryDelay * (attempt + 1));
        attempt++;
      } on Exception catch (e) {
        final msg = e.toString().toLowerCase();
        if ((msg.contains('socket') || msg.contains('network')) && attempt < _maxRetries) {
          await Future.delayed(_retryDelay * (attempt + 1));
          attempt++;
          continue;
        }
        rethrow;
      }
    }
  }

  // ============================================================
  // GET PRODUCTS
  // ============================================================
  Future<void> fetchProducts() async {
    _clearError();
    _setLoading(true);
    try {
      final fetched = await _withNetworkFallback(() => _service.getProducts());

      // Prevenir memory bombing
      final truncated = fetched.length > _maxProducts
          ? fetched.sublist(0, _maxProducts)
          : fetched;

      products = truncated;
      notifyListeners();

      if (kDebugMode) {
        AppLogger.debug('Cargados ${products.length} productos');
      }
    } catch (e) {
      _setError(_sanitizeError(e));
      if (kDebugMode) AppLogger.error('Error cargando productos', e);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // CREATE PRODUCT
  // ============================================================
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

    // Validaciones en frontend (UX + reducción de tráfico basura)
    if (!_isValidName(name)) {
      _setError('Nombre de producto inválido');
      _setLoading(false);
      return false;
    }

    if (!_isValidPrice(price)) {
      _setError('Precio debe estar entre \$${_minValidPrice.toStringAsFixed(2)} y \$${_maxValidPrice.toStringAsFixed(2)}');
      _setLoading(false);
      return false;
    }

    if (!_isValidStock(stock)) {
      _setError('Stock inválido');
      _setLoading(false);
      return false;
    }

    try {
      final newProduct = await _withNetworkFallback(() => _service.createProduct({
        'name': name.trim(),
        'description': description.trim(),
        'price': price,
        'category': category.trim(),
        'image_url': imageUrl,
        'available': available,
        if (stock != null) 'stock': stock,
      }));

      products.insert(0, newProduct);
      
      // Mantener límite
      if (products.length > _maxProducts) {
        products = products.sublist(0, _maxProducts);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_sanitizeError(e));
      if (kDebugMode) AppLogger.error('Error creando producto', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // UPDATE PRODUCT
  // ============================================================
  Future<bool> updateProduct({
    required int id,
    required String name,
    required String description,
    required double price,
    required String category,
    required String imageUrl,
    required bool available,
    int? stock,
  }) async {
    _clearError();

    // Validaciones
    if (!_isValidId(id)) {
      _setError('ID de producto inválido');
      return false;
    }

    if (!_isValidName(name)) {
      _setError('Nombre de producto inválido');
      return false;
    }

    if (!_isValidPrice(price)) {
      _setError('Precio inválido');
      return false;
    }

    if (!_isValidStock(stock)) {
      _setError('Stock inválido');
      return false;
    }

    // Prevenir race conditions
    if (_updatingProductIds.contains(id)) {
      _setError('El producto ya está siendo actualizado');
      return false;
    }

    _updatingProductIds.add(id);

    // Buscar índice actual
    final idx = products.indexWhere((p) => p.id == id);
    if (idx == -1) {
      _setError('Producto no encontrado');
      _updatingProductIds.remove(id);
      return false;
    }

    // Snapshot para rollback
    final originalProduct = products[idx];

    _setLoading(true);

    try {
      final updated = await _withNetworkFallback(() => _service.updateProduct(id, {
        'name': name.trim(),
        'description': description.trim(),
        'price': price,
        'category': category.trim(),
        'image_url': imageUrl,
        'available': available,
        if (stock != null) 'stock': stock,
      }));

      products[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      // Rollback
      products[idx] = originalProduct;
      _setError(_sanitizeError(e));
      if (kDebugMode) AppLogger.error('Error actualizando producto #$id', e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
      _updatingProductIds.remove(id);
    }
  }

  // ============================================================
  // DELETE PRODUCT
  // ============================================================
  Future<bool> deleteProduct(int id) async {
    _clearError();

    if (!_isValidId(id)) {
      _setError('ID de producto inválido');
      return false;
    }

    // Guardar para rollback
    final originalList = List<Product>.from(products);
    final wasRemoved = products.any((p) => p.id == id);

    if (!wasRemoved) {
      _setError('Producto no encontrado');
      return false;
    }

    products.removeWhere((p) => p.id == id);
    
    notifyListeners();
    _setLoading(true);

    try {
      await _withNetworkFallback(() => _service.deleteProduct(id));
      return true;
    } catch (e) {
      // Rollback
      products = originalList;
      _setError(_sanitizeError(e));
      if (kDebugMode) AppLogger.error('Error eliminando producto #$id', e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // TOGGLE AVAILABILITY
  // ============================================================
  Future<bool> toggleAvailability(int id, bool available) async {
    _clearError();

    if (!_isValidId(id)) {
      _setError('ID de producto inválido');
      return false;
    }

    final idx = products.indexWhere((p) => p.id == id);
    if (idx == -1) {
      _setError('Producto no encontrado');
      return false;
    }

    final originalProduct = products[idx];
    
    // Optimistic update
    final updatedProduct = originalProduct.copyWith(available: available);
    products[idx] = updatedProduct;
    notifyListeners();

    try {
      final result = await _withNetworkFallback(() => _service.toggleAvailability(id, available));
      
      // Actualizar con respuesta del servidor
      final finalIdx = products.indexWhere((p) => p.id == id);
      if (finalIdx != -1) products[finalIdx] = result;
      notifyListeners();
      return true;
    } catch (e) {
      // Rollback
      products[idx] = originalProduct;
      _setError(_sanitizeError(e));
      if (kDebugMode) AppLogger.error('Error cambiando disponibilidad del producto #$id', e);
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // FILTROS DE CONVENIENCIA (EXISTENTES)
  // ============================================================
  List<Product> get availableProducts =>
      products.where((p) => p.available).toList();

  List<Product> byCategory(String category) =>
      products.where((p) => p.category == category).toList();

  List<String> get categories =>
      products.map((p) => p.category).toSet().toList()..sort();

  // ============================================================
  // ✅ NUEVOS MÉTODOS PARA AUDITORÍA Y ORDENAMIENTO
  // ============================================================

  // ✅ Productos ordenados por fecha de creación (más recientes primero)
  List<Product> get productsNewestFirst {
    return [...products]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ✅ Productos ordenados por fecha de creación (más antiguos primero)
  List<Product> get productsOldestFirst {
    return [...products]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  // ✅ Productos actualizados recientemente
  List<Product> get recentlyUpdated {
    final updated = products.where((p) => p.updatedAt != null).toList();
    return updated..sort((a, b) => (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt));
  }

  // ✅ Productos más nuevos (alias para productsNewestFirst)
  List<Product> get newestProducts => productsNewestFirst;

  // ✅ Productos más vendidos
  List<Product> get bestSellingProducts {
    return [...products]..sort((a, b) => (b.totalSold ?? 0).compareTo(a.totalSold ?? 0));
  }

  // ✅ Productos con stock bajo (<= 5 unidades y > 0)
  List<Product> get lowStockProducts {
    return products.where((p) => p.stock != null && p.stock! <= 5 && p.stock! > 0).toList();
  }

  // ✅ Productos agotados (stock == 0)
  List<Product> get outOfStockProducts {
    return products.where((p) => p.stock != null && p.stock! <= 0).toList();
  }

  // ✅ Productos disponibles en inventario (available = true y stock > 0 o stock null)
  List<Product> get inStockProducts {
    return products.where((p) => p.available && (p.stock == null || p.stock! > 0)).toList();
  }

  // ✅ Productos creados en los últimos N días
  List<Product> getProductsCreatedInLastDays(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return products.where((p) => p.createdAt.isAfter(cutoff)).toList();
  }

  // ✅ Productos actualizados en los últimos N días
  List<Product> getProductsUpdatedInLastDays(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return products.where((p) => p.updatedAt != null && p.updatedAt!.isAfter(cutoff)).toList();
  }
}