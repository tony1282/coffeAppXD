import '../models/product_model.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _api = ApiService();

  Future<List<ProductModel>> getProducts() async {
    final data = await _api.get("/products/");

    return (data as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }
}