// lib/presentation/screens/admin/orders/widgets/admin_order_info.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/config/constants.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../presentation/widgets/order/order_detail_info_row.dart';

class AdminOrderInfo extends StatelessWidget {
  final dynamic order;

  const AdminOrderInfo({super.key, required this.order});

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OrderDetailInfoRow(
          icon: Icons.person_outline_rounded,
          label: 'Nombre',
          value: order.userName ?? 'Usuario',
        ),
        const OrderDetailInfoDivider(),
        OrderDetailInfoRow(
          icon: Icons.phone_outlined,
          label: 'Teléfono',
          value: order.userPhone ?? 'No disponible',
          trailing: GestureDetector(
            onTap: () => _copyToClipboard(context, order.userPhone ?? '', 'Teléfono copiado'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Copiar', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
            ),
          ),
        ),
        const OrderDetailInfoDivider(),
        OrderDetailInfoRow(
          icon: Icons.location_on_outlined,
          label: 'Dirección',
          value: order.deliveryAddress ?? 'No especificada',
          multiline: true,
        ),
      ],
    );
  }
}