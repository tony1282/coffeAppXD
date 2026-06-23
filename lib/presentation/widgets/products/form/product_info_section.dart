// lib/presentation/widgets/products/form/product_info_section.dart

import 'package:flutter/material.dart';
import 'product_form_field.dart';
import 'product_form_divider.dart';

class ProductInfoSection extends StatelessWidget {
  const ProductInfoSection({
    super.key,
    required this.nameController,
    required this.descController,
    this.nameValidator,
    this.descValidator,
  });

  final TextEditingController nameController;
  final TextEditingController descController;
  final String? Function(String?)? nameValidator;
  final String? Function(String?)? descValidator;

  // ✅ VALIDADOR POR DEFECTO
  static String? defaultNameValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre del producto es requerido';
    }
    if (value.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    if (value.trim().length > 100) {
      return 'El nombre no puede exceder 100 caracteres';
    }
    return null;
  }

  static String? defaultDescValidator(String? value) {
    if (value != null && value.trim().length > 500) {
      return 'La descripción no puede exceder 500 caracteres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProductFormField(
          controller: nameController,
          label: 'Nombre del producto',
          hint: 'Ej. Americano Clásico',
          icon: Icons.coffee_rounded,
          validator: nameValidator ?? defaultNameValidator,
          textCapitalization: TextCapitalization.words,
        ),
        const ProductFormDivider(),
        ProductFormField(
          controller: descController,
          label: 'Descripción',
          hint: 'Describe el producto brevemente',
          icon: Icons.notes_rounded,
          maxLines: 3,
          validator: descValidator ?? defaultDescValidator,
        ),
      ],
    );
  }
}