// lib/presentation/widgets/cart/cart_order_summary.dart
//
// NUEVO WIDGET — muestra subtotal, impuestos y total.
// Uso: CartOrderSummary(total: _total)

import 'package:flutter/material.dart';
import '../../../core/config/constants.dart';
import '../../../core/theme/text_styles.dart';

class CartOrderSummary extends StatelessWidget {
  final double total;

  const CartOrderSummary({super.key, required this.total});

  @override
  Widget build(BuildContext context) {
    final subtotal = total / 1.08;
    final tax = total - subtotal;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Subtotal',
            value: '\$${subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Impuestos (8%)',
            value: '\$${tax.toStringAsFixed(2)}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}