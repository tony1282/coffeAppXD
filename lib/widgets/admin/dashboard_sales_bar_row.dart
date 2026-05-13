import 'package:flutter/material.dart';
import '../../../../config/constants.dart';

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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              productName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                    height: 7,
                    color: AppColors.primary.withOpacity(0.08),
                  ),
                  FractionallySizedBox(
                    widthFactor: ratio,
                    child: Container(
                      height: 7,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 26,
            child: Text(
              '$sold',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}