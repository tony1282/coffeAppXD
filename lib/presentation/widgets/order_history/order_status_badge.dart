// lib/presentation/widgets/order/order_status_badge.dart

import 'package:flutter/material.dart';
import '../../../core/config/constants.dart';
import '../../../core/theme/text_styles.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;
  final bool isSmall;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.isSmall = false,
  });

  Color get _statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return AppColors.primary;
      case 'preparing':
        return const Color(0xFFF59E0B);
      case 'shipped':
        return const Color(0xFF10B981);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textGrey;
    }
  }

  Color get _statusBg {
    switch (status) {
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'confirmed':
        return const Color(0xFFEEF1FF);
      case 'preparing':
        return const Color(0xFFFEF3C7);
      case 'shipped':
        return const Color(0xFFD1FAE5);
      case 'delivered':
        return const Color(0xFFD1FAE5);
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color get _statusTextColor {
    switch (status) {
      case 'pending':
        return const Color(0xFF92400E);
      case 'confirmed':
        return AppColors.primary;
      case 'preparing':
        return const Color(0xFF92400E);
      case 'shipped':
        return const Color(0xFF065F46);
      case 'delivered':
        return const Color(0xFF065F46);
      case 'cancelled':
        return const Color(0xFF991B1B);
      default:
        return AppColors.textGrey;
    }
  }

  String get _statusText {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'confirmed':
        return 'Confirmado';
      case 'preparing':
        return 'Preparando';
      case 'shipped':
        return 'En camino';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _statusBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _statusText,
            style: (isSmall
                    ? AppTextStyles.labelSmall
                    : AppTextStyles.labelMedium)
                .copyWith(
              color: _statusTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}