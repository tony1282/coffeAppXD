// lib/screens/home_screen.dart

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
  bool _isNavigating = false; // ✅ Prevenir navegación múltiple

  // ── Categorías estáticas (puedes obtenerlas dinámicamente después) ──
  final List<String> _categories = ['Todo', 'Café frío', 'Caliente', 'Galletas'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductProvider>().fetchProducts();
      }
    });
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    if (_selectedCategory == 'Todo') return products;
    return products.where((p) => p.category == _selectedCategory).toList();
  }

  // ✅ Validar stock antes de agregar
  bool _canAddToCart(Product product, CartProvider cartProvider) {
    if (product.stock != null && product.stock! <= 0) {
      _showErrorSnack('${product.name} no está disponible');
      return false;
    }
    if (!product.available) {
      _showErrorSnack('${product.name} no está disponible');
      return false;
    }
    
    // ✅ Verificar límite por producto en carrito
    final existingIndex = cartProvider.items.indexWhere(
      (item) => item.product.id == product.id,
    );
    final existingItem = existingIndex != -1 ? cartProvider.items[existingIndex] : null;
    
    if (existingItem != null && product.stock != null) {
      if (existingItem.quantity + 1 > product.stock!) {
        _showErrorSnack('Solo hay ${product.stock} unidades disponibles de ${product.name}');
        return false;
      }
    }
    
    return true;
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _goToProduct(Product product, CartProvider cartProvider) {
    if (_isNavigating) return;
    _isNavigating = true;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product,
          onAddToCart: () {
            if (_canAddToCart(product, cartProvider)) {
              cartProvider.add(product);
              if (mounted) {
                _showSuccessSnack('${product.name} agregado al carrito');
              }
            }
          },
        ),
      ),
    ).whenComplete(() {
      if (mounted) {
        _isNavigating = false;
      }
    });
  }

  void _goToCart() {
    if (_isNavigating) return;
    _isNavigating = true;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          cartItems: context.read<CartProvider>().items.toList(),
          onOrderPlaced: () {
            context.read<CartProvider>().clear();
            if (mounted) {
              setState(() {});
            }
          },
        ),
      ),
    ).whenComplete(() {
      if (mounted) {
        _isNavigating = false;
      }
    });
  }

  void _goToOrderHistory() {
    if (_isNavigating) return;
    _isNavigating = true;
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
    ).whenComplete(() {
      if (mounted) {
        setState(() => _selectedNav = 0);
        _isNavigating = false;
      }
    });
  }

  void _goToProfile() {
    if (_isNavigating) return;
    _isNavigating = true;
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    ).whenComplete(() {
      if (mounted) {
        setState(() => _selectedNav = 0);
        _isNavigating = false;
      }
    });
  }

  void _openSearch(List<Product> products, CartProvider cartProvider) {
    if (_isNavigating) return;
    
    showSearch(
      context: context,
      delegate: ProductSearchDelegate(
        products: products,
        onAddToCart: (p) {
          if (_canAddToCart(p, cartProvider)) {
            cartProvider.add(p);
            if (mounted) {
              _showSuccessSnack('${p.name} agregado');
              setState(() {});
            }
          }
        },
        onTap: (p) => _goToProduct(p, cartProvider),
      ),
    );
  }

  void _addToCart(CartProvider cartProvider, Product p) {
    if (!_canAddToCart(p, cartProvider)) return;
    
    cartProvider.add(p);
    if (mounted) {
      setState(() {});
      _showSuccessSnack('${p.name} agregado al carrito');
    }
  }

  // ✅ Badge con límite de dígitos
  Widget _buildCartIcon(CartProvider cartProvider) {
    final itemCount = cartProvider.itemCount;
    final displayCount = itemCount > 99 ? '99+' : '$itemCount';
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_rounded),
          onPressed: _goToCart,
          color: AppColors.textDark,
        ),
        if (itemCount > 0)
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
                displayCount,
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
                HomeHeader(
                  onSearchTap: () => _openSearch(products, cartProvider),
                  actions: _buildCartIcon(cartProvider),
                ),
                const SizedBox(height: 12),
                CategoryChips(
                  categories: _categories,
                  selected: _selectedCategory,
                  onSelect: (cat) {
                    if (mounted) {
                      setState(() => _selectedCategory = cat);
                    }
                  },
                ),
                const SizedBox(height: 10),
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
                if (cartProvider.isNotEmpty)
                  CartBar(
                    itemCount: cartProvider.itemCount,
                    total: cartProvider.total,
                    onTap: _goToCart,
                  ),
                HomeNavBar(
                  selected: _selectedNav,
                  onMenu: () {
                    if (mounted) {
                      setState(() => _selectedNav = 0);
                    }
                  },
                  onOrders: () {
                    if (mounted) {
                      setState(() => _selectedNav = 1);
                    }
                    _goToOrderHistory();
                  },
                  onProfile: () {
                    if (mounted) {
                      setState(() => _selectedNav = 2);
                    }
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