// lib/presentation/screens/admin/orders/widgets/admin_order_info.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/config/constants.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/ui/custom_dialogs.dart';
import '../../../../../presentation/widgets/order/order_detail_info_row.dart';

class AdminOrderInfo extends StatelessWidget {
  final dynamic order;

  const AdminOrderInfo({super.key, required this.order});

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    CustomDialogs.showSuccess(context, message);
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
        // ✅ QUITAR TELÉFONO (no existe en el modelo)
        // Mostrar ID del usuario en su lugar
        OrderDetailInfoRow(
          icon: Icons.person_pin_rounded,
          label: 'ID Usuario',
          value: order.userId ?? 'No disponible',
          trailing: GestureDetector(
            onTap: () => _copyToClipboard(
              context,
              order.userId ?? '',
              'ID de usuario copiado',
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Copiar',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
              ),
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