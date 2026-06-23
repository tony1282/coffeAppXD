import 'package:flutter/material.dart';
import '../../../../../core/config/constants.dart';

class DashboardSalesBarRow extends StatelessWidget {
  const DashboardSalesBarRow({
    super.key,
    required this.productName,
    required this.sold,
    required this.maxSold,
  });

  final String productName;
  final int sold;
  final int maxSold;

  @override
  Widget build(BuildContext context) {
    final ratio = maxSold > 0 ? sold / maxSold : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                productName,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$sold uds',
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  color: AppColors.primary.withOpacity(0.08),
                ),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}