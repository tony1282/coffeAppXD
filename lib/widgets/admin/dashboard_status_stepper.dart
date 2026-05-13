import 'package:coffe_app/config/constants.dart';
import 'package:coffe_app/config/order_status_config.dart';
import 'package:flutter/material.dart';


class DashboardStatusStepper extends StatelessWidget {
  const DashboardStatusStepper({super.key, required this.currentIdx});

  final int currentIdx;

  @override
  Widget build(BuildContext context) {
    final color = OrderStatusConfig.stepperColors[currentIdx] ?? AppColors.primary;

    return Row(
      children: List.generate(
        OrderStatusConfig.stepperSteps.length * 2 - 1,
        (i) {
          if (i.isOdd) {
            final stepIdx = i ~/ 2;
            final filled = stepIdx < currentIdx;
            return Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: filled
                      ? color.withOpacity(0.5)
                      : AppColors.textGrey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final done = stepIdx <= currentIdx;
          final active = stepIdx == currentIdx;
          final stepColor = done ? color : AppColors.textGrey.withOpacity(0.3);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: active ? 10 : 7,
                height: active ? 10 : 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? color : AppColors.textGrey.withOpacity(0.2),
                  border: active
                      ? Border.all(color: color.withOpacity(0.35), width: 2)
                      : null,
                  boxShadow: active
                      ? [BoxShadow(color: color.withOpacity(0.40), blurRadius: 4)]
                      : null,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                OrderStatusConfig.stepperSteps[stepIdx],
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: stepColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}