// lib/presentation/widgets/cart/cart_delivery_banner.dart
//
// NUEVO WIDGET — muestra la dirección de entrega y el tiempo estimado.
// Uso: CartDeliveryBanner(address: '...', onChangeTap: () {})

import 'package:flutter/material.dart';
import '../../../core/config/constants.dart';
import '../../../core/theme/text_styles.dart';

class CartDeliveryBanner extends StatelessWidget {
  final String address;
  final VoidCallback? onChangeTap;

  const CartDeliveryBanner({
    super.key,
    required this.address,
    this.onChangeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FF), width: 1),
      ),
      child: Column(
        children: [
          // Address row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ENTREGAR EN',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Divider(height: 1, color: const Color(0xFFC7D2FF)),
          const SizedBox(height: 10),

          // Time + change row
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: Color(0xFF6B7280),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Tiempo estimado: 15 – 20 min',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onChangeTap,
                child: Text(
                  'Cambiar',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}