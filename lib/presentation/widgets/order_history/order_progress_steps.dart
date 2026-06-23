// lib/presentation/widgets/order/order_progress_steps.dart
//
// NUEVO WIDGET — agrégalo a tu proyecto.
// Muestra el progreso del pedido como pasos conectados.
// Uso: OrderProgressSteps(status: order.status)

import 'package:flutter/material.dart';
import '../../../core/config/constants.dart';
import '../../../core/theme/text_styles.dart';

class _Step {
  final String label;
  final String emoji;
  final String statusKey;
  const _Step(
      {required this.label, required this.emoji, required this.statusKey});
}

class OrderProgressSteps extends StatelessWidget {
  final String status;

  const OrderProgressSteps({super.key, required this.status});

  static const _steps = [
    _Step(label: 'Recibido', emoji: '📋', statusKey: 'pending'),
    _Step(label: 'Confirmado', emoji: '✅', statusKey: 'confirmed'),
    _Step(label: 'Preparando', emoji: '☕', statusKey: 'preparing'),
    _Step(label: 'En camino', emoji: '🚴', statusKey: 'shipped'),
  ];

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
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeIndex;
    final isCancelled = status == 'cancelled';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: List.generate(_steps.length, (i) {
          final step = _steps[i];
          final isDone = !isCancelled && i < active;
          final isActive = !isCancelled && i == active;
          final isLast = i == _steps.length - 1;

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
                          // connector line to the right
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
                          // connector line to the left
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
                          // dot
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
                                      step.emoji,
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
                        step.label,
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
}