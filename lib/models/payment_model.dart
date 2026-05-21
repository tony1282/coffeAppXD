// lib/models/payment_model.dart

import 'package:flutter/foundation.dart';

class Payment {
  final int? id;
  final String? orderId;
  final double amount;
  final String method;
  final String status;
  final DateTime createdAt;

  static const List<String> _validStatuses = ['pending', 'completed', 'failed', 'refunded'];
  static const List<String> _validMethods = ['card', 'oxxo', 'bank_transfer', 'cash'];

  Payment({
    this.id,
    this.orderId,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'];
    double parsedAmount;
    if (amount is int) {
      parsedAmount = amount.toDouble();
    } else if (amount is double) {
      parsedAmount = amount;
    } else if (amount is String) {
      parsedAmount = double.tryParse(amount) ?? 0.0;
    } else {
      throw FormatException('Monto de pago inválido');
    }

    final method = json['payment_method']?.toString().toLowerCase() ?? '';
    final status = json['status']?.toString().toLowerCase() ?? 'pending';

    final createdAtStr = json['created_at'];
    DateTime parsedCreatedAt;
    try {
      parsedCreatedAt = createdAtStr != null
          ? DateTime.parse(createdAtStr.toString())
          : DateTime.now();
    } catch (_) {
      parsedCreatedAt = DateTime.now();
    }

    return Payment(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      orderId: json['order_id']?.toString(),
      amount: parsedAmount,
      method: _validMethods.contains(method) ? method : 'cash',
      status: _validStatuses.contains(status) ? status : 'pending',
      createdAt: parsedCreatedAt,
    );
  }
}

class Order {
  final int? id;
  final String? userId;
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

  // ============================================================
  // CONFIGURACIÓN DE SEGURIDAD
  // ============================================================
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
  });

  // ============================================================
  // VALIDACIONES DEFENSIVAS
  // ============================================================
  static bool _isValidId(dynamic id) {
    if (id == null) return true; // ID puede ser null para pedidos nuevos
    if (id is int) return id > 0;
    if (id is String) {
      final parsed = int.tryParse(id);
      return parsed != null && parsed > 0;
    }
    return false;
  }

  static bool _isValidUserId(dynamic userId) {
    if (userId == null) return true;
    return userId is String && userId.trim().isNotEmpty && userId.length <= 128;
  }

  static bool _isValidTotal(dynamic total) {
    if (total == null) return false;
    double parsed;
    if (total is int) {
      parsed = total.toDouble();
    } else if (total is double) {
      parsed = total;
    } else if (total is String) {
      parsed = double.tryParse(total) ?? -1;
    } else {
      return false;
    }
    return parsed >= _minValidTotal && parsed <= _maxValidTotal;
  }

  static bool _isValidStatus(dynamic status) {
    if (status == null) return false;
    return status is String && _validStatuses.contains(status.toLowerCase());
  }

  static bool _isValidDateTime(dynamic dateTime) {
    if (dateTime == null) return false;
    if (dateTime is String) {
      try {
        DateTime.parse(dateTime);
        return true;
      } catch (_) {
        return false;
      }
    }
    return dateTime is DateTime;
  }

  static bool _isValidDeliveryAddress(dynamic address) {
    if (address == null) return true;
    return address is String && address.length <= _maxDeliveryAddressLength;
  }

  static bool _isValidLat(dynamic lat) {
    if (lat == null) return true;
    double parsed;
    if (lat is int) {
      parsed = lat.toDouble();
    } else if (lat is double) {
      parsed = lat;
    } else if (lat is String) {
      parsed = double.tryParse(lat) ?? -999;
    } else {
      return false;
    }
    return parsed >= _minValidLat && parsed <= _maxValidLat;
  }

  static bool _isValidLng(dynamic lng) {
    if (lng == null) return true;
    double parsed;
    if (lng is int) {
      parsed = lng.toDouble();
    } else if (lng is double) {
      parsed = lng;
    } else if (lng is String) {
      parsed = double.tryParse(lng) ?? -999;
    } else {
      return false;
    }
    return parsed >= _minValidLng && parsed <= _maxValidLng;
  }

  // ============================================================
  // FROM JSON (CON VALIDACIONES DEFENSIVAS)
  // ============================================================
  factory Order.fromJson(Map<String, dynamic> json) {
    // ✅ Validación de ID (opcional)
    final id = json['id'];
    if (!_isValidId(id)) {
      if (kDebugMode) {
        print('[Order] ID inválido: $id');
      }
    }

    // ✅ Validación de userId
    final userId = json['user_id'];
    if (!_isValidUserId(userId)) {
      if (kDebugMode) {
        print('[Order] userId inválido: $userId');
      }
    }

    // ✅ Validación y parse de items
    final itemsData = json['items'];
    List<OrderItem> parsedItems = [];
    if (itemsData is List) {
      // Limitar cantidad de items (memory bombing)
      final limitedItems = itemsData.length > _maxItems
          ? itemsData.sublist(0, _maxItems)
          : itemsData;
      
      for (final item in limitedItems) {
        if (item is Map<String, dynamic>) {
          try {
            parsedItems.add(OrderItem.fromJson(item));
          } catch (e) {
            if (kDebugMode) {
              print('[Order] Error parseando OrderItem: $e');
            }
          }
        }
      }
    }

    // ✅ Validación de total (CRÍTICA)
    final total = json['total'];
    if (!_isValidTotal(total)) {
      if (kDebugMode) {
        print('[Order] Total inválido: $total');
      }
      throw FormatException('Total de pedido inválido');
    }

    // ✅ Validación de status
    final status = json['status'] ?? 'pending';
    if (!_isValidStatus(status)) {
      if (kDebugMode) {
        print('[Order] Status inválido: $status, usando pending');
      }
    }
    final normalizedStatus = _validStatuses.contains(status?.toLowerCase())
        ? status.toLowerCase()
        : 'pending';

    // ✅ Validación de fechas
    final createdAtStr = json['created_at'];
    DateTime parsedCreatedAt;
    if (!_isValidDateTime(createdAtStr)) {
      if (kDebugMode) {
        print('[Order] created_at inválido: $createdAtStr');
      }
      parsedCreatedAt = DateTime.now();
    } else {
      parsedCreatedAt = DateTime.parse(createdAtStr.toString());
    }

    DateTime? parsedUpdatedAt;
    final updatedAtStr = json['updated_at'];
    if (updatedAtStr != null && _isValidDateTime(updatedAtStr)) {
      parsedUpdatedAt = DateTime.parse(updatedAtStr.toString());
    }

    // ✅ Validación de dirección
    final deliveryAddress = json['delivery_address'];
    if (!_isValidDeliveryAddress(deliveryAddress)) {
      if (kDebugMode) {
        print('[Order] delivery_address inválido, ignorando');
      }
    }

    // ✅ Validación de coordenadas
    final deliveryLat = json['delivery_lat'];
    final deliveryLng = json['delivery_lng'];
    if (!_isValidLat(deliveryLat)) {
      if (kDebugMode) {
        print('[Order] delivery_lat inválido: $deliveryLat');
      }
    }
    if (!_isValidLng(deliveryLng)) {
      if (kDebugMode) {
        print('[Order] delivery_lng inválido: $deliveryLng');
      }
    }

    // Parse seguro del total
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

    // Asegurar que el total no sea menor al mínimo
    if (parsedTotal < _minValidTotal) {
      parsedTotal = _minValidTotal;
    }

    return Order(
      id: id is int ? id : (id is String ? int.tryParse(id) : null),
      userId: userId?.toString(),
      items: parsedItems,
      total: parsedTotal,
      status: normalizedStatus,
      paymentMethod: json['payment_method']?.toString(),
      paymentStatus: json['payment_status']?.toString(),
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      deliveryAddress: _isValidDeliveryAddress(deliveryAddress)
          ? deliveryAddress.toString()
          : null,
      deliveryLat: _isValidLat(deliveryLat)
          ? (deliveryLat is int ? deliveryLat.toDouble() : deliveryLat?.toDouble())
          : null,
      deliveryLng: _isValidLng(deliveryLng)
          ? (deliveryLng is int ? deliveryLng.toDouble() : deliveryLng?.toDouble())
          : null,
    );
  }

  // ============================================================
  // COPYWITH (COMPLETO PARA ROLLBACK)
  // ============================================================
  Order copyWith({
    int? id,
    String? userId,
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
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
    );
  }

  // ============================================================
  // STATUS TEXT (SEGURO)
  // ============================================================
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

// ============================================================
// ORDER ITEM MODEL
// ============================================================
class OrderItem {
  final int productId;
  final String productName;
  final int quantity;
  final double price;

  // ============================================================
  // CONFIGURACIÓN DE SEGURIDAD
  // ============================================================
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

  // ============================================================
  // VALIDACIONES
  // ============================================================
  static bool _isValidProductId(dynamic id) {
    if (id == null) return false;
    if (id is int) return id > 0;
    if (id is String) {
      final parsed = int.tryParse(id);
      return parsed != null && parsed > 0;
    }
    return false;
  }

  static bool _isValidProductName(dynamic name) {
    if (name == null) return false;
    return name is String && 
           name.trim().isNotEmpty && 
           name.length <= _maxProductNameLength;
  }

  static bool _isValidQuantity(dynamic quantity) {
    if (quantity == null) return false;
    int parsed;
    if (quantity is int) {
      parsed = quantity;
    } else if (quantity is String) {
      parsed = int.tryParse(quantity) ?? -1;
    } else {
      return false;
    }
    return parsed >= _minQuantity && parsed <= _maxQuantity;
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

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final productId = json['product_id'];
    if (!_isValidProductId(productId)) {
      if (kDebugMode) {
        print('[OrderItem] productId inválido: $productId');
      }
      throw FormatException('ID de producto inválido');
    }

    final productName = json['product_name'];
    if (!_isValidProductName(productName)) {
      if (kDebugMode) {
        print('[OrderItem] productName inválido: $productName');
      }
      throw FormatException('Nombre de producto inválido');
    }

    final quantity = json['quantity'];
    if (!_isValidQuantity(quantity)) {
      if (kDebugMode) {
        print('[OrderItem] quantity inválido: $quantity');
      }
      throw FormatException('Cantidad inválida');
    }

    final price = json['price'];
    if (!_isValidPrice(price)) {
      if (kDebugMode) {
        print('[OrderItem] price inválido: $price');
      }
      throw FormatException('Precio inválido');
    }

    // Parse seguro
    int parsedProductId;
    if (productId is int) {
      parsedProductId = productId;
    } else {
      parsedProductId = int.parse(productId.toString());
    }

    int parsedQuantity;
    if (quantity is int) {
      parsedQuantity = quantity;
    } else {
      parsedQuantity = int.parse(quantity.toString());
    }

    double parsedPrice;
    if (price is int) {
      parsedPrice = price.toDouble();
    } else if (price is double) {
      parsedPrice = price;
    } else {
      parsedPrice = double.parse(price.toString());
    }

    return OrderItem(
      productId: parsedProductId,
      productName: productName.toString().trim(),
      quantity: parsedQuantity,
      price: parsedPrice,
    );
  }
}