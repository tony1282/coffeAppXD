import 'package:coffe_app/config/order_status_config.dart';
import 'package:flutter/material.dart';
import '../../../../config/constants.dart';
import '../../../../models/order_model.dart';
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
    final color = OrderStatusConfig.colors[order.status] ?? AppColors.textGrey;
    final idx = OrderStatusConfig.flow.indexOf(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderRow(color),
                      const SizedBox(height: 7),
                      _buildItemsRow(),
                      const SizedBox(height: 12),
                      if (expanded) ...[
                        DashboardStatusStepper(currentIdx: idx),
                        const SizedBox(height: 12),
                      ],
                      _buildActionRow(color),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '#${order.id ?? '???'}',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            order.userId ?? '',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '\$${order.total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsRow() {
    final itemsText = order.items.map((i) => i.productName).join('  ·  ');
    return Text(
      itemsText,
      style: TextStyle(
        color: AppColors.textGrey.withOpacity(0.8),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildActionRow(Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.30)),
          ),
          child: Text(
            OrderStatusConfig.labels[order.status] ?? order.status,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        if (order.status != 'entregado')
          GestureDetector(
            onTap: () {
              const next = {
                'pendiente': 'preparando',
                'preparando': 'listo',
                'listo': 'entregado',
              };
              onStatusChange(next[order.status] ?? order.status);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.30),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Avanzar estado',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}