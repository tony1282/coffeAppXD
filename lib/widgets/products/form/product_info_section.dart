import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'product_form_field.dart';
import 'product_form_divider.dart';

class ProductInfoSection extends StatelessWidget {
  const ProductInfoSection({
    super.key,
    required this.nameController,
    required this.descController,
  });

  final TextEditingController nameController;
  final TextEditingController descController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProductFormField(
          controller: nameController,
          label: 'Nombre del producto',
          hint: 'Ej. Americano Clásico',
          icon: Icons.coffee_rounded,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'El nombre es requerido' : null,
          textCapitalization: TextCapitalization.words,
        ),
        const ProductFormDivider(),
        ProductFormField(
          controller: descController,
          label: 'Descripción',
          hint: 'Describe el producto brevemente',
          icon: Icons.notes_rounded,
          maxLines: 3,
        ),
      ],
    );
  }
}