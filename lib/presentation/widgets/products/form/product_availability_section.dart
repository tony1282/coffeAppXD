import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/../../core/config/constants.dart';
import 'product_form_field.dart';
import 'product_form_divider.dart';

class ProductAvailabilitySection extends StatelessWidget {
  const ProductAvailabilitySection({
    super.key,
    required this.available,
    required this.onAvailableChanged,
    required this.hasStock,
    required this.onHasStockChanged,
    required this.stockController,
    required this.showStockField,
  });

  final bool available;
  final ValueChanged<bool> onAvailableChanged;
  final bool hasStock;
  final ValueChanged<bool> onHasStockChanged;
  final TextEditingController stockController;
  final bool showStockField;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAvailableToggle(),
        const ProductFormDivider(),
        _buildStockToggle(),
        if (showStockField) ...[
          const ProductFormDivider(),
          _buildStockField(),
        ],
      ],
    );
  }

  Widget _buildAvailableToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: (available ? AppColors.success : AppColors.textGrey)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              available ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: available ? AppColors.success : AppColors.textGrey,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Disponible para venta',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  available ? 'Visible en el menú' : 'Oculto del menú',
                  style: TextStyle(
                    color: AppColors.textGrey.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: available,
            onChanged: onAvailableChanged,
            activeColor: AppColors.success,
            activeTrackColor: AppColors.success.withOpacity(0.25),
          ),
        ],
      ),
    );
  }

  Widget _buildStockToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: AppColors.warning,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Controlar stock',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Limitar unidades disponibles',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: hasStock,
            onChanged: onHasStockChanged,
            activeColor: AppColors.warning,
            activeTrackColor: AppColors.warning.withOpacity(0.25),
          ),
        ],
      ),
    );
  }

  Widget _buildStockField() {
    return ProductFormField(
      controller: stockController,
      label: 'Cantidad en stock',
      hint: 'Ej. 50',
      icon: Icons.numbers_rounded,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: hasStock
          ? (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Ingresa la cantidad';
              }
              if (int.tryParse(v) == null) {
                return 'Número inválido';
              }
              return null;
            }
          : null,
    );
  }
}