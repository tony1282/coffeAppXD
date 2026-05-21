// lib/screens/orders/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/constants.dart';

class CartScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final VoidCallback onOrderPlaced;

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.onOrderPlaced,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<CartItem> _items;
  bool _isProcessing = false;
  bool _isConfirming = false;

  // ✅ Límites de cantidad
  static const int _minQuantity = 1;
  static const int _maxQuantityPerProduct = 99;
  static const int _maxTotalItems = 50;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.cartItems);
  }

  double get _total => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  void _removeItem(int index) {
    if (!mounted) return;
    setState(() => _items.removeAt(index));
  }

  void _updateQuantity(int index, int newQuantity) {
    if (!mounted) return;
    
    setState(() {
      if (newQuantity < _minQuantity) {
        _items.removeAt(index);
      } else if (newQuantity > _maxQuantityPerProduct) {
        _items[index].quantity = _maxQuantityPerProduct;
      } else {
        _items[index].quantity = newQuantity;
      }
    });
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
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

  // ✅ Validación de stock antes de pagar
  bool _validateStock() {
    for (final item in _items) {
      final product = item.product;
      if (product.stock != null && item.quantity > product.stock!) {
        _showErrorSnack('${product.name} solo tiene ${product.stock} unidades disponibles');
        return false;
      }
      if (!product.available) {
        _showErrorSnack('${product.name} ya no está disponible');
        return false;
      }
    }
    return true;
  }

  Future<bool> _showConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirmar pedido',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Total a pagar: \$${_total.toStringAsFixed(2)}\n\n¿Confirmas este pedido?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _placeOrder(String paymentMethod) async {
    // ✅ Prevenir spam
    if (_isProcessing || _isConfirming) return;

    if (_items.isEmpty) {
      _showErrorSnack('Tu carrito está vacío');
      return;
    }

    // ✅ Validar stock antes de continuar
    if (!_validateStock()) return;

    // ✅ Confirmar antes de pagar
    final confirmed = await _showConfirmDialog();
    if (!confirmed) return;

    setState(() => _isProcessing = true);

    String? createdOrderId;
    
    try {
      final userId = context.read<AuthProvider>().userModel?.userId;
      
      final orderData = {
        'user_id': userId,
        'items': _items.map((item) => {
          'product_id': item.product.id,
          'quantity': item.quantity,
        }).toList(),
        'payment_method': paymentMethod,
        'delivery_address': 'Calle Principal 123',
      };

      final orderProvider = context.read<OrderProvider>();
      final success = await orderProvider.createOrder(orderData);

      if (!mounted) return;

      if (success && orderProvider.orders.isNotEmpty) {
        createdOrderId = orderProvider.orders.first.id.toString();
        
        widget.onOrderPlaced();
        
        _showSuccessSnack('Pedido #$createdOrderId confirmado · Pago: $paymentMethod');
        
        if (mounted) {
          Navigator.popUntil(context, (r) => r.isFirst);
        }
      } else {
        throw Exception(orderProvider.errorMsg ?? 'Error al crear pedido');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnack('Error al procesar el pedido. Intenta de nuevo.');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showPaymentSheet() {
    if (_isProcessing) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PaymentMethodSheet(
        total: _total,
        isProcessing: _isProcessing,
        onConfirm: (method) {
          Navigator.pop(context);
          _placeOrder(method);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi carrito', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _items.isEmpty
          ? const Center(child: Text('Tu carrito está vacío', style: TextStyle(color: Colors.grey)))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final p = item.product;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                p.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.local_cafe, size: 40),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('\$${p.price.toStringAsFixed(2)}', style: TextStyle(color: AppColors.primary)),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, size: 18),
                                        onPressed: () => _updateQuantity(index, item.quantity - 1),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                      Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 18),
                                        onPressed: () {
                                          if (item.quantity < _maxQuantityPerProduct) {
                                            _updateQuantity(index, item.quantity + 1);
                                          } else {
                                            _showErrorSnack('Máximo $_maxQuantityPerProduct unidades por producto');
                                          }
                                        },
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeItem(index),
                              icon: const Icon(Icons.close_rounded, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text(
                            '\$${_total.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _showPaymentSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Confirmar pedido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

// ── Selección de método de pago ────────────────────────────────────
class _PaymentMethodSheet extends StatefulWidget {
  final double total;
  final bool isProcessing;
  final void Function(String method) onConfirm;

  const _PaymentMethodSheet({
    required this.total,
    required this.isProcessing,
    required this.onConfirm,
  });

  @override
  State<_PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends State<_PaymentMethodSheet> {
  String? _selected;

  final List<Map<String, dynamic>> _methods = [
    {'label': 'Efectivo', 'icon': Icons.money_rounded},
    {'label': 'Tarjeta', 'icon': Icons.credit_card_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Método de pago',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ..._methods.map((m) {
            final isSelected = _selected == m['label'];
            return GestureDetector(
              onTap: () => setState(() => _selected = m['label'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(m['icon'] as IconData, color: isSelected ? AppColors.primary : Colors.grey),
                    const SizedBox(width: 12),
                    Text(
                      m['label'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primary : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected) 
                      const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total a pagar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(
                '\$${widget.total.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isProcessing || _selected == null
                  ? null
                  : () => widget.onConfirm(_selected!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Confirmar pago', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}