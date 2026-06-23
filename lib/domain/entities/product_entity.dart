// domain/entities/product_entity.dart

class ProductEntity {
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

  ProductEntity({
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

  bool get isInStock => stock != null && stock! > 0;
  bool get isLowStock => stock != null && stock! <= 5 && stock! > 0;
  bool get isOutOfStock => stock != null && stock! <= 0;
}