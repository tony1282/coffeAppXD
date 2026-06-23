// lib/presentation/screens/admin/orders/widgets/admin_order_notes.dart

import 'package:flutter/material.dart';
import '../../../../../core/config/constants.dart';
import '../../../../../core/theme/text_styles.dart';

class AdminOrderNotes extends StatelessWidget {
  final dynamic order;

  const AdminOrderNotes({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              order.notes ?? '',
              style: AppTextStyles.bodyMedium.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}