// lib/widgets/admin/order_detail_header.dart

import 'package:coffe_app/core/config/constants.dart';
import 'package:coffe_app/core/config/order_status_config.dart';
import 'package:coffe_app/data/models/order_model.dart';
import 'package:flutter/material.dart';

class OrderDetailHeader extends StatelessWidget {
  final Order order;
  final String timeAgo;

  const OrderDetailHeader({
    super.key,
    required this.order,
    this.timeAgo = '',
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = OrderStatusConfig.colors[order.status] ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.13),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: statusColor.withOpacity(0.25)),
          ),
          child: Icon(
            OrderStatusConfig.icons[order.status] ?? Icons.receipt_long_rounded,
            color: statusColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('Pedido ',
                    style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                Text('#${order.id}',
                    style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3)),
              ]),
              Text(timeAgo,
                  style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.30)),
          ),
          child: Text(
            OrderStatusConfig.clientLabels[order.status] ?? order.status,
            style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w800),
          ),
        ),
      ]),
    );
  }
}