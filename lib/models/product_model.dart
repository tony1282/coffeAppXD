// lib/models/product_model.dart

import 'package:flutter/foundation.dart';

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final bool available;
  final int? stock;
  final int? totalSold;
  
  // ============================================================
  // ✅ NUEVOS CAMPOS PARA AUDITORÍA
  // ============================================================
  final DateTime createdAt;
  final DateTime? updatedAt;

  // ============================================================
  // CONFIGURACIÓN DE SEGURIDAD
  // ============================================================
  static const double _minValidPrice = 1.0;
  static const double _maxValidPrice = 10000.0;
  static const int _minStock = 0;
  static const int _maxStock = 99999;
  static const int _maxNameLength = 100;
  static const int _maxDescriptionLength = 2000;
  static const int _maxCategoryLength = 50;
  static const int _maxImageUrlLength = 500;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    this.available = true,
    this.stock,
    this.totalSold,
    // ============================================================
    // ✅ NUEVOS PARÁMETROS
    // ============================================================
    required this.createdAt,
    this.updatedAt,
  });

  String get imgUrl => imageUrl;

  // ============================================================
  // VALIDACIONES DEFENSIVAS
  // ============================================================
  static bool _isValidId(dynamic id) {
    if (id == null) return false;
    if (id is int) return id > 0;
    if (id is String) {
      final parsed = int.tryParse(id);
      return parsed != null && parsed > 0;
    }
    return false;
  }

  static bool _isValidName(dynamic name) {
    return name is String &&
        name.trim().isNotEmpty &&
        name.length <= _maxNameLength;
  }

  static bool _isValidDescription(dynamic desc) {
    if (desc == null) return true;
    return desc is String && desc.length <= _maxDescriptionLength;
  }

  static bool _isValidPrice(dynamic price) {
    if (price == null) return false;

    double parsed;

    if (price is int) {
      parsed = price.toDouble();
    } else if (price is double) {
      parsed = price;
    } else if (price is String) {
      parsed = double.tryParse(price) ?? -1;
    } else {
      return false;
    }

    return parsed >= _minValidPrice && parsed <= _maxValidPrice;
  }

  static bool _isValidCategory(dynamic category) {
    if (category == null) return true;
    return category is String && category.length <= _maxCategoryLength;
  }

  static bool _isValidImageUrl(dynamic url) {
    if (url == null) return true;
    return url is String && url.length <= _maxImageUrlLength;
  }

  static bool _isValidStock(dynamic stock) {
    if (stock == null) return true;
    int parsed;
    if (stock is int) {
      parsed = stock;
    } else if (stock is String) {
      parsed = int.tryParse(stock) ?? -1;
    } else {
      return false;
    }
    return parsed >= _minStock && parsed <= _maxStock;
  }

  static bool _isValidAvailable(dynamic available) {
    if (available == null) return true;
    return available is bool;
  }

  // ============================================================
  // ✅ VALIDACIÓN DE FECHAS
  // ============================================================
  static bool _isValidDateTime(dynamic dateTime) {
    if (dateTime == null) return false;
    if (dateTime is DateTime) return true;
    if (dateTime is String) {
      try {
        DateTime.parse(dateTime);
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  // ============================================================
  // FROM JSON (CON VALIDACIONES DEFENSIVAS)
  // ============================================================
  factory Product.fromJson(Map<String, dynamic> json) {
    // ✅ Validación de ID (crítica)
    final id = json['id'];
    if (!_isValidId(id)) {
      if (kDebugMode) print('[Product] ID inválido: $id');
      throw FormatException('ID de producto inválido');
    }

    // ✅ Validación de nombre (crítica)
    final name = json['name'];
    if (!_isValidName(name)) {
      if (kDebugMode) print('[Product] Nombre inválido: $name');
      throw FormatException('Nombre de producto inválido');
    }

    // ✅ Validación de precio (crítica)
    final price = json['price'];
    if (!_isValidPrice(price)) {
      if (kDebugMode) print('[Product] Precio inválido: $price');
      throw FormatException('Precio de producto inválido');
    }

    // ✅ Validaciones de campos opcionales (defensivas)
    final description = json['description'];
    if (!_isValidDescription(description) && kDebugMode) {
      print('[Product] Descripción inválida (truncada)');
    }

    final category = json['category'];
    if (!_isValidCategory(category) && kDebugMode) {
      print('[Product] Categoría inválida, usando default');
    }

    final imageUrl = json['image_url'] ?? json['imgUrl'];
    if (!_isValidImageUrl(imageUrl) && kDebugMode) {
      print('[Product] URL de imagen inválida');
    }

    final stock = json['stock'];
    if (!_isValidStock(stock) && kDebugMode) {
      print('[Product] Stock inválido, ignorando');
    }

    final available = json['available'];
    if (!_isValidAvailable(available) && kDebugMode) {
      print('[Product] available inválido, usando default true');
    }

    // ============================================================
    // ✅ VALIDACIÓN DE FECHAS
    // ============================================================
    final createdAtStr = json['created_at'];
    DateTime parsedCreatedAt;
    if (!_isValidDateTime(createdAtStr)) {
      if (kDebugMode) print('[Product] created_at inválido, usando ahora');
      parsedCreatedAt = DateTime.now();
    } else {
      parsedCreatedAt = createdAtStr is DateTime 
          ? createdAtStr 
          : DateTime.parse(createdAtStr.toString());
    }

    DateTime? parsedUpdatedAt;
    final updatedAtStr = json['updated_at'];
    if (updatedAtStr != null && _isValidDateTime(updatedAtStr)) {
      parsedUpdatedAt = updatedAtStr is DateTime
          ? updatedAtStr
          : DateTime.parse(updatedAtStr.toString());
    }

    // Parse seguro de precio
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

    // Parse seguro de stock
    int? parsedStock;
    if (stock != null) {
      if (stock is int) {
        parsedStock = stock;
      } else if (stock is String) {
        parsedStock = int.tryParse(stock);
      }
      if (parsedStock != null && parsedStock < _minStock) parsedStock = _minStock;
      if (parsedStock != null && parsedStock > _maxStock) parsedStock = _maxStock;
    }

    // Parse seguro de totalSold
    int? parsedTotalSold;
    final totalSold = json['total_sold'];
    if (totalSold != null) {
      if (totalSold is int) {
        parsedTotalSold = totalSold;
      } else if (totalSold is String) {
        parsedTotalSold = int.tryParse(totalSold);
      }
      if (parsedTotalSold != null && parsedTotalSold < 0) parsedTotalSold = 0;
    }

    return Product(
      id: id is int ? id : int.parse(id.toString()),
      name: name.toString().trim(),
      description: description?.toString().trim() ?? '',
      price: parsedPrice,
      category: category?.toString().trim() ?? 'Sin categoría',
      imageUrl: imageUrl?.toString() ?? '',
      available: available is bool ? available : true,
      stock: parsedStock,
      totalSold: parsedTotalSold,
      // ============================================================
      // ✅ NUEVOS CAMPOS
      // ============================================================
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================
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
      // ============================================================
      // ✅ NUEVOS CAMPOS
      // ============================================================
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ============================================================
  // FROM MAP (Firestore)
  // ============================================================
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product.fromJson(map);
  }

  // ============================================================
  // COPYWITH (para rollback en providers)
  // ============================================================
  Product copyWith({
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
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      available: available ?? this.available,
      stock: stock ?? this.stock,
      totalSold: totalSold ?? this.totalSold,
      // ============================================================
      // ✅ NUEVOS CAMPOS
      // ============================================================
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}