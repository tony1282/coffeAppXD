// data/models/product_model.dart

import 'package:flutter/foundation.dart';
import '../../core/error/error_messages.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/validators.dart';

class ProductModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final bool available;
  final int? stock;
  final int? totalSold;
  final DateTime createdAt;
  final DateTime? updatedAt;

  static const double _minValidPrice = 1.0;
  static const double _maxValidPrice = 10000.0;
  static const int _maxNameLength = 100;
  static const int _maxDescriptionLength = 2000;
  static const int _maxCategoryLength = 50;
  static const int _maxImageUrlLength = 500;
  static const int _minStock = 0;
  static const int _maxStock = 99999;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    this.available = true,
    this.stock,
    this.totalSold,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // id
    final id = json['id'];
    if (id == null || (id is! int && int.tryParse(id.toString()) == null)) {
      if (kDebugMode) AppLogger.debug('ProductModel: id inválido');
      throw FormatException(ErrorMessages.invalidResponse);
    }
    final parsedId = id is int ? id : int.parse(id.toString());

    // name - usando Validators
    final name = json['name']?.toString().trim() ?? '';
    if (name.isEmpty || name.length > _maxNameLength) {
      if (kDebugMode) AppLogger.debug('ProductModel: name inválido');
      throw FormatException(ErrorMessages.invalidResponse);
    }

    // price
    final price = json['price'];
    double parsedPrice;
    if (price is int) {
      parsedPrice = price.toDouble();
    } else if (price is double) {
      parsedPrice = price;
    } else if (price is String) {
      parsedPrice = double.tryParse(price) ?? _minValidPrice;
    } else {
      parsedPrice = _minValidPrice;
    }
    if (parsedPrice < _minValidPrice || parsedPrice > _maxValidPrice) {
      if (kDebugMode) AppLogger.debug('ProductModel: price inválido');
    }

    // description
    final description = json['description']?.toString().trim() ?? '';
    if (description.length > _maxDescriptionLength) {
      if (kDebugMode) AppLogger.debug('ProductModel: description demasiado larga');
    }

    // category
    final category = json['category']?.toString().trim() ?? 'Sin categoría';
    if (category.length > _maxCategoryLength) {
      if (kDebugMode) AppLogger.debug('ProductModel: category demasiado larga');
    }

    // imageUrl
    final imageUrl = json['image_url'] ?? json['imgUrl'] ?? '';
    if (imageUrl.toString().length > _maxImageUrlLength) {
      if (kDebugMode) AppLogger.debug('ProductModel: imageUrl demasiado larga');
    }

    // stock
    int? parsedStock;
    final stock = json['stock'];
    if (stock != null) {
      if (stock is int) {
        parsedStock = stock.clamp(_minStock, _maxStock);
      } else if (stock is String) {
        parsedStock = int.tryParse(stock);
        if (parsedStock != null) {
          parsedStock = parsedStock.clamp(_minStock, _maxStock);
        }
      }
    }

    // available
    final available = json['available'] is bool ? json['available'] : true;

    // totalSold
    int? parsedTotalSold;
    final totalSold = json['total_sold'];
    if (totalSold != null) {
      if (totalSold is int) {
        parsedTotalSold = totalSold;
      } else if (totalSold is String) {
        parsedTotalSold = int.tryParse(totalSold);
      }
      if (parsedTotalSold != null && parsedTotalSold < 0) {
        parsedTotalSold = 0;
      }
    }

    // dates
    DateTime parsedCreatedAt;
    final createdAtStr = json['created_at'];
    if (createdAtStr != null) {
      try {
        parsedCreatedAt = DateTime.parse(createdAtStr.toString());
      } catch (_) {
        parsedCreatedAt = DateTime.now();
        if (kDebugMode) AppLogger.debug('ProductModel: created_at inválido');
      }
    } else {
      parsedCreatedAt = DateTime.now();
    }

    DateTime? parsedUpdatedAt;
    final updatedAtStr = json['updated_at'];
    if (updatedAtStr != null) {
      try {
        parsedUpdatedAt = DateTime.parse(updatedAtStr.toString());
      } catch (_) {
        if (kDebugMode) AppLogger.debug('ProductModel: updated_at inválido');
      }
    }

    return ProductModel(
      id: parsedId,
      name: name,
      description: description,
      price: parsedPrice,
      category: category,
      imageUrl: imageUrl.toString(),
      available: available,
      stock: parsedStock,
      totalSold: parsedTotalSold,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image_url': imageUrl,
      'available': available,
      if (stock != null) 'stock': stock,
      if (totalSold != null) 'total_sold': totalSold,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ProductModel copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    bool? available,
    int? stock,
    int? totalSold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      available: available ?? this.available,
      stock: stock ?? this.stock,
      totalSold: totalSold ?? this.totalSold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}