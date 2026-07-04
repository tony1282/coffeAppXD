// lib/data/models/order_model.dart

import 'package:flutter/foundation.dart';
import '../../core/error/error_messages.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/validators.dart';

class Order {
  final int? id;
  final String? userId;
  final String? userName;
  final List<OrderItem> items;
  final double total;
  final String status;
  final String? paymentMethod;
  final String? paymentStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? notes;
  
  // ⭐ NUEVO: mp_payment_id para reembolsos
  final String? mpPaymentId;

  static const double _minValidTotal = 1.0;
  static const double _maxValidTotal = 100000.0;
  static const int _maxItems = 100;
  static const double _minValidLat = -90.0;
  static const double _maxValidLat = 90.0;
  static const double _minValidLng = -180.0;
  static const double _maxValidLng = 180.0;
  static const int _maxDeliveryAddressLength = 500;
  static const List<String> _validStatuses = [
    'pending', 'confirmed', 'preparing', 'shipped', 'delivered', 'cancelled'
  ];

  Order({
    this.id,
    this.userId,
    this.userName,
    required this.items,
    required this.total,
    required this.status,
    this.paymentMethod,
    this.paymentStatus,
    required this.createdAt,
    this.updatedAt,
    this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    this.notes,
    this.mpPaymentId,  // ← NUEVO
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // id
    final id = json['id'];
    int? parsedId;
    if (id != null) {
      if (id is int) {
        parsedId = id;
      } else if (id is String) {
        parsedId = int.tryParse(id);
      }
      if (parsedId != null && parsedId <= 0) {
        if (kDebugMode) AppLogger.debug('Order: id inválido');
      }
    }

    // userId
    final userId = json['user_id']?.toString();
    if (userId != null && userId.length > 128) {
      if (kDebugMode) AppLogger.debug('Order: userId demasiado largo');
    }

    // userName
    final userName = json['user_name']?.toString();
    if (userName != null && userName.length > 100) {
      if (kDebugMode) AppLogger.debug('Order: userName demasiado largo');
    }

    // items
    final itemsData = json['items'];
    List<OrderItem> parsedItems = [];
    if (itemsData is List) {
      final limitedItems = itemsData.length > _maxItems
          ? itemsData.sublist(0, _maxItems)
          : itemsData;
      for (final item in limitedItems) {
        if (item is Map<String, dynamic>) {
          try {
            parsedItems.add(OrderItem.fromJson(item));
          } catch (e) {
            if (kDebugMode) AppLogger.debug('Order: error parseando OrderItem');
          }
        }
      }
    }

    // total
    final total = json['total'];
    double parsedTotal;
    if (total is int) {
      parsedTotal = total.toDouble();
    } else if (total is double) {
      parsedTotal = total;
    } else if (total is String) {
      parsedTotal = double.tryParse(total) ?? _minValidTotal;
    } else {
      parsedTotal = _minValidTotal;
    }
    if (parsedTotal < _minValidTotal || parsedTotal > _maxValidTotal) {
      if (kDebugMode) AppLogger.debug('Order: total inválido');
      parsedTotal = _minValidTotal;
    }

    // status
    final status = json['status']?.toString().toLowerCase() ?? 'pending';
    final normalizedStatus = _validStatuses.contains(status) ? status : 'pending';

    // dates
    DateTime parsedCreatedAt;
    final createdAtStr = json['created_at'];
    if (createdAtStr != null) {
      try {
        parsedCreatedAt = DateTime.parse(createdAtStr.toString());
      } catch (_) {
        parsedCreatedAt = DateTime.now();
        if (kDebugMode) AppLogger.debug('Order: created_at inválido');
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
        if (kDebugMode) AppLogger.debug('Order: updated_at inválido');
      }
    }

    // deliveryAddress
    final deliveryAddress = json['delivery_address']?.toString();
    if (deliveryAddress != null && deliveryAddress.length > _maxDeliveryAddressLength) {
      if (kDebugMode) AppLogger.debug('Order: delivery_address demasiado largo');
    }

    // coordinates
    double? parsedLat;
    final deliveryLat = json['delivery_lat'];
    if (deliveryLat != null) {
      if (deliveryLat is int) {
        parsedLat = deliveryLat.toDouble();
      } else if (deliveryLat is double) {
        parsedLat = deliveryLat;
      } else if (deliveryLat is String) {
        parsedLat = double.tryParse(deliveryLat);
      }
      if (parsedLat != null && (parsedLat < _minValidLat || parsedLat > _maxValidLat)) {
        if (kDebugMode) AppLogger.debug('Order: delivery_lat inválido');
        parsedLat = null;
      }
    }

    double? parsedLng;
    final deliveryLng = json['delivery_lng'];
    if (deliveryLng != null) {
      if (deliveryLng is int) {
        parsedLng = deliveryLng.toDouble();
      } else if (deliveryLng is double) {
        parsedLng = deliveryLng;
      } else if (deliveryLng is String) {
        parsedLng = double.tryParse(deliveryLng);
      }
      if (parsedLng != null && (parsedLng < _minValidLng || parsedLng > _maxValidLng)) {
        if (kDebugMode) AppLogger.debug('Order: delivery_lng inválido');
        parsedLng = null;
      }
    }

    // ⭐ NUEVO: mp_payment_id
    final mpPaymentId = json['mp_payment_id']?.toString();

    return Order(
      id: parsedId,
      userId: userId,
      userName: userName,
      items: parsedItems,
      total: parsedTotal,
      status: normalizedStatus,
      paymentMethod: json['payment_method']?.toString(),
      paymentStatus: json['payment_status']?.toString(),
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      deliveryAddress: deliveryAddress,
      deliveryLat: parsedLat,
      deliveryLng: parsedLng,
      notes: json['notes']?.toString(),
      mpPaymentId: mpPaymentId,  // ← NUEVO
    );
  }

  Order copyWith({
    int? id,
    String? userId,
    String? userName,
    List<OrderItem>? items,
    double? total,
    String? status,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
    String? notes,
    String? mpPaymentId,  // ← NUEVO
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
      notes: notes ?? this.notes,
      mpPaymentId: mpPaymentId ?? this.mpPaymentId,  // ← NUEVO
    );
  }

  String get statusText {
    switch (status) {
      case 'pending': return 'Pendiente';
      case 'confirmed': return 'Confirmado';
      case 'preparing': return 'Preparando';
      case 'shipped': return 'En camino';
      case 'delivered': return 'Entregado';
      case 'cancelled': return 'Cancelado';
      default: return status;
    }
  }
}

class OrderItem {
  final int productId;
  final String productName;
  final int quantity;
  final double price;

  static const double _minValidPrice = 1.0;
  static const double _maxValidPrice = 10000.0;
  static const int _minQuantity = 1;
  static const int _maxQuantity = 999;
  static const int _maxProductNameLength = 100;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // productId
    final productId = json['product_id'];
    int parsedProductId;
    if (productId is int) {
      parsedProductId = productId;
    } else if (productId is String) {
      parsedProductId = int.tryParse(productId) ?? 0;
    } else {
      parsedProductId = 0;
    }
    if (parsedProductId <= 0) {
      if (kDebugMode) AppLogger.debug('OrderItem: productId inválido');
      throw FormatException(ErrorMessages.invalidResponse);
    }

    // productName
    final productName = json['product_name']?.toString().trim() ?? '';
    if (productName.isEmpty || productName.length > _maxProductNameLength) {
      if (kDebugMode) AppLogger.debug('OrderItem: productName inválido');
      throw FormatException(ErrorMessages.invalidResponse);
    }

    // quantity
    final quantity = json['quantity'];
    int parsedQuantity;
    if (quantity is int) {
      parsedQuantity = quantity;
    } else if (quantity is String) {
      parsedQuantity = int.tryParse(quantity) ?? 0;
    } else {
      parsedQuantity = 0;
    }
    if (parsedQuantity < _minQuantity || parsedQuantity > _maxQuantity) {
      if (kDebugMode) AppLogger.debug('OrderItem: quantity inválido');
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
      if (kDebugMode) AppLogger.debug('OrderItem: price inválido');
      throw FormatException(ErrorMessages.invalidResponse);
    }

    return OrderItem(
      productId: parsedProductId,
      productName: productName,
      quantity: parsedQuantity,
      price: parsedPrice,
    );
  }
}