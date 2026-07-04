// lib/presentation/screens/admin/orders/widgets/admin_order_payment.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/config/constants.dart';
import '../../../../../core/config/order_status_config.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../data/models/order_model.dart';
import '../../../../../data/models/payment_model.dart';
import '../../../../../presentation/providers/payment_provider.dart';
import '../../../../../presentation/widgets/admin/orders/admin_refund_status.dart'; // ✅ NUEVO

class AdminOrderPayment extends StatelessWidget {
  final dynamic order;

  const AdminOrderPayment({super.key, required this.order});

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, _) {
        // Buscar el pago asociado a esta orden
        final payment = paymentProvider.payments.firstWhere(
          (p) => p.orderId == order.id?.toString(),
          orElse: () => Payment(
            id: null,
            orderId: order.id?.toString(),
            amount: _toDouble(order.total ?? 0),
            method: order.paymentMethod ?? 'cash',
            status: order.paymentStatus ?? 'pending',
            createdAt: DateTime.now(),
          ),
        );

        final pColor = OrderStatusConfig.paymentColors[order.paymentStatus] ?? AppColors.textGrey;
        final pLabel = OrderStatusConfig.paymentLabels[order.paymentStatus] ?? 'Pendiente';
        final pIcon = OrderStatusConfig.paymentIcons[order.paymentStatus] ?? Icons.payment_rounded;

        // Calcular subtotal
        double subtotal = 0.0;
        final items = order.items;
        if (items != null && items is List) {
          for (final item in items) {
            final price = _toDouble(item.price);
            final quantity = item.quantity ?? 0;
            subtotal += price * quantity;
          }
        }

        final deliveryFee = 35.0;
        final total = _toDouble(order.total ?? 0);

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
                        Text(
                          pLabel,
                          style: TextStyle(
                            color: pColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Método: ${order.paymentMethod ?? 'No especificado'}',
                          style: TextStyle(
                            color: pColor.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Divider(height: 1, color: AppColors.divider),
            _PaymentRow(
              label: 'Subtotal',
              value: '\$${subtotal.toStringAsFixed(2)}',
            ),
            const Divider(height: 1, color: AppColors.divider),
            _PaymentRow(
              label: 'Envío',
              value: '\$${deliveryFee.toStringAsFixed(2)}',
              badge: 'domicilio',
            ),
            const Divider(height: 1, color: AppColors.divider),
            _PaymentRow(
              label: 'Total',
              value: '\$${total.toStringAsFixed(2)}',
              isHighlight: true,
            ),
            
            // ✅ Estado de reembolso para pedidos cancelados
            if (order.status == 'cancelled')
              AdminRefundStatus(
                order: order,
                payment: payment,
              ),
          ],
        );
      },
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
            style: isHighlight
                ? AppTextStyles.titleSmall
                : AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey),
          ),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.textGrey.withOpacity(0.10),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                badge!,
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textGrey),
              ),
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