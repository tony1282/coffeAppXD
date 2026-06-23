// presentation/providers/product_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/error/error_handler.dart';
import '../../core/error/failure.dart';
import '../../core/utils/logger.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/repositories/product_repository.dart';
import '../../data/datasources/remote/product_remote_datasource.dart';
import '../../data/datasources/local/product_local_datasource.dart';

class ProductProvider with ChangeNotifier {
  late final ProductRepository _repository;

  static const int _maxProducts = 5000;
  static const int _minStock = 0;
  static const int _maxStock = 99999;

  List<ProductModel> products = [];
  bool isLoading = false;
  String? errorMsg;
  final Set<int> _updatingProductIds = {};

  List<ProductModel> get productsList => List.unmodifiable(products);

  ProductProvider({ProductRepository? repository, bool enableCache = false}) {
    if (repository != null) {
      _repository = repository;
    } else {
      final remoteDataSource = ProductRemoteDataSource();
      final localDataSource = enableCache ? ProductLocalDataSource() : null;
      _repository = ProductRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
    }
  }

  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    errorMsg = msg;
    notifyListeners();
  }

  void _clearError() {
    errorMsg = null;
  }

  void _handleFailure(Failure failure) {
    _setError(failure.message);
    if (kDebugMode) {
      AppLogger.error('ProductProvider: ${failure.message}');
    }
  }

  bool _isValidId(int id) => id > 0;
  bool _isValidName(String name) => name.trim().isNotEmpty && name.length <= 100;

  // ============================================================
  // GET PRODUCTS
  // ============================================================
  Future<void> fetchProducts() async {
    _clearError();
    _setLoading(true);

    try {
      final entities = await _repository.getProducts();
      products = entities.map((entity) => ProductModel(
        id: entity.id,
        name: entity.name,
        description: entity.description,
        price: entity.price,
        category: entity.category,
        imageUrl: entity.imageUrl,
        available: entity.available,
        stock: entity.stock,
        totalSold: entity.totalSold,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      )).toList();

      if (products.length > _maxProducts) {
        products = products.sublist(0, _maxProducts);
      }

      notifyListeners();
      if (kDebugMode) {
      AppLogger.debug('ProductProvider: Cargados ${products.length} productos');
      }
    } catch (e) {
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
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

    if (!_isValidName(name)) {
      _setError('Nombre de producto inválido');
      return false;
    }
    if (price <= 0 || price >= 10000) {
      _setError('Precio inválido');
      return false;
    }
    if (stock != null && (stock < _minStock || stock > _maxStock)) {
      _setError('Stock inválido');
      return false;
    }

    _setLoading(true);

    try {
      final entity = await _repository.createProduct({
        'name': name.trim(),
        'description': description.trim(),
        'price': price,
        'category': category.trim(),
        'image_url': imageUrl,
        'available': available,
        if (stock != null) 'stock': stock,
      });

      products.insert(0, ProductModel(
        id: entity.id,
        name: entity.name,
        description: entity.description,
        price: entity.price,
        category: entity.category,
        imageUrl: entity.imageUrl,
        available: entity.available,
        stock: entity.stock,
        totalSold: entity.totalSold,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      ));

      if (products.length > _maxProducts) {
        products = products.sublist(0, _maxProducts);
      }

      notifyListeners();
      return true;
    } catch (e) {
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
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

    if (!_isValidId(id)) {
      _setError('ID de producto inválido');
      return false;
    }
    if (!_isValidName(name)) {
      _setError('Nombre de producto inválido');
      return false;
    }
    if (price <= 0 || price >= 10000) {
      _setError('Precio inválido');
      return false;
    }
    if (stock != null && (stock < _minStock || stock > _maxStock)) {
      _setError('Stock inválido');
      return false;
    }

    if (_updatingProductIds.contains(id)) {
      _setError('El producto ya está siendo actualizado');
      return false;
    }

    _updatingProductIds.add(id);

    final idx = products.indexWhere((p) => p.id == id);
    if (idx == -1) {
      _setError('Producto no encontrado');
      _updatingProductIds.remove(id);
      return false;
    }

    final originalProduct = products[idx];
    _setLoading(true);

    try {
      final entity = await _repository.updateProduct(id, {
        'name': name.trim(),
        'description': description.trim(),
        'price': price,
        'category': category.trim(),
        'image_url': imageUrl,
        'available': available,
        if (stock != null) 'stock': stock,
      });

      products[idx] = ProductModel(
        id: entity.id,
        name: entity.name,
        description: entity.description,
        price: entity.price,
        category: entity.category,
        imageUrl: entity.imageUrl,
        available: entity.available,
        stock: entity.stock,
        totalSold: entity.totalSold,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );

      notifyListeners();
      return true;
    } catch (e) {
      products[idx] = originalProduct;
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
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

    final originalList = List<ProductModel>.from(products);
    final wasRemoved = products.any((p) => p.id == id);

    if (!wasRemoved) {
      _setError('Producto no encontrado');
      return false;
    }

    products.removeWhere((p) => p.id == id);
    notifyListeners();
    _setLoading(true);

    try {
      await _repository.deleteProduct(id);
      return true;
    } catch (e) {
      products = originalList;
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
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
    products[idx] = originalProduct.copyWith(available: available);
    notifyListeners();

    try {
      final entity = await _repository.toggleAvailability(id, available);
      products[idx] = ProductModel(
        id: entity.id,
        name: entity.name,
        description: entity.description,
        price: entity.price,
        category: entity.category,
        imageUrl: entity.imageUrl,
        available: entity.available,
        stock: entity.stock,
        totalSold: entity.totalSold,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );
      notifyListeners();
      return true;
    } catch (e) {
      products[idx] = originalProduct;
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
      return false;
    }
  }

  // ============================================================
  // FILTROS DE CONVENIENCIA
  // ============================================================
  List<ProductModel> get availableProducts => products.where((p) => p.available).toList();
  List<ProductModel> byCategory(String category) => products.where((p) => p.category == category).toList();
  List<String> get categories => products.map((p) => p.category).toSet().toList()..sort();
  List<ProductModel> get productsNewestFirst => [...products]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  List<ProductModel> get productsOldestFirst => [...products]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  List<ProductModel> get recentlyUpdated => products.where((p) => p.updatedAt != null).toList()..sort((a, b) => (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt));
  List<ProductModel> get newestProducts => productsNewestFirst;
  List<ProductModel> get bestSellingProducts => [...products]..sort((a, b) => (b.totalSold ?? 0).compareTo(a.totalSold ?? 0));
  List<ProductModel> get lowStockProducts => products.where((p) => p.stock != null && p.stock! <= 5 && p.stock! > 0).toList();
  List<ProductModel> get outOfStockProducts => products.where((p) => p.stock != null && p.stock! <= 0).toList();
  List<ProductModel> get inStockProducts => products.where((p) => p.available && (p.stock == null || p.stock! > 0)).toList();
  List<ProductModel> getProductsCreatedInLastDays(int days) => products.where((p) => p.createdAt.isAfter(DateTime.now().subtract(Duration(days: days)))).toList();
  List<ProductModel> getProductsUpdatedInLastDays(int days) => products.where((p) => p.updatedAt != null && p.updatedAt!.isAfter(DateTime.now().subtract(Duration(days: days)))).toList();
}