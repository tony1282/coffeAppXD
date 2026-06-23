import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'product_form_field.dart';
import 'product_form_divider.dart';
import 'product_category_picker.dart';

class ProductPriceSection extends StatelessWidget {
  const ProductPriceSection({
    super.key,
    required this.priceController,
    required this.category,
    required this.onCategoryChanged,
  });

  final TextEditingController priceController;
  final String category;
  final void Function(String) onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProductFormField(
          controller: priceController,
          label: 'Precio (MXN)',
          hint: '0.00',
          icon: Icons.attach_money_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'El precio es requerido';
            }
            final n = double.tryParse(v);
            if (n == null || n <= 0) {
              return 'Ingresa un precio válido';
            }
            return null;
          },
        ),
        const ProductFormDivider(),
        ProductCategoryPicker(
          selected: category,
          onChanged: onCategoryChanged,
        ),
      ],
    );
  }
}