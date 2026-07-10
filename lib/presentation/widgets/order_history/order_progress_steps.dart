// lib/presentation/widgets/order/order_progress_steps.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/constants.dart';
import '../../../core/config/order_status_config.dart';
import '../../../core/theme/text_styles.dart';
import '../../../presentation/providers/auth_provider.dart';

class OrderProgressSteps extends StatelessWidget {
  final String status;

  const OrderProgressSteps({super.key, required this.status});

  int get _activeIndex {
    switch (status) {
      case 'pending':
        return 0;
      case 'confirmed':
        return 1;
      case 'preparing':
        return 2;
      case 'shipped':
        return 3;
      case 'delivered':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    
    // ✅ Elegir los pasos correctos según el rol
    final steps = isAdmin
        ? OrderStatusConfig.adminStepper
        : OrderStatusConfig.clientStepper;

    final active = _activeIndex;
    final isCancelled = status == 'cancelled';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isDone = !isCancelled && i < active;
          final isActive = !isCancelled && i == active;
          final isLast = i == steps.length - 1;

          Color dotBg;
          Color dotFg;
          Color lineColor;

          if (isCancelled) {
            dotBg = const Color(0xFFFEE2E2);
            dotFg = AppColors.error;
            lineColor = const Color(0xFFE5E7EB);
          } else if (isDone) {
            dotBg = const Color(0xFF10B981);
            dotFg = Colors.white;
            lineColor = const Color(0xFF10B981);
          } else if (isActive) {
            dotBg = AppColors.primary;
            dotFg = Colors.white;
            lineColor = const Color(0xFFE5E7EB);
          } else {
            dotBg = const Color(0xFFF3F4F6);
            dotFg = const Color(0xFF9CA3AF);
            lineColor = const Color(0xFFE5E7EB);
          }

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (!isLast)
                            Align(
                              alignment: Alignment.centerRight,
                              child: FractionallySizedBox(
                                widthFactor: 0.5,
                                child: Container(
                                  height: 2,
                                  color: lineColor,
                                ),
                              ),
                            ),
                          if (i > 0)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: 0.5,
                                child: Container(
                                  height: 2,
                                  color: i <= active && !isCancelled
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                            ),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: dotBg,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 15)
                                  : Text(
                                      _getEmoji(i),
                                      style: TextStyle(
                                        fontSize: isActive ? 14 : 12,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        steps[i],
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isActive
                              ? AppColors.primary
                              : isDone
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF9CA3AF),
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getEmoji(int index) {
    const emojis = ['📋', '✅', '☕', '🚴', '🏠'];
    return emojis[index];
  }
}