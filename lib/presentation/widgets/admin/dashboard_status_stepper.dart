// lib/presentation/widgets/admin/dashboard_status_stepper.dart

import 'package:coffe_app/core/config/constants.dart';
import 'package:coffe_app/core/config/order_status_config.dart';
import 'package:flutter/material.dart';

class DashboardStatusStepper extends StatelessWidget {
  const DashboardStatusStepper({super.key, required this.currentIdx});

  final int currentIdx;

  @override
  Widget build(BuildContext context) {
    // ✅ VALIDAR QUE currentIdx NO SEA -1
    final safeIdx = currentIdx.clamp(0, OrderStatusConfig.stepperColors.length - 1);
    final color = OrderStatusConfig.stepperColors[safeIdx];

    return Row(
      children: List.generate(
        OrderStatusConfig.stepperSteps.length * 2 - 1,
        (i) {
          if (i.isOdd) {
            final stepIdx = i ~/ 2;
            final filled = stepIdx < safeIdx;
            return Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: filled ? color : AppColors.textGrey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }

          final stepIdx = i ~/ 2;
          final done = stepIdx <= safeIdx;
          final active = stepIdx == safeIdx;
          final stepColor = done ? color : AppColors.textGrey.withOpacity(0.25);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: active ? 32 : 24,
                height: active ? 32 : 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? color
                      : done
                          ? color.withOpacity(0.15)
                          : AppColors.textGrey.withOpacity(0.08),
                  border: active
                      ? Border.all(
                          color: color.withOpacity(0.30),
                          width: 3,
                        )
                      : done
                          ? Border.all(
                              color: color.withOpacity(0.3),
                              width: 1,
                            )
                          : null,
                ),
                child: Center(
                  child: done
                      ? Icon(
                          Icons.check_rounded,
                          size: active ? 16 : 12,
                          color: active ? Colors.white : color,
                        )
                      : Text(
                          '${stepIdx + 1}',
                          style: TextStyle(
                            fontSize: active ? 12 : 10,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            color: active ? Colors.white : AppColors.textGrey.withOpacity(0.4),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                OrderStatusConfig.stepperSteps[stepIdx],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active
                      ? color
                      : done
                          ? color.withOpacity(0.6)
                          : AppColors.textGrey.withOpacity(0.4),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}