import '../models/product_model.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _api = ApiService();

  Future<List<Product>> getProducts() async {
    final data = await _api.get("/products/");

    return (data as List)
        .map((json) => Product.fromMap(json))
        .toList();
  }
}