import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategory = 0;
  int _selectedNav = 0;
  final List<Map<String, dynamic>> _cartItems = [];

  static const Color primary = Color(0xFF1A2F5E);
  static const Color primaryLight = Color(0xFF2A4A8E);
  static const Color background = Color(0xFFF5F7FB);
  static const Color textDark = Color(0xFF1A2F5E);
  static const Color textGrey = Color(0xFF7A8BA8);
  static const Color cardBg = Color(0xFFFFFFFF);

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Todo', 'icon': Icons.local_fire_department_rounded},
    {'label': 'Café Caliente', 'icon': Icons.coffee_rounded},
    {'label': 'Café Frío', 'icon': Icons.ac_unit_rounded},
    {'label': 'Pastelería', 'icon': Icons.cookie_outlined},
    {'label': 'Granos', 'icon': Icons.grass_rounded},
  ];

  final List<Map<String, dynamic>> _products = [
    {
      'name': 'Espresso Intenso',
      'category': 'Café Caliente',
      'categoryLabel': 'CAFÉ CALIENTE',
      'price': 3.50,
      'image': 'https://images.unsplash.com/photo-1510707577719-ae7c14805e3a?w=400',
    },
    {
      'name': 'Latte de Avena',
      'category': 'Café Caliente',
      'categoryLabel': 'CAFÉ CALIENTE',
      'price': 4.75,
      'image': 'https://images.unsplash.com/photo-1561882468-9110e03e0f78?w=400',
    },
    {
      'name': 'Cold Brew Vainilla',
      'category': 'Café Frío',
      'categoryLabel': 'COLD BREW',
      'price': 5.25,
      'image': 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400',
    },
    {
      'name': 'Iced Mocha',
      'category': 'Café Frío',
      'categoryLabel': 'COLD BREW',
      'price': 5.50,
      'image': 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400',
    },
    {
      'name': 'Croissant de Mantequilla',
      'category': 'Pastelería',
      'categoryLabel': 'PASTELERÍA',
      'price': 3.25,
      'image': 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400',
    },
    {
      'name': 'Muffin de Arándanos',
      'category': 'Pastelería',
      'categoryLabel': 'PASTELERÍA',
      'price': 3.50,
      'image': 'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=400',
    },
    {
      'name': 'Granos Etíopes 250g',
      'category': 'Granos',
      'categoryLabel': 'GRANOS',
      'price': 18.00,
      'image': 'https://images.unsplash.com/photo-1447933601403-0c6688de566e?w=400',
    },
    {
      'name': 'Mezcla de la Casa',
      'category': 'Granos',
      'categoryLabel': 'GRANOS',
      'price': 15.50,
      'image': 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400',
    },
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedCategory == 0) return _products;
    final cat = _categories[_selectedCategory]['label'];
    return _products.where((p) => p['category'] == cat).toList();
  }

  double get _cartTotal =>
      _cartItems.fold(0, (sum, item) => sum + item['price'] * item['qty']);

  int get _cartCount =>
      _cartItems.fold(0, (sum, item) => sum + (item['qty'] as int));

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final existing = _cartItems.indexWhere((i) => i['name'] == product['name']);
      if (existing >= 0) {
        _cartItems[existing]['qty']++;
      } else {
        _cartItems.add({...product, 'qty': 1});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firstName = user?.displayName?.split(' ').first ?? 'Usuario';

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.coffee_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'COFFEE SHOP',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.search_rounded,
                            color: textDark, size: 26),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hola, $firstName 👋',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: textGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Elige tu café',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: textDark,
                                ),
                              ),
                              const Text(
                                'Preparado con amor, servido fresco.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Categorías
                        SizedBox(
                          height: 44,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _categories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              final selected = _selectedCategory == i;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedCategory = i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected ? primary : Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: selected ? primary : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _categories[i]['icon'],
                                        size: 16,
                                        color: selected ? Colors.white : textGrey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _categories[i]['label'],
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: selected ? Colors.white : textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Grid de productos
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.78,
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, i) {
                              final product = _filteredProducts[i];
                              return _ProductCard(
                                product: product,
                                onAdd: () => _addToCart(product),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Banner novedad
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'Nuevo',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Mezcla de Temporada',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Prueba nuestro nuevo blend con\nnotas de chocolate y avellana.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.coffee_maker_outlined,
                                    size: 56, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Cart FAB
            if (_cartCount > 0)
              Positioned(
                bottom: 80,
                left: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.shopping_bag_outlined,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$_cartCount ${_cartCount == 1 ? 'Producto' : 'Productos'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '\$${_cartTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Ver carrito >',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom Nav
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.restaurant_menu_rounded,
                      label: 'Menú',
                      selected: _selectedNav == 0,
                      onTap: () => setState(() => _selectedNav = 0),
                    ),
                    _NavItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'Pedidos',
                      selected: _selectedNav == 1,
                      onTap: () => setState(() => _selectedNav = 1),
                    ),
                    _NavItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Perfil',
                      selected: _selectedNav == 2,
                      onTap: () => setState(() => _selectedNav = 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onAdd;

  const _ProductCard({required this.product, required this.onAdd});

  static const Color primary = Color(0xFF1A2F5E);
  static const Color textDark = Color(0xFF1A2F5E);
  static const Color textGrey = Color(0xFF7A8BA8);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: product['image'],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade100,
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.coffee_rounded,
                      color: Color(0xFF1A2F5E),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product['categoryLabel'],
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: textGrey,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '\$${product['price'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Color primary = Color(0xFF1A2F5E);
  static const Color textGrey = Color(0xFF7A8BA8);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? primary : textGrey, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? primary : textGrey,
            ),
          ),
        ],
      ),
    );
  }
}