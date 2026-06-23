// lib/presentation/screens/admin/orders/widgets/admin_order_actions.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/config/constants.dart';
import '../../../../../presentation/widgets/order/order_detail_action_button.dart';

class AdminOrderActions extends StatelessWidget {
  final dynamic order;

  const AdminOrderActions({super.key, required this.order});

  void _showCancelDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Cancelar pedido?'),
        content: Text('Se cancelará el pedido #${order.id}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: implementar cancelación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Función en desarrollo'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OrderDetailActionButton(
            icon: Icons.phone_rounded,
            label: 'Llamar',
            color: AppColors.success,
            onTap: () {},
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('ID copiado'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OrderDetailActionButton(
            icon: Icons.cancel_outlined,
            label: 'Cancelar',
            color: AppColors.error,
            onTap: () => _showCancelDialog(context),
          ),
        ),
      ],
    );
  }
}