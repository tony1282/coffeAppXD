// lib/presentation/screens/orders/cart_screen.dart

import 'package:coffe_app/data/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as custom_tabs;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/ui/custom_dialogs.dart';
import '../../../presentation/providers/auth_provider.dart' as app_auth;
import '../../../presentation/providers/cart_provider.dart';
import '../../../presentation/providers/order_provider.dart';
import '../../../presentation/providers/payment_provider.dart';
import '../../widgets/cart/cart_delivery_banner.dart';
import '../../widgets/cart/cart_item_tile.dart';
import '../../widgets/cart/cart_order_summary.dart';
import '../../widgets/cart/cart_payment_row.dart';
import '../../widgets/cart/cart_checkout_bar.dart';
import '../../widgets/cart/cart_empty_state.dart';
import '../../widgets/cart/payment_method_sheet.dart';

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
  late CartProvider _cartProvider;

  int? _pendingOrderId;
  double? _pendingAmount;
  String? _selectedMethod;
  String? _currentPreferenceId;

  static const int _minQuantity = 1;
  static const int _maxQuantityPerProduct = 99;
  static const Duration _webhookTimeout = Duration(seconds: 8);
  static const int _maxVerificationAttempts = 6;

  static const String _paymentMethod = 'Tarjeta';

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.cartItems);
    _cartProvider = context.read<CartProvider>();
    _selectedMethod = _paymentMethod;
  }

  double get _total =>
      _items.fold(0.0, (sum, item) => sum + item.subtotal);

  void _removeItem(int index) {
    if (!mounted) return;
    _cartProvider.remove(_items[index].product);
    setState(() => _items.removeAt(index));
  }

  void _updateQuantity(int index, int newQuantity) {
    if (!mounted) return;
    setState(() {
      if (newQuantity < _minQuantity) {
        _cartProvider.remove(_items[index].product);
        _items.removeAt(index);
      } else if (newQuantity > _maxQuantityPerProduct) {
        _items[index].quantity = _maxQuantityPerProduct;
        _cartProvider.updateQuantity(
            _items[index].product, _maxQuantityPerProduct);
      } else {
        _items[index].quantity = newQuantity;
        _cartProvider.updateQuantity(_items[index].product, newQuantity);
      }
    });
  }

  bool _validateStock() {
    for (final item in _items) {
      final product = item.product;
      if (product.stock != null && item.quantity > product.stock!) {
        CustomDialogs.showError(
          context,
          '${product.name} solo tiene ${product.stock} unidades disponibles',
        );
        return false;
      }
      if (!product.available) {
        CustomDialogs.showError(
            context, '${product.name} ya no está disponible');
        return false;
      }
    }
    return true;
  }

  Future<bool> _showConfirmDialog() async {
    return await CustomDialogs.showConfirm(
          context: context,
          title: 'Confirmar pedido',
          message:
              'Total a pagar: \$${_total.toStringAsFixed(2)}\n\n'
              'Método de pago: Tarjeta\n\n'
              '¿Confirmas este pedido?',
          confirmText: 'Confirmar',
          cancelText: 'Cancelar',
          confirmColor: AppColors.primary,
        ) ??
        false;
  }

  // ────────────────────────────────────────────────────────────────
  // 🔥 OBTENER MENSAJE DE ERROR ESPECÍFICO
  // ────────────────────────────────────────────────────────────────
  String _getPaymentErrorMessage(String status, String? detail) {
    switch (status) {
      case 'rejected':
        if (detail?.contains('insufficient') ?? false) {
          return 'Fondos insuficientes. Intenta con otra tarjeta.';
        }
        if (detail?.contains('expired') ?? false) {
          return 'La tarjeta ha expirado.';
        }
        if (detail?.contains('security') ?? false) {
          return 'Código de seguridad inválido.';
        }
        if (detail?.contains('blocked') ?? false) {
          return 'Tarjeta bloqueada. Contacta a tu banco.';
        }
        if (detail?.contains('limit') ?? false) {
          return 'Límite de gasto excedido.';
        }
        if (detail?.contains('duplicate') ?? false) {
          return 'Este pago ya fue procesado.';
        }
        if (detail?.contains('invalid') ?? false) {
          return 'Número de tarjeta inválido.';
        }
        if (detail?.contains('installment') ?? false) {
          return 'Cuotas no disponibles.';
        }
        return 'El pago fue rechazado. Intenta de nuevo.';
      case 'pending':
        return 'Tu pago está en proceso. Te notificaremos cuando sea confirmado.';
      case 'in_process':
        return 'Tu banco está validando el pago. Esto puede tardar unos minutos.';
      case 'not_found':
        return 'No se encontró el pago. Intenta de nuevo.';
      case 'error':
        return 'Error al verificar el pago. Intenta de nuevo.';
      default:
        return 'No se pudo procesar el pago. Intenta de nuevo.';
    }
  }

  // ────────────────────────────────────────────────────────────────
  // 🔥 VERIFICAR DIRECTAMENTE EN MERCADO PAGO
  // ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _verifyDirectlyWithMercadoPago(String preferenceId) async {
    final paymentProvider = context.read<PaymentProvider>();
    return await paymentProvider.verifyPayment(preferenceId);
  }

  // ────────────────────────────────────────────────────────────────
  // 🔥 ESPERAR WEBHOOK CON TIMEOUT Y FALLBACK
  // ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _waitForPaymentConfirmation(
    String preferenceId,
    String userId,
  ) async {
    int attempts = 0;
    
    while (attempts < _maxVerificationAttempts) {
      await Future.delayed(const Duration(seconds: 3));
      attempts++;
      
      // Refrescar pedidos
      final orderProvider = context.read<OrderProvider>();
      await orderProvider.fetchOrders();
      
      // Buscar el pedido más reciente del usuario
      final orders = orderProvider.orders;
      final newOrder = orders.cast<Order?>().firstWhere(
        (o) => o?.userId == userId && o?.paymentStatus != 'failed' && o?.paymentStatus != 'rejected',
        orElse: () => orders.firstOrNull,
      );
      
      if (newOrder != null && (newOrder.paymentStatus == 'completed' || newOrder.paymentStatus == 'paid')) {
        return {
          'status': 'approved',
          'order_id': newOrder.id,
          'payment_status': newOrder.paymentStatus,
        };
      }
      
      if (newOrder != null && newOrder.paymentStatus == 'pending') {
        // Si sigue pendiente después de varios intentos, verificar directamente
        if (attempts >= 3) {
          final verification = await _verifyDirectlyWithMercadoPago(preferenceId);
          return verification;
        }
      }
    }
    
    // ⏰ Timeout - verificar directamente en MP
    return await _verifyDirectlyWithMercadoPago(preferenceId);
  }

  // ────────────────────────────────────────────────────────────────
  // 🔥 PROCESAR PAGO COMPLETO
  // ────────────────────────────────────────────────────────────────
  Future<void> _processMercadoPagoPayment(Map<String, dynamic> orderData) async {
    final paymentProvider = context.read<PaymentProvider>();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      // 1️⃣ Crear preferencia
      final preference = await paymentProvider.createMercadoPagoPreference(
        orderData: orderData,
      );
      _currentPreferenceId = preference.preferenceId;

      if (!mounted) return;

      // 2️⃣ Abrir Custom Tab
      try {
        await custom_tabs.launchUrl(
          Uri.parse(preference.initPoint),
          customTabsOptions: custom_tabs.CustomTabsOptions(
            colorSchemes: custom_tabs.CustomTabsColorSchemes.defaults(
              toolbarColor: AppColors.primary,
            ),
            showTitle: true,
            urlBarHidingEnabled: true,
            closeButton: custom_tabs.CustomTabsCloseButton(
              icon: custom_tabs.CustomTabsCloseButtonIcons.back,
            ),
            animations: const custom_tabs.CustomTabsAnimations(
              startEnter: 'slide_up',
              startExit: 'android:anim/fade_out',
              endEnter: 'android:anim/fade_in',
              endExit: 'slide_down',
            ),
          ),
          safariVCOptions: custom_tabs.SafariViewControllerOptions(
            preferredBarTintColor: AppColors.primary,
            preferredControlTintColor: Colors.white,
            barCollapsingEnabled: true,
            dismissButtonStyle: custom_tabs.SafariViewControllerDismissButtonStyle.close,
          ),
        );
      } catch (e) {
        print('⚠️ Custom Tabs falló, usando navegador: $e');
        await launchUrl(
          Uri.parse(preference.initPoint),
          mode: LaunchMode.externalApplication,
        );
      }

      if (!mounted) return;

      // 3️⃣ Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              SizedBox(height: 16),
              Text(
                'Verificando pago...',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

      // 4️⃣ Esperar webhook con timeout
      final result = await _waitForPaymentConfirmation(
        preference.preferenceId,
        userId,
      );

      if (!mounted) {
        Navigator.pop(context);
        return;
      }

      Navigator.pop(context); // Cerrar loading

      // 5️⃣ Procesar resultado
      final status = result['status'];

      if (status == 'approved' || status == 'completed') {
        // ✅ Éxito
        final orderId = result['order_id'];
        widget.onOrderPlaced();
        if (mounted) {
          Navigator.popUntil(context, (r) => r.isFirst);
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            CustomDialogs.showSuccess(
                context, '¡Pago exitoso! Pedido #$orderId confirmado');
          }
        }
      } else if (status == 'pending' || status == 'in_process') {
        // ⏳ Pendiente
        widget.onOrderPlaced();
        if (mounted) {
          Navigator.popUntil(context, (r) => r.isFirst);
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            CustomDialogs.showSuccess(
                context,
                'Pedido registrado. Tu pago está pendiente de confirmación.\n'
                'Te notificaremos cuando sea aprobado.');
          }
        }
      } else if (status == 'failed' || status == 'rejected') {
        // ❌ Fallido con mensaje específico
        final detail = result['payment_detail'] as String?;
        final errorMsg = _getPaymentErrorMessage('rejected', detail);
        if (mounted) {
          CustomDialogs.showError(context, errorMsg);
        }
      } else if (status == 'not_found') {
        // ⚠️ No se encontró el pago
        if (mounted) {
          CustomDialogs.showError(
              context, 'No se encontró el pago. Intenta de nuevo.');
        }
      } else {
        // ❌ Error genérico
        if (mounted) {
          CustomDialogs.showError(
              context, 'No se pudo confirmar el pago. Intenta de nuevo.');
        }
      }

    } catch (e) {
      print('❌ Error en pago: $e');
      if (mounted) {
        Navigator.pop(context);
        CustomDialogs.showError(
            context, 'Error al procesar el pago. Intenta de nuevo.');
      }
    } finally {
      // Liberar lock
      if (_pendingOrderId != null && _pendingAmount != null) {
        paymentProvider.releasePaymentLock(
          orderId: _pendingOrderId!,
          userId: userId,
          amount: _pendingAmount!,
        );
        _pendingOrderId = null;
        _pendingAmount = null;
      }
    }
  }

  // ────────────────────────────────────────────────────────────────
  // 🔥 PLACE ORDER
  // ────────────────────────────────────────────────────────────────
  Future<void> _placeOrder() async {
    if (_isProcessing) return;
    if (_items.isEmpty) {
      CustomDialogs.showError(context, 'Tu carrito está vacío');
      return;
    }
    if (!_validateStock()) return;

    final confirmed = await _showConfirmDialog();
    if (!confirmed) return;

    setState(() => _isProcessing = true);

    try {
      final userId = context.read<app_auth.AuthProvider>().userModel?.userId;

      final orderData = {
        'user_id': userId,
        'items': _items.map((item) => {
          'product_id': item.product.id,
          'product_name': item.product.name,
          'quantity': item.quantity,
          'price': item.product.price,
        }).toList(),
        'total': _total,
        'delivery_address': 'Calle Principal 123',
      };

      await _processMercadoPagoPayment(orderData);

    } catch (e) {
      if (mounted) {
        CustomDialogs.showError(
            context, 'Error al procesar el pedido. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showPaymentSheet() {
    if (_isProcessing) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => PaymentMethodSheet(
        total: _total,
        isProcessing: _isProcessing,
        onConfirm: (method) {
          Navigator.pop(context);
          setState(() => _selectedMethod = method);
          _placeOrder();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: AppColors.textDark,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu carrito',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            if (_items.isNotEmpty)
              Text(
                '${_items.length} artículo${_items.length == 1 ? '' : 's'}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textGrey,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: _items.isEmpty
          ? const CartEmptyState()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CartDeliveryBanner(
                          address: 'Calle Principal 123',
                          onChangeTap: () {},
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tus productos',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_items.length} artículo${_items.length == 1 ? '' : 's'}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return CartItemTile(
                              item: _items[index],
                              onRemove: () => _removeItem(index),
                              onQuantityChanged: (qty) =>
                                  _updateQuantity(index, qty),
                            );
                          },
                        ),
                        CartOrderSummary(total: _total),
                        CartPaymentRow(
                          method: _selectedMethod ?? 'Tarjeta',
                          onTap: _showPaymentSheet,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                CartCheckoutBar(
                  total: _total,
                  isProcessing: _isProcessing,
                  onTap: _showPaymentSheet,
                ),
              ],
            ),
    );
  }
}