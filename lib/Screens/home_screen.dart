import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../screens/orders/cart_screen.dart';
import '../../screens/orders/order_history_screen.dart';
import '../../screens/products/product_detail_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '/widgets/home/home_header.dart';
import '/widgets/home/category_chips.dart';
import '/widgets/home/product_grid.dart';
import '/widgets/home/cart_bar.dart';
import '/widgets/home/home_nav_bar.dart';
import '/widgets/home/product_search_delegate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNav = 0;
  String _selectedCategory = 'Todo';
  final CartProvider _cart = CartProvider();

  final List<String> _categories = ['Todo', 'Café frío', 'Caliente', 'Galletas'];

  final List<Product> _products = [
    Product(
      id: '1',
      name: 'Americano Clásico',
      price: 5.50,
      imageUrl: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400',
      description: 'Caliente',
      category: 'Caliente',
    ),
    Product(
      id: '2',
      name: 'Espresso Doble',
      price: 3.50,
      imageUrl: 'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?w=400',
      description: 'Intenso y concentrado',
      category: 'Caliente',
    ),
    Product(
      id: '3',
      name: 'Capuchino',
      price: 6.00,
      imageUrl: 'https://images.unsplash.com/photo-1534778101976-62847782c213?w=400',
      description: 'Con espuma de leche',
      category: 'Caliente',
    ),
    Product(
      id: '4',
      name: 'Frappé de Caramelo',
      price: 7.50,
      imageUrl: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400',
      description: 'Refrescante y dulce',
      category: 'Café frío',
    ),
    Product(
      id: '5',
      name: 'Cold Brew',
      price: 6.50,
      imageUrl: 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=400',
      description: 'Suave y sin acidez',
      category: 'Café frío',
    ),
    Product(
      id: '6',
      name: 'Galleta de Avena',
      price: 2.50,
      imageUrl: 'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=400',
      description: 'Recién horneada',
      category: 'Galletas',
    ),
    Product(
      id: '7',
      name: 'Chocolate Chip Cookie',
      price: 2.75,
      imageUrl: 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400',
      description: 'Con chips de chocolate',
      category: 'Galletas',
    ),
    Product(
      id: '8',
      name: 'Latte Helado',
      price: 6.00,
      imageUrl: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400',
      description: 'Suave con hielo',
      category: 'Café frío',
    ),
  ];

  List<Product> get _filteredProducts {
    if (_selectedCategory == 'Todo') return _products;
    return _products
        .where((p) => p.category == _selectedCategory)
        .toList();
  }

  // ── Navegación ────────────────────────────────────────────────────────────

  void _goToProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product,
          onAddToCart: () {
            _cart.add(product);
            setState(() {});
          },
        ),
      ),
    );
  }

  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          cartItems: _cart.items.toList(),
          onOrderPlaced: () {
            setState(() => _cart.clear());
          },
        ),
      ),
    );
  }

  void _goToOrderHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
    ).then((_) => setState(() => _selectedNav = 0));
  }

  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    ).then((_) => setState(() => _selectedNav = 0));
  }

  void _openSearch() {
    showSearch(
      context: context,
      delegate: ProductSearchDelegate(
        products: _products,
        onAddToCart: (p) {
          _cart.add(p);
          setState(() {});
        },
        onTap: _goToProduct,
      ),
    );
  }

  void _addToCart(Product p) {
    _cart.add(p);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${p.name} agregado'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            HomeHeader(onSearchTap: _openSearch),

            const SizedBox(height: 12),

            // ── Categorías ──
            CategoryChips(
              categories: _categories,
              selected: _selectedCategory,
              onSelect: (cat) => setState(() => _selectedCategory = cat),
            ),

            const SizedBox(height: 10),

            // ── Grid de productos ──
            Expanded(
              child: ProductGrid(
                products: _filteredProducts,
                onTap: _goToProduct,
                onAdd: _addToCart,
              ),
            ),

            // ── Barra del carrito ──
            if (_cart.isNotEmpty)
              CartBar(
                itemCount: _cart.itemCount,
                total: _cart.total,
                onTap: _goToCart,
              ),

            // ── NavBar ──
            HomeNavBar(
              selected: _selectedNav,
              onMenu: () => setState(() => _selectedNav = 0),
              onOrders: () {
                setState(() => _selectedNav = 1);
                _goToOrderHistory();
              },
              onProfile: () {
                setState(() => _selectedNav = 2);
                _goToProfile();
              },
            ),
          ],
        ),
      ),
    );
  }
}