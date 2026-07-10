// lib/presentation/widgets/order/payment_status_badge.dart

import 'package:coffe_app/core/config/constants.dart';
import 'package:flutter/material.dart';
import '../../../core/config/order_status_config.dart';
import '../../../core/theme/text_styles.dart';

class PaymentStatusBadge extends StatelessWidget {
  final String paymentStatus;
  final bool isSmall;

  const PaymentStatusBadge({
    super.key,
    required this.paymentStatus,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final pColor = OrderStatusConfig.paymentColors[paymentStatus] ?? AppColors.textGrey;
    final pLabel = OrderStatusConfig.paymentLabels[paymentStatus] ?? 'Pendiente';
    final pIcon = OrderStatusConfig.paymentIcons[paymentStatus] ?? Icons.payment_rounded;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 10,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: pColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pColor.withOpacity(0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pIcon,
            color: pColor,
            size: isSmall ? 10 : 14,
          ),
          const SizedBox(width: 4),
          Text(
            pLabel,
            style: TextStyle(
              color: pColor,
              fontSize: isSmall ? 9 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}