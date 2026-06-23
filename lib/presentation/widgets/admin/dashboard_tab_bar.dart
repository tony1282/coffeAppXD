import 'package:coffe_app/core/config/constants.dart';
import 'package:flutter/material.dart';

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
      (Icons.bar_chart_rounded, 'Resumen'),
      (Icons.receipt_long_rounded, 'Pedidos'),
      (Icons.inventory_2_rounded, 'Productos'),
    ];

    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final active = currentTab == i;
            final showBadge = i == 1 && pendingCount > 0;

            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tabs[i].$1,
                            size: 14,
                            color: active
                                ? AppColors.primary
                                : Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            tabs[i].$2,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? AppColors.primary
                                  : Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showBadge)
                      Positioned(
                        top: -3,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
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
            );
          }),
        ),
      ),
    );
  }
}