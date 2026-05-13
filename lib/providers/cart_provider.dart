import 'package:flutter/material.dart';
import '../models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  
  // 🔥 Método para obtener lista de productos (para compatibilidad)
  List<Product> get products => _items.map((item) => item.product).toList();
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get total => _items.fold(0, (sum, item) => sum + item.subtotal);
  
  bool get isNotEmpty => _items.isNotEmpty;

  // 🔥 Método add que acepta Product
  void add(Product product) {
    final existing = _items.firstWhere(
      (item) => item.product.id == product.id,
      orElse: () => CartItem(product: product, quantity: 0),
    );
    
    if (existing.quantity == 0) {
      _items.add(CartItem(product: product));
    } else {
      existing.quantity++;
    }
    notifyListeners();
  }

  void remove(Product product) {
    _items.removeWhere((item) => item.product.id == product.id);
    notifyListeners();
  }

  void updateQuantity(Product product, int quantity) {
    final item = _items.firstWhere((item) => item.product.id == product.id);
    if (quantity <= 0) {
      _items.remove(item);
    } else {
      item.quantity = quantity;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}