// lib/presentation/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/constants.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/ui/custom_dialogs.dart';
import '../../../data/models/product_model.dart';
import '../../../presentation/providers/cart_provider.dart';
import '../../../presentation/providers/product_provider.dart';
import '../../../presentation/providers/order_provider.dart';
import '../../../presentation/providers/payment_provider.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/category_chips.dart';
import '../../widgets/home/product_grid.dart';
import '../../widgets/home/cart_bar.dart';
import '../../widgets/home/home_nav_bar.dart';
import '../../widgets/home/product_search_delegate.dart';
import '../orders/cart_screen.dart';
import '../orders/order_history_screen.dart';
import '../products/product_detail_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNav = 0;
  String _selectedCategory = 'Todo';
  bool _isNavigating = false;

  final Map<int, DateTime> _lastAddTime = {};
  static const Duration _addThrottle = Duration(milliseconds: 800);

  final List<String> _categories = ['Todo', 'Café frío', 'Caliente', 'Galletas'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Cargar productos
        context.read<ProductProvider>().fetchProducts();
        // 🔥 Verificar pedidos pendientes
        _checkPendingOrders();
      }
    });
  }

  // ────────────────────────────────────────────────────────────────
  // 🔥 VERIFICAR PEDIDOS PENDIENTES AL ABRIR LA APP
  // ────────────────────────────────────────────────────────────────
  Future<void> _checkPendingOrders() async {
    final orderProvider = context.read<OrderProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    
    // Esperar a que los pedidos se carguen
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Obtener pedidos pendientes
    final pendingOrders = orderProvider.orders
        .where((o) => o.paymentStatus == 'pending' || o.paymentStatus == 'in_process')
        .toList();
    
    if (pendingOrders.isEmpty) return;
    
    print('🔍 [HOME] Se encontraron ${pendingOrders.length} pedidos pendientes');
    
    for (final order in pendingOrders) {
      // Verificar si el pedido tiene mp_payment_id
      if (order.mpPaymentId != null && order.mpPaymentId!.isNotEmpty) {
        print('🔍 [HOME] Verificando pedido #${order.id} con mp_payment_id: ${order.mpPaymentId}');
        
        // Verificar directamente en MP
        final result = await paymentProvider.verifyPayment(order.mpPaymentId!);
        
        print('🔍 [HOME] Resultado para pedido #${order.id}: ${result['status']}');
        
        if (result['status'] == 'approved' || result['status'] == 'completed') {
          // ✅ El pago fue aprobado, refrescar pedidos
          await orderProvider.fetchOrders();
          if (mounted) {
            CustomDialogs.showSuccess(
              context,
              '¡Tu pago fue confirmado! Pedido #${order.id}'
            );
          }
        } else if (result['status'] == 'failed' || result['status'] == 'rejected') {
          // ❌ El pago fue rechazado
          await orderProvider.fetchOrders();
          if (mounted) {
            CustomDialogs.showError(
              context,
              'El pago del pedido #${order.id} fue rechazado. Intenta de nuevo.'
            );
          }
        } else if (result['status'] == 'pending' || result['status'] == 'in_process') {
          // ⏳ Aún está pendiente
          print('⏳ [HOME] Pedido #${order.id} sigue pendiente');
        }
      }
    }
  }

  // ────────────────────────────────────────────────────────────────
  // THROTTLE
  // ────────────────────────────────────────────────────────────────
  bool _isThrottled(int productId) {
    final last = _lastAddTime[productId];
    if (last == null) return false;
    return DateTime.now().difference(last) < _addThrottle;
  }

  void _markAdded(int productId) {
    _lastAddTime[productId] = DateTime.now();
  }

  // ────────────────────────────────────────────────────────────────
  // VALIDAR STOCK
  // ────────────────────────────────────────────────────────────────
  bool _canAddToCart(ProductModel product, CartProvider cartProvider) {
    if (product.stock != null && product.stock! <= 0) {
      CustomDialogs.showError(context, '${product.name} no está disponible');
      return false;
    }
    if (!product.available) {
      CustomDialogs.showError(context, '${product.name} no está disponible');
      return false;
    }

    final existingIndex = cartProvider.items
        .indexWhere((item) => item.product.id == product.id);
    final existingItem =
        existingIndex != -1 ? cartProvider.items[existingIndex] : null;

    if (existingItem != null && product.stock != null) {
      if (existingItem.quantity + 1 > product.stock!) {
        CustomDialogs.showError(
          context,
          'Solo hay ${product.stock} unidades disponibles de ${product.name}',
        );
        return false;
      }
    }

    return true;
  }

  // ────────────────────────────────────────────────────────────────
  // NAVEGACIÓN
  // ────────────────────────────────────────────────────────────────
  void _goToProduct(ProductModel product, CartProvider cartProvider) {
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
                CustomDialogs.showSuccess(
                    context, '${product.name} agregado al carrito');
              }
            }
          },
        ),
      ),
    ).whenComplete(() {
      if (mounted) _isNavigating = false;
    });
  }

  void _goToCart() async {
    if (_isNavigating) return;
    _isNavigating = true;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          cartItems: context.read<CartProvider>().items.toList(),
          onOrderPlaced: () {
            context.read<CartProvider>().clear();
            if (mounted) setState(() {});
          },
        ),
      ),
    );

    if (mounted) {
      setState(() {});
      _isNavigating = false;
    }
  }

  void _goToOrderHistory() {
    if (_isNavigating) return;
    _isNavigating = true;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _selectedNav = 0;
          _isNavigating = false;
        });
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
        setState(() {
          _selectedNav = 0;
          _isNavigating = false;
        });
      }
    });
  }

  void _openSearch(List<ProductModel> products, CartProvider cartProvider) {
    if (_isNavigating) return;

    showSearch(
      context: context,
      delegate: ProductSearchDelegate(
        products: products,
        onAddToCart: (p) {
          if (_isThrottled(p.id)) return;
          if (_canAddToCart(p, cartProvider)) {
            cartProvider.add(p);
            _markAdded(p.id);
            if (mounted) {
              CustomDialogs.showSuccess(context, '${p.name} agregado');
              setState(() {});
            }
          }
        },
        onTap: (p) => _goToProduct(p, cartProvider),
      ),
    );
  }

  void _addToCart(CartProvider cartProvider, ProductModel p) {
    if (_isThrottled(p.id)) return;
    if (!_canAddToCart(p, cartProvider)) return;

    cartProvider.add(p);
    _markAdded(p.id);

    if (mounted) {
      setState(() {});
      CustomDialogs.showSuccess(context, '${p.name} agregado al carrito');
    }
  }

  // ────────────────────────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer3<ProductProvider, CartProvider, OrderProvider>(
      builder: (context, productProvider, cartProvider, orderProvider, _) {
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
                    if (mounted) setState(() => _selectedCategory = cat);
                  },
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : products.isEmpty
                          ? Center(
                              child: Text(
                                'No hay productos disponibles',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textGrey,
                                ),
                              ),
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
                    if (mounted) setState(() => _selectedNav = 0);
                  },
                  onOrders: () {
                    if (mounted) setState(() => _selectedNav = 1);
                    _goToOrderHistory();
                  },
                  onProfile: () {
                    if (mounted) setState(() => _selectedNav = 2);
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

  List<ProductModel> _getFilteredProducts(List<ProductModel> products) {
    if (_selectedCategory == 'Todo') return products;
    return products.where((p) => p.category == _selectedCategory).toList();
  }

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
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}