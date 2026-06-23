// data/datasources/local/product_local_datasource.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../../models/product_model.dart';

class ProductLocalDataSource {
  static const String _boxName = 'products_cache';
  static const int _maxCachedProducts = 200;

  Future<Box<ProductModel>> _getBox() async {
    return await Hive.openBox<ProductModel>(_boxName);
  }

  Future<void> cacheProducts(List<ProductModel> products) async {
    final box = await _getBox();
    await box.clear();
    final limited = products.take(_maxCachedProducts).toList();
    for (var i = 0; i < limited.length; i++) {
      await box.put(i.toString(), limited[i]);
    }
  }

  Future<List<ProductModel>> getCachedProducts() async {
    final box = await _getBox();
    return box.values.toList();
  }

  Future<void> removeCachedProduct(int id) async {
    final box = await _getBox();
    final key = box.keys.cast<String>().firstWhere(
      (key) => box.get(key)?.id == id,
      orElse: () => '',
    );
    if (key.isNotEmpty) {
      await box.delete(key);
    }
  }

  Future<void> clearCache() async {
    final box = await _getBox();
    await box.clear();
  }
}