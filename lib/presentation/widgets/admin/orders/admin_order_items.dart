// lib/presentation/screens/admin/orders/widgets/admin_order_items.dart

import 'package:flutter/material.dart';
import '../../../../../core/config/constants.dart';
import '../../../../../core/theme/text_styles.dart';

class AdminOrderItems extends StatelessWidget {
  final dynamic order;

  const AdminOrderItems({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final items = order.items ?? [];

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No hay productos en este pedido',
            style: TextStyle(color: AppColors.textGrey),
          ),
        ),
      );
    }

    // ✅ USAR LISTA DE WIDGETS CORRECTAMENTE
    final List<Widget> itemWidgets = [];
    
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      
      if (i > 0) {
        itemWidgets.add(
          const Divider(height: 1, color: AppColors.divider),
        );
      }
      
      itemWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${item.quantity}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.productName ?? 'Producto',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: itemWidgets);
  }
}