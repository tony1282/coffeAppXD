// lib/presentation/widgets/cart/cart_item_tile.dart
//
// Reemplaza el item inline en CartScreen.
// Uso: CartItemTile(item: item, onRemove: ..., onQuantityChanged: ...)

import 'package:flutter/material.dart';
import '../../../core/config/constants.dart';
import '../../../core/theme/text_styles.dart';
import '../../../presentation/providers/cart_provider.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = item.product;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              p.imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_cafe_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${p.price.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Quantity controls + delete
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Delete button when qty == 1, minus otherwise
              _QuantityControls(
                quantity: item.quantity,
                onDecrement: () => onQuantityChanged(item.quantity - 1),
                onIncrement: () => onQuantityChanged(item.quantity + 1),
                onRemove: onRemove,
              ),
              const SizedBox(height: 6),
              // Subtotal
              Text(
                '\$${item.subtotal.toStringAsFixed(2)}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityControls extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onRemove;

  const _QuantityControls({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Left button: trash if qty==1, minus otherwise
          GestureDetector(
            onTap: quantity <= 1 ? onRemove : onDecrement,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: quantity <= 1
                    ? const Color(0xFFFEE2E2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                quantity <= 1
                    ? Icons.delete_outline_rounded
                    : Icons.remove_rounded,
                size: 16,
                color: quantity <= 1
                    ? AppColors.error
                    : const Color(0xFF6B7280),
              ),
            ),
          ),

          // Count
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),

          // Plus
          GestureDetector(
            onTap: onIncrement,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}