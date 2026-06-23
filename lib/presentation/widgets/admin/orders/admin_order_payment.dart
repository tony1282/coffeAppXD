// lib/presentation/screens/admin/orders/widgets/admin_order_payment.dart

import 'package:flutter/material.dart';
import '../../../../../core/config/constants.dart';
import '../../../../../core/config/order_status_config.dart';
import '../../../../../core/theme/text_styles.dart';

class AdminOrderPayment extends StatelessWidget {
  final dynamic order;

  const AdminOrderPayment({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final pColor = OrderStatusConfig.paymentColors[order.paymentStatus] ?? AppColors.textGrey;
    final pLabel = OrderStatusConfig.paymentLabels[order.paymentStatus] ?? 'Pendiente';
    final pIcon = OrderStatusConfig.paymentIcons[order.paymentStatus] ?? Icons.payment_rounded;

    final subtotal = order.items?.fold<double>(0, (s, i) => s + (i.price * i.quantity)) ?? 0.0;
    final deliveryFee = 35.0; // TODO: obtener del backend
    final total = order.total ?? 0.0;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: pColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: pColor.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Icon(pIcon, color: pColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pLabel, style: TextStyle(color: pColor, fontSize: 12, fontWeight: FontWeight.w800)),
                    Text(
                      'Método: ${order.paymentMethod ?? 'No especificado'}',
                      style: TextStyle(color: pColor.withOpacity(0.7), fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        _PaymentRow(label: 'Subtotal', value: '\$${subtotal.toStringAsFixed(2)}'),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        _PaymentRow(label: 'Envío', value: '\$${deliveryFee.toStringAsFixed(2)}', badge: 'domicilio'),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        _PaymentRow(label: 'Total', value: '\$${total.toStringAsFixed(2)}', isHighlight: true),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final String value;
  final String? badge;
  final bool isHighlight;

  const _PaymentRow({
    required this.label,
    required this.value,
    this.badge,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: isHighlight ? 12 : 10),
      child: Row(
        children: [
          Text(
            label,
            style: isHighlight ? AppTextStyles.titleSmall : AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey),
          ),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.textGrey.withOpacity(0.10),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(badge!, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textGrey)),
            ),
          ],
          const Spacer(),
          Text(
            value,
            style: isHighlight
                ? AppTextStyles.titleLarge.copyWith(color: AppColors.warning)
                : AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}