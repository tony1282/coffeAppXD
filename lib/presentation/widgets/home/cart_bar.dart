import 'package:flutter/material.dart';
import 'package:coffe_app/core/config/constants.dart';
// lib/presentation/widgets/home/cart_bar.dart

class CartBar extends StatefulWidget {
  final int itemCount;
  final double total;
  final VoidCallback onTap;

  const CartBar({
    super.key,
    required this.itemCount,
    required this.total,
    required this.onTap,
  });

  @override
  State<CartBar> createState() => _CartBarState();
}

class _CartBarState extends State<CartBar> {
  bool _tapped = false;

  void _handleTap() {
    if (_tapped) return;
    _tapped = true;
    widget.onTap();
    // Reset después de 1 segundo para permitir volver a tocar
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _tapped = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        MediaQuery.of(context).size.width > 700 ? 24.0 : 16.0;

    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        margin: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ícono con badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag_rounded, color: Colors.white),
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.itemCount}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'TOTAL ACTUAL',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${widget.itemCount} ${widget.itemCount == 1 ? 'Producto' : 'Productos'} • \$${widget.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ver carrito',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 3),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
