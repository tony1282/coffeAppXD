// lib/models/cart_item_model.dart

import 'package:hive/hive.dart';

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
  
  CartItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });
}