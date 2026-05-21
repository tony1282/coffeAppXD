// lib/widgets/admin/order_detail_status_stepper.dart
import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../config/order_status_config.dart';

class OrderDetailStatusStepper extends StatelessWidget {
  final String currentStatus;

  const OrderDetailStatusStepper({
    super.key,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final currentIdx  = OrderStatusConfig.flow.indexOf(currentStatus);
    final statusColor = OrderStatusConfig.colors[currentStatus] ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 3, height: 14,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Progreso del pedido',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              OrderStatusConfig.flow.length * 2 - 1,
              (i) {
                if (i.isOdd) {
                  final stepIdx = i ~/ 2;
                  final filled  = stepIdx < currentIdx;
                  return Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: filled
                            ? statusColor.withOpacity(0.5)
                            : AppColors.textGrey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }
                final stepIdx   = i ~/ 2;
                final done      = stepIdx <= currentIdx;
                final active    = stepIdx == currentIdx;
                final stepColor = done
                    ? statusColor
                    : AppColors.textGrey.withOpacity(0.3);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width:  active ? 32 : 24,
                      height: active ? 32 : 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? statusColor.withOpacity(active ? 1 : 0.15)
                            : AppColors.textGrey.withOpacity(0.08),
                        border: active
                            ? Border.all(
                                color: statusColor.withOpacity(0.35),
                                width: 3)
                            : null,
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: statusColor.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        OrderStatusConfig.icons[OrderStatusConfig.flow[stepIdx]],
                        size:  active ? 16 : 12,
                        color: active
                            ? Colors.white
                            : done
                                ? statusColor
                                : AppColors.textGrey.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      OrderStatusConfig.labels[OrderStatusConfig.flow[stepIdx]] ?? '',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: stepColor),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}