import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/ui/custom_dialogs.dart';
import '../../../data/models/product_model.dart';
// lib/presentation/screens/products/product_detail_screen.dart

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onAddToCart;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isAdding = false;
  int _quantity = 1;

  static const int _minQuantity = 1;
  static const int _maxQuantity = 10;

  bool _canAddToCart() {
    if (widget.product.stock != null && widget.product.stock! <= 0) {
      CustomDialogs.showError(context, 'Este producto no está disponible');
      return false;
    }

    if (!widget.product.available) {
      CustomDialogs.showError(context, 'Este producto no está disponible');
      return false;
    }

    if (widget.product.stock != null && _quantity > widget.product.stock!) {
      CustomDialogs.showError(
        context,
        'Solo hay ${widget.product.stock} unidades disponibles',
      );
      return false;
    }

    return true;
  }

  Future<void> _addToCart() async {
    if (_isAdding) return;

    if (!_canAddToCart()) return;

    setState(() => _isAdding = true);

    try {
      for (int i = 0; i < _quantity; i++) {
        widget.onAddToCart();
      }

      if (mounted) {
        final message = _quantity > 1
            ? '${widget.product.name} agregado al carrito x$_quantity'
            : '${widget.product.name} agregado al carrito';
        CustomDialogs.showSuccess(context, message);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomDialogs.showError(context, 'Error al agregar el producto');
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  void _increaseQuantity() {
    if (_quantity >= _maxQuantity) {
      CustomDialogs.showError(
          context, 'Máximo $_maxQuantity unidades por producto');
      return;
    }
    if (widget.product.stock != null && _quantity >= widget.product.stock!) {
      CustomDialogs.showError(
        context,
        'Solo hay ${widget.product.stock} unidades disponibles',
      );
      return;
    }
    setState(() => _quantity++);
  }

  void _decreaseQuantity() {
    if (_quantity > _minQuantity) {
      setState(() => _quantity--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOutOfStock =
        widget.product.stock != null && widget.product.stock! <= 0;
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width >= 700 ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: Text(
          widget.product.name,
          style: AppTextStyles.titleMedium,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagen ──────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _buildProductImage(),
            ),
            const SizedBox(height: 20),

            // ── Nombre ─────────────────────────────────────────
            Text(
              widget.product.name,
              style: AppTextStyles.displaySmall,
            ),
            const SizedBox(height: 4),

            // ── Descripción ────────────────────────────────────
            Text(
              widget.product.description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 12),

            // ── Precio ─────────────────────────────────────────
            Text(
              '\$${widget.product.price.toStringAsFixed(2)}',
              style: AppTextStyles.priceLarge,
            ),

            // ── Selector de cantidad ──────────────────────────
            if (widget.product.stock != null && widget.product.stock! > 0) ...[
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cantidad:',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: _decreaseQuantity,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      color: AppColors.textDark,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$_quantity',
                        style: AppTextStyles.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: _increaseQuantity,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ── Botón agregar ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isAdding || isOutOfStock) ? null : _addToCart,
                icon: _isAdding
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.shopping_bag_outlined),
                label: _isAdding
                    ? const Text('Agregando...')
                    : isOutOfStock
                        ? const Text('Agotado')
                        : Text(
                            'Agregar al carrito${_quantity > 1 ? " ($_quantity)" : ""}',
                          ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isOutOfStock ? Colors.grey : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            // ── Stock disponible ──────────────────────────────
            if (widget.product.stock != null && widget.product.stock! > 0) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '${widget.product.stock} unidades disponibles',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textGrey,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    final imageUrl = widget.product.imageUrl;

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 220,
            color: AppColors.surface,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: AppColors.primary,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          height: 220,
          width: double.infinity,
          color: AppColors.surface,
          child: Icon(
            Icons.broken_image,
            size: 60,
            color: AppColors.textGrey,
          ),
        ),
      );
    } else {
      return Image.asset(
        imageUrl,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 220,
          width: double.infinity,
          color: AppColors.surface,
          child: Icon(
            Icons.local_cafe,
            size: 60,
            color: AppColors.textGrey,
          ),
        ),
      );
    }
  }
}
