// domain/repositories/product_repository.dart

import '../entities/product_entity.dart';

abstract class ProductRepository {
  Future<List<ProductEntity>> getProducts();
  Future<ProductEntity> getProductById(int id);
  Future<ProductEntity> createProduct(Map<String, dynamic> data);
  Future<ProductEntity> updateProduct(int id, Map<String, dynamic> data);
  Future<void> deleteProduct(int id);
  Future<ProductEntity> toggleAvailability(int id, bool available);
}