// data/repositories/product_repository_impl.dart

import 'package:coffe_app/data/models/product_model.dart';

import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/remote/product_remote_datasource.dart';
import '../datasources/local/product_local_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource? localDataSource;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    this.localDataSource,
  });

  @override
  Future<List<ProductEntity>> getProducts() async {
    try {
      final models = await remoteDataSource.getProducts();
      if (localDataSource != null) {
        await localDataSource!.cacheProducts(models);
      }
      return models.map((model) => _toEntity(model)).toList();
    } catch (e) {
      if (localDataSource != null) {
        final cached = await localDataSource!.getCachedProducts();
        if (cached.isNotEmpty) {
          return cached.map((model) => _toEntity(model)).toList();
        }
      }
      rethrow;
    }
  }

  @override
  Future<ProductEntity> getProductById(int id) async {
    final model = await remoteDataSource.getProductById(id);
    return _toEntity(model);
  }

  @override
  Future<ProductEntity> createProduct(Map<String, dynamic> data) async {
    final model = await remoteDataSource.createProduct(data);
    if (localDataSource != null) {
      await localDataSource!.removeCachedProduct(model.id);
    }
    return _toEntity(model);
  }

  @override
  Future<ProductEntity> updateProduct(int id, Map<String, dynamic> data) async {
    final model = await remoteDataSource.updateProduct(id, data);
    if (localDataSource != null) {
      await localDataSource!.removeCachedProduct(id);
    }
    return _toEntity(model);
  }

  @override
  Future<void> deleteProduct(int id) async {
    await remoteDataSource.deleteProduct(id);
    if (localDataSource != null) {
      await localDataSource!.removeCachedProduct(id);
    }
  }

  @override
  Future<ProductEntity> toggleAvailability(int id, bool available) async {
    final model = await remoteDataSource.toggleAvailability(id, available);
    if (localDataSource != null) {
      await localDataSource!.removeCachedProduct(id);
    }
    return _toEntity(model);
  }

  ProductEntity _toEntity(ProductModel model) {
    return ProductEntity(
      id: model.id,
      name: model.name,
      description: model.description,
      price: model.price,
      category: model.category,
      imageUrl: model.imageUrl,
      available: model.available,
      stock: model.stock,
      totalSold: model.totalSold,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}