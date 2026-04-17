import '../models/product_model.dart';

class CartProvider {
  final List<Product> _items = [];

  List<Product> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  bool get isNotEmpty => _items.isNotEmpty;
  bool get isEmpty => _items.isEmpty;

  double get total => _items.fold(0.0, (sum, p) => sum + p.price);

  void add(Product product) => _items.add(product);

  void remove(Product product) => _items.remove(product);

  void removeAt(int index) => _items.removeAt(index);

  void clear() => _items.clear();
}