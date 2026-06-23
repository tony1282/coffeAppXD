// lib/presentation/widgets/admin/dashboard_order_tile.dart

import 'package:coffe_app/core/config/order_status_config.dart';
import 'package:coffe_app/core/ui/custom_dialogs.dart';
import 'package:flutter/material.dart';
import '../../../../../core/config/constants.dart';
import '../../../data/models/order_model.dart';
import 'dashboard_status_stepper.dart';

class DashboardOrderTile extends StatelessWidget {
  const DashboardOrderTile({
    super.key,
    required this.order,
    required this.onStatusChange,
    this.expanded = false,
  });

  final Order order;
  final bool expanded;
  final void Function(String) onStatusChange;

  @override
  Widget build(BuildContext context) {
    // ✅ NORMALIZAR EL ESTADO (SOLO INGLÉS)
    final normalizedStatus = OrderStatusConfig.statusMap[order.status] ?? 'pending';
    final color = OrderStatusConfig.colors[normalizedStatus] ?? AppColors.textGrey;
    final idx = OrderStatusConfig.flow.indexOf(normalizedStatus);
    final displayName = order.userName ?? order.userId ?? 'Cliente';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Franja de color superior
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${order.id ?? '???'}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '\$${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Items
                Text(
                  order.items.map((i) => i.productName).join(' · '),
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                if (expanded) ...[
                  const SizedBox(height: 12),
                  DashboardStatusStepper(currentIdx: idx),
                ],

                const SizedBox(height: 12),

                // Footer
                Row(
                  children: [
                    // Badge de estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            OrderStatusConfig.labels[normalizedStatus] ?? order.status,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // ✅ Botón "Avanzar" (SOLO INGLÉS)
                    if (normalizedStatus != 'delivered' && normalizedStatus != 'cancelled')
                      GestureDetector(
                        onTap: () {
                          // ✅ VALIDAR QUE order.id NO SEA NULL
                          if (order.id == null) {
                            print('❌ [ADMIN] order.id es null, no se puede avanzar');
                            CustomDialogs.showError(context, 'Error: ID de pedido no encontrado');
                            return;
                          }
                          final nextStatus = OrderStatusConfig.nextStatus[normalizedStatus] ?? normalizedStatus;
                          print('🔍 [ADMIN] Botón avanzar: estado actual "$normalizedStatus" → nuevo "$nextStatus"');
                          onStatusChange(nextStatus);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Avanzar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}