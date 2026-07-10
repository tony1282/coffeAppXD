// lib/presentation/widgets/order/order_status_badge.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/constants.dart';
import '../../../core/config/order_status_config.dart';
import '../../../core/theme/text_styles.dart';
import '../../../presentation/providers/auth_provider.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;
  final bool isSmall;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    
    final label = isAdmin
        ? OrderStatusConfig.adminLabels[status] ?? status
        : OrderStatusConfig.clientLabels[status] ?? status;

    final color = OrderStatusConfig.colors[status] ?? AppColors.textGrey;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: (isSmall
                    ? AppTextStyles.labelSmall
                    : AppTextStyles.labelMedium)
                .copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}