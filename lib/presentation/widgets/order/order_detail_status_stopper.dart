// lib/widgets/admin/order_detail_status_stepper.dart
import 'package:coffe_app/core/config/constants.dart';
import 'package:coffe_app/core/config/order_status_config.dart';
import 'package:flutter/material.dart';

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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_shipping_rounded,
                  color: AppColors.primary, size: 14),
            ),
            const SizedBox(width: 10),
            const Text(
              'Progreso del pedido',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ]),
          const SizedBox(height: 20),
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
                      margin: const EdgeInsets.only(bottom: 22),
                      decoration: BoxDecoration(
                        color: filled
                            ? statusColor.withOpacity(0.4)
                            : AppColors.textGrey.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }

                final stepIdx = i ~/ 2;
                final done    = stepIdx <= currentIdx;
                final active  = stepIdx == currentIdx;
                final dotColor = done ? statusColor : AppColors.textGrey.withOpacity(0.25);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width:  active ? 34 : 26,
                      height: active ? 34 : 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? statusColor
                            : done
                                ? statusColor.withOpacity(0.15)
                                : AppColors.textGrey.withOpacity(0.08),
                        border: active
                            ? Border.all(
                                color: statusColor.withOpacity(0.30),
                                width: 3)
                            : null,
                      ),
                      child: Icon(
                        OrderStatusConfig.icons[OrderStatusConfig.flow[stepIdx]],
                        size:  active ? 16 : 12,
                        color: active
                            ? Colors.white
                            : done
                                ? statusColor
                                : AppColors.textGrey.withOpacity(0.25),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      OrderStatusConfig.clientLabels[OrderStatusConfig.flow[stepIdx]] ?? '',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active
                            ? statusColor
                            : done
                                ? statusColor.withOpacity(0.6)
                                : AppColors.textGrey.withOpacity(0.4),
                      ),
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