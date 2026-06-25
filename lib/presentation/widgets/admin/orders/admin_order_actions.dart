// lib/presentation/screens/admin/orders/widgets/admin_order_actions.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/config/constants.dart';
import '../../../../../core/ui/custom_dialogs.dart';
import '../../../../../presentation/widgets/order/order_detail_action_button.dart';

class AdminOrderActions extends StatelessWidget {
  final dynamic order;

  const AdminOrderActions({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OrderDetailActionButton(
            icon: Icons.phone_rounded,
            label: 'Llamar',
            color: AppColors.success,
            onTap: () {
              CustomDialogs.showInfo(context, 'Función en desarrollo');
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OrderDetailActionButton(
            icon: Icons.copy_rounded,
            label: 'Copiar ID',
            color: AppColors.textGrey,
            onTap: () {
              Clipboard.setData(ClipboardData(text: '#${order.id}'));
              CustomDialogs.showSuccess(context, 'ID copiado');
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OrderDetailActionButton(
            icon: Icons.share_rounded,
            label: 'Compartir',
            color: AppColors.primary,
            onTap: () {
              CustomDialogs.showInfo(context, 'Función en desarrollo');
            },
          ),
        ),
      ],
    );
  }
}