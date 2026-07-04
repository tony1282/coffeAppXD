// lib/presentation/widgets/admin/orders/admin_refund_status.dart

import 'package:flutter/material.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/models/payment_model.dart';

class AdminRefundStatus extends StatelessWidget {
  final Order order;
  final Payment? payment;

  const AdminRefundStatus({
    super.key,
    required this.order,
    this.payment,
  });

  @override
  Widget build(BuildContext context) {
    // Si el pedido no está cancelado, no mostrar
    if (order.status != 'cancelled') {
      return const SizedBox.shrink();
    }

    // Si no hay pago o no es con tarjeta
    if (payment == null || payment!.method != 'card') {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.textGrey, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pedido cancelado. El reembolso solo aplica a pagos con tarjeta.',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isRefunded = payment!.refundedAmount != null && payment!.refundedAmount! > 0;
    final isFullRefund = isRefunded && payment!.refundedAmount! >= payment!.amount;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isFullRefund 
            ? AppColors.success.withOpacity(0.1)
            : isRefunded
                ? Colors.orange.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFullRefund
              ? AppColors.success.withOpacity(0.3)
              : isRefunded
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFullRefund 
                    ? Icons.check_circle_rounded
                    : isRefunded
                        ? Icons.currency_exchange_rounded
                        : Icons.pending_rounded,
                color: isFullRefund
                    ? AppColors.success
                    : isRefunded
                        ? Colors.orange
                        : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isFullRefund
                      ? '✅ Reembolso completo procesado'
                      : isRefunded
                          ? '🔄 Reembolso parcial procesado'
                          : '⏳ Reembolso pendiente de procesar',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isFullRefund
                        ? AppColors.success
                        : isRefunded
                            ? Colors.orange
                            : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          if (isRefunded) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monto reembolsado:',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textGrey,
                  ),
                ),
                Text(
                  '\$${payment!.refundedAmount!.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            if (payment!.refundedAt != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fecha:',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                  Text(
                    _formatDate(payment!.refundedAt!),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ],
            if (payment!.refundReason != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Motivo:',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      payment!.refundReason!,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textGrey,
                      ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
          if (!isRefunded && order.status == 'cancelled') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El reembolso se procesará automáticamente.\n'
                    'Puede tardar 24-48 horas hábiles en reflejarse.',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}