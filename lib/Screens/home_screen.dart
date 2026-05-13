import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
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

  // ── Categorías estáticas (puedes obtenerlas dinámicamente después) ──
  final List<String> _categories = ['Todo', 'Café frío', 'Caliente', 'Galletas'];

  @override
  void initState() {
    super.initState();
    // Cargar productos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    if (_selectedCategory == 'Todo') return products;
    return products
        .where((p) => p.category == _selectedCategory)
        .toList();
  }

  // ── Navegación ────────────────────────────────────────────────────────────

  void _goToProduct(Product product, CartProvider cartProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product,
          onAddToCart: () {
            cartProvider.add(product);
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
          cartItems: context.read<CartProvider>().items.toList(),
          onOrderPlaced: () {
            context.read<CartProvider>().clear();
            setState(() {});
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

  void _openSearch(List<Product> products, CartProvider cartProvider) {
    showSearch(
      context: context,
      delegate: ProductSearchDelegate(
        products: products,
        onAddToCart: (p) {
          cartProvider.add(p);
          setState(() {});
        },
        onTap: (p) => _goToProduct(p, cartProvider),
      ),
    );
  }

  void _addToCart(CartProvider cartProvider, Product p) {
    cartProvider.add(p);
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

  // ── Ícono del carrito con badge ──
  Widget _buildCartIcon(CartProvider cartProvider) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_rounded),
          onPressed: _goToCart,
          color: AppColors.textDark,
        ),
        if (cartProvider.itemCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '${cartProvider.itemCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProductProvider, CartProvider>(
      builder: (context, productProvider, cartProvider, _) {
        final products = productProvider.products;
        final isLoading = productProvider.isLoading;
        final filteredProducts = _getFilteredProducts(products);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // ── Header con carrito ──
                HomeHeader(
                  onSearchTap: () => _openSearch(products, cartProvider),
                  actions: _buildCartIcon(cartProvider),  // ← AGREGADO
                ),

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
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : products.isEmpty
                          ? const Center(
                              child: Text('No hay productos disponibles'),
                            )
                          : ProductGrid(
                              products: filteredProducts,
                              onTap: (p) => _goToProduct(p, cartProvider),
                              onAdd: (p) => _addToCart(cartProvider, p),
                            ),
                ),

                // ── Barra del carrito (opcional, puedes mantenerla) ──
                if (cartProvider.isNotEmpty)
                  CartBar(
                    itemCount: cartProvider.itemCount,
                    total: cartProvider.total,
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
      },
    );
  }
}