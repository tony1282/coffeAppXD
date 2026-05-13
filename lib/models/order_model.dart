class Order {
  final int? id;
  final String? userId;
  final List<OrderItem> items;
  final double total;
  final String status; // pending, confirmed, preparing, shipped, delivered
  final String? paymentMethod;
  final String? paymentStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;

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

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      items: (json['items'] as List? ?? [])
          .map((i) => OrderItem.fromJson(i))
          .toList(),
      total: json['total'].toDouble(),
      status: json['status'],
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      deliveryAddress: json['delivery_address'],
      deliveryLat: json['delivery_lat']?.toDouble(),
      deliveryLng: json['delivery_lng']?.toDouble(),
    );
  }

  String get statusText {
    switch (status) {
      case 'pending': return 'Pendiente';
      case 'confirmed': return 'Confirmado';
      case 'preparing': return 'Preparando';
      case 'shipped': return 'En camino';
      case 'delivered': return 'Entregado';
      default: return status;
    }
  }
}

class OrderItem {
  final int productId;
  final String productName;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'],
      productName: json['product_name'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
    );
  }
}