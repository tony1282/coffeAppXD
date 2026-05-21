// lib/screens/products/product_detail_screen.dart

import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../config/constants.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
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

  bool _canAddToCart() {
    // ✅ Validar stock
    if (widget.product.stock != null && widget.product.stock! <= 0) {
      _showErrorSnack('Este producto no está disponible');
      return false;
    }
    
    // ✅ Validar disponibilidad
    if (!widget.product.available) {
      _showErrorSnack('Este producto no está disponible');
      return false;
    }
    
    // ✅ Validar cantidad vs stock
    if (widget.product.stock != null && _quantity > widget.product.stock!) {
      _showErrorSnack('Solo hay ${widget.product.stock} unidades disponibles');
      return false;
    }
    
    return true;
  }

  Future<void> _addToCart() async {
    if (_isAdding) return;
    
    if (!_canAddToCart()) return;

    setState(() => _isAdding = true);

    try {
      // Agregar múltiples veces según cantidad
      for (int i = 0; i < _quantity; i++) {
        widget.onAddToCart();
      }
      
      if (mounted) {
        _showSuccessSnack('${widget.product.name} agregado al carrito${_quantity > 1 ? " x$_quantity" : ""}');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnack('Error al agregar el producto');
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  void _increaseQuantity() {
    if (_quantity >= _maxQuantity) {
      _showErrorSnack('Máximo $_maxQuantity unidades por producto');
      return;
    }
    if (widget.product.stock != null && _quantity >= widget.product.stock!) {
      _showErrorSnack('Solo hay ${widget.product.stock} unidades disponibles');
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          widget.product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Imagen con soporte para URL y asset
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _buildProductImage(),
            ),
            const SizedBox(height: 20),
            Text(
              widget.product.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.product.description,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              '\$${widget.product.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // ✅ Selector de cantidad
            if (widget.product.stock != null && widget.product.stock! > 0) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Cantidad:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: _decreaseQuantity,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: _increaseQuantity,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // ✅ Botón de agregar (deshabilitado si no hay stock)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isAdding || (widget.product.stock != null && widget.product.stock! <= 0))
                    ? null
                    : _addToCart,
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
                    : (widget.product.stock != null && widget.product.stock! <= 0)
                        ? const Text('Agotado')
                        : Text('Agregar al carrito${_quantity > 1 ? " ($_quantity)" : ""}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (widget.product.stock != null && widget.product.stock! <= 0)
                      ? Colors.grey
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    final imageUrl = widget.product.imageUrl;
    
    // ✅ Determinar si es asset o network
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
            color: Colors.grey.shade100,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: AppColors.primary,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          height: 220,
          width: double.infinity,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
        ),
      );
    } else {
      // Asset local
      return Image.asset(
        imageUrl,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 220,
          width: double.infinity,
          color: Colors.grey.shade200,
          child: const Icon(Icons.local_cafe, size: 60, color: Colors.grey),
        ),
      );
    }
  }
}