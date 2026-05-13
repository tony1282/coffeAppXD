import 'package:flutter/material.dart';
import '../../../config/constants.dart';

class DashboardTabBar extends StatelessWidget {
  const DashboardTabBar({
    super.key,
    required this.currentTab,
    required this.pendingCount,
    required this.onTap,
  });

  final int currentTab;
  final int pendingCount;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (Icons.dashboard_rounded, 'Resumen'),
      (Icons.receipt_long_rounded, 'Pedidos'),
      (Icons.coffee_rounded, 'Productos'),
    ];

    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = currentTab == i;
          final showBadge = i == 1 && pendingCount > 0;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                margin: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active
                        ? AppColors.primary
                        : AppColors.textGrey.withOpacity(0.2),
                    width: active ? 0 : 1,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tabs[i].$1,
                          size: 14,
                          color: active ? Colors.white : AppColors.textGrey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tabs[i].$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                    if (showBadge)
                      Positioned(
                        top: -8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}