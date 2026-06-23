// data/datasources/remote/product_remote_datasource.dart

import '../../models/product_model.dart';
import '../../services/product_service.dart';

class ProductRemoteDataSource {
  final ProductService _productService;

  ProductRemoteDataSource({ProductService? productService})
      : _productService = productService ?? ProductService();

  Future<List<ProductModel>> getProducts() async {
    return await _productService.getProducts();
  }

  Future<ProductModel> getProductById(int id) async {
    return await _productService.getProductById(id);
  }

  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    return await _productService.createProduct(data);
  }

  Future<ProductModel> updateProduct(int id, Map<String, dynamic> data) async {
    return await _productService.updateProduct(id, data);
  }

  Future<void> deleteProduct(int id) async {
    await _productService.deleteProduct(id);
  }

  Future<ProductModel> toggleAvailability(int id, bool available) async {
    return await _productService.toggleAvailability(id, available);
  }
}