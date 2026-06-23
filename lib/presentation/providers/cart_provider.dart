// presentation/providers/cart_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/error/error_handler.dart';
import '../../core/error/failure.dart';
import '../../core/utils/logger.dart';
import '../../data/models/product_model.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/services/cart_service.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  final double originalPrice;

  CartItem({
    required this.product,
    required this.quantity,
  }) : originalPrice = product.price;

  double get subtotal => originalPrice * quantity;
}

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  late Box<CartItemModel> _cartBox;
  
  final List<CartItem> _items = [];
  bool _isInitialized = false;
  bool _isSyncing = false;

  // ============================================================
  // CONFIGURACIÓN DE SEGURIDAD
  // ============================================================
  static const int _maxQuantityPerProduct = 50;
  static const int _maxTotalItems = 100;
  static const int _minQuantity = 1;

  List<CartItem> get items => List.unmodifiable(_items);
  List<ProductModel> get products => _items.map((item) => item.product).toList();
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get total => _items.fold(0.0, (sum, item) => sum + item.subtotal);
  bool get isNotEmpty => _items.isNotEmpty;
  bool get isSyncing => _isSyncing;

  void _handleFailure(Failure failure) {
    if (kDebugMode) {
      AppLogger.error('CartProvider', failure.message);
    }
  }

  // ============================================================
  // INICIALIZACIÓN
  // ============================================================
  Future<void> init() async {
    _cartBox = await Hive.openBox<CartItemModel>('cart');
    _loadFromLocal();
    _isInitialized = true;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await syncWithBackend();
    }
  }

  void _loadFromLocal() {
    final localItems = _cartBox.values.toList();
    if (localItems.isEmpty) return;
    
    for (final item in localItems) {
      final product = ProductModel(
        id: item.productId,
        name: item.productName,
        description: '',
        price: item.price,
        category: '',
        imageUrl: item.imageUrl,
        available: true,
        stock: null,
        createdAt: DateTime.now(),
      );
      _items.add(CartItem(product: product, quantity: item.quantity));
    }
    notifyListeners();
  }

  void _saveToLocal() {
    if (!_isInitialized) return;
    
    _cartBox.clear();
    for (final item in _items) {
      final cartItemModel = CartItemModel(
        productId: item.product.id,
        productName: item.product.name,
        price: item.originalPrice,
        quantity: item.quantity,
        imageUrl: item.product.imageUrl,
      );
      _cartBox.add(cartItemModel);
    }
  }

  // ============================================================
  // SINCRONIZACIÓN CON BACKEND
  // ============================================================
  Future<void> syncWithBackend() async {
    if (!_isInitialized) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    if (_isSyncing) return;
    _isSyncing = true;
    
    try {
      final remoteItems = await _cartService.getCart();
      
      final mergedItems = _mergeCartItems(_items, remoteItems);
      
      _items.clear();
      _items.addAll(mergedItems);
      _saveToLocal();
      notifyListeners();
      
      await _cartService.syncCart(_items.map((item) => CartItemModel(
        productId: item.product.id,
        productName: item.product.name,
        price: item.originalPrice,
        quantity: item.quantity,
        imageUrl: item.product.imageUrl,
      )).toList());
      
    } catch (e) {
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
      if (kDebugMode) {
        AppLogger.error('CartProvider', 'Sync error: $e');
      }
    } finally {
      _isSyncing = false;
    }
  }

  List<CartItem> _mergeCartItems(
    List<CartItem> local,
    List<CartItemModel> remote,
  ) {
    final Map<int, CartItem> merged = {};
    
    for (final item in local) {
      merged[item.product.id] = item;
    }
    
    for (final remoteItem in remote) {
      if (!merged.containsKey(remoteItem.productId)) {
        final product = ProductModel(
          id: remoteItem.productId,
          name: remoteItem.productName,
          description: '',
          price: remoteItem.price,
          category: '',
          imageUrl: remoteItem.imageUrl,
          available: true,
          stock: null,
          createdAt: DateTime.now(),
        );
        merged[remoteItem.productId] = CartItem(
          product: product,
          quantity: remoteItem.quantity,
        );
      }
    }
    
    return merged.values.toList();
  }

  void _syncWithBackendBackground() {
    if (!_isInitialized) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    Future.microtask(() => syncWithBackend());
  }

  // ============================================================
  // ADD
  // ============================================================
  void add(ProductModel product) {
    if (product.id <= 0) return;
    if (!product.available) return;
    if (product.stock != null && product.stock! <= 0) return;

    _addWithLock(product);
  }

  void _addWithLock(ProductModel product) {
    Timer.run(() {
      final existingIndex = _items.indexWhere((item) => item.product.id == product.id);

      if (existingIndex != -1) {
        final currentQty = _items[existingIndex].quantity;
        if (currentQty >= _maxQuantityPerProduct) return;
        
        final newQty = currentQty + 1;
        if (product.stock != null && newQty > product.stock!) return;
        
        _items[existingIndex] = CartItem(
          product: product,
          quantity: newQty,
        );
      } else {
        if (_items.length >= _maxTotalItems) return;
        if (product.stock != null && product.stock! < 1) return;
        
        _items.add(CartItem(product: product, quantity: 1));
      }
      
      _saveToLocal();
      notifyListeners();
      _syncWithBackendBackground();
    });
  }

  // ============================================================
  // REMOVE
  // ============================================================
  void remove(ProductModel product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      _items.removeAt(index);
      _saveToLocal();
      notifyListeners();
      _syncWithBackendBackground();
    }
  }

  // ============================================================
  // UPDATE QUANTITY
  // ============================================================
  void updateQuantity(ProductModel product, int quantity) {
    if (quantity < _minQuantity) {
      remove(product);
      return;
    }

    if (quantity > _maxQuantityPerProduct) {
      quantity = _maxQuantityPerProduct;
    }

    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index == -1) return;

    if (product.stock != null && quantity > product.stock!) {
      quantity = product.stock!;
      if (quantity < _minQuantity) {
        remove(product);
        return;
      }
    }

    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = CartItem(
        product: product,
        quantity: quantity,
      );
    }
    
    _saveToLocal();
    notifyListeners();
    _syncWithBackendBackground();
  }

  // ============================================================
  // CLEAR
  // ============================================================
  void clear() {
    _items.clear();
    _saveToLocal();
    notifyListeners();
    _syncWithBackendBackground();
  }

  // ============================================================
  // VALIDACIÓN PARA CHECKOUT
  // ============================================================
  bool validateForCheckout() {
    for (final item in _items) {
      if (!item.product.available) return false;
      if (item.product.stock != null && item.quantity > item.product.stock!) {
        return false;
      }
      if (item.subtotal != item.product.price * item.quantity) {
        return false;
      }
    }
    return true;
  }
}