// lib/presentation/widgets/cart/payment_method_sheet.dart
//
// Reemplaza _PaymentMethodSheet (clase privada) de cart_screen.dart.
// Ahora es un widget público reutilizable.
// Uso: PaymentMethodSheet(total: _total, isProcessing: ..., onConfirm: ...)

import 'package:flutter/material.dart';
import '../../../core/config/constants.dart';
import '../../../core/theme/text_styles.dart';

class PaymentMethodSheet extends StatefulWidget {
  final double total;
  final bool isProcessing;
  final void Function(String method) onConfirm;

  const PaymentMethodSheet({
    super.key,
    required this.total,
    required this.isProcessing,
    required this.onConfirm,
  });

  @override
  State<PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends State<PaymentMethodSheet> {
  String? _selected;

  // ✅ SOLO TARJETA - ELIMINADO EFECTIVO
  static const _methods = [
    _PaymentMethod(
      label: 'Tarjeta',
      subtitle: 'Visa, Mastercard, Mercado Pago',
      icon: Icons.credit_card_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // ✅ Seleccionar tarjeta por defecto
    _selected = 'Tarjeta';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Row(
            children: [
              Text(
                'Método de pago',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pago seguro con tarjeta',
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),

          // Method options
          ..._methods.map((m) {
            final isSelected = _selected == m.label;
            return GestureDetector(
              onTap: () => setState(() => _selected = m.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.06)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        m.icon,
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFF6B7280),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.label,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFF111827),
                            ),
                          ),
                          Text(
                            m.subtitle,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: const Color(0xFF6B7280),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFD1D5DB),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 13)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Total display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total a pagar',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
                Text(
                  '\$${widget.total.toStringAsFixed(2)}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.isProcessing || _selected == null
                  ? null
                  : () => widget.onConfirm(_selected!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: widget.isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Pagar con tarjeta',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Mensaje de seguridad
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: const Color(0xFF6B7280),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Pago seguro con Mercado Pago',
                style: AppTextStyles.labelSmall.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMethod {
  final String label;
  final String subtitle;
  final IconData icon;

  const _PaymentMethod({
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}