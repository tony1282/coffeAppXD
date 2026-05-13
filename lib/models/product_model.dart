// lib/models/product_model.dart

class Product {
  final int id;  // ← CAMBIADO a int
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final bool available;
  final int? stock;
  final int? totalSold;

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
  });

  String get imgUrl => imageUrl;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],  // ← convertir a int
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price']).toDouble(),
      category: json['category'] ?? 'Sin categoría',
      imageUrl: json['image_url'] ?? json['imgUrl'] ?? '',
      available: json['available'] ?? true,
      stock: json['stock'],
      totalSold: json['total_sold'],
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
      'stock': stock,
      'total_sold': totalSold,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] is String ? int.parse(map['id']) : map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      price: (map['price']).toDouble(),
      category: map['category'] ?? 'Sin categoría',
      imageUrl: map['image_url'] ?? map['imgUrl'] ?? '',
      available: map['available'] ?? true,
      stock: map['stock'],
      totalSold: map['total_sold'],
    );
  }
}