// data/models/cart_item_model.dart

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../core/error/error_messages.dart';
import '../../core/utils/logger.dart';

part 'cart_item_model.g.dart';

@HiveType(typeId: 0)
class CartItemModel {
  @HiveField(0)
  final int productId;
  
  @HiveField(1)
  final String productName;
  
  @HiveField(2)
  final double price;
  
  @HiveField(3)
  final int quantity;
  
  @HiveField(4)
  final String imageUrl;

  static const int _minProductId = 1;
  static const double _minPrice = 0.01;
  static const double _maxPrice = 10000.0;
  static const int _minQuantity = 1;
  static const int _maxQuantity = 999;
  static const int _maxProductNameLength = 100;
  static const int _maxImageUrlLength = 500;

  CartItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  }) {
    // Validaciones en constructor (defensivo)
    _validate();
  }

  void _validate() {
    if (productId < _minProductId) {
      if (kDebugMode) {
        AppLogger.debug('CartItemModel: productId inválido ($productId)');
      }
    }

    if (productName.trim().isEmpty || productName.length > _maxProductNameLength) {
      if (kDebugMode) {
        AppLogger.debug('CartItemModel: productName inválido');
      }
    }

    if (price < _minPrice || price > _maxPrice) {
      if (kDebugMode) {
        AppLogger.debug('CartItemModel: price inválido ($price)');
      }
    }

    if (quantity < _minQuantity || quantity > _maxQuantity) {
      if (kDebugMode) {
        AppLogger.debug('CartItemModel: quantity inválido ($quantity)');
      }
    }

    if (imageUrl.length > _maxImageUrlLength) {
      if (kDebugMode) {
        AppLogger.debug('CartItemModel: imageUrl demasiado largo');
      }
    }
  }

  CartItemModel copyWith({
    int? productId,
    String? productName,
    double? price,
    int? quantity,
    String? imageUrl,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() {
    return 'CartItemModel(productId: $productId, productName: $productName, price: $price, quantity: $quantity)';
  }
}