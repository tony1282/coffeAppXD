// lib/presentation/widgets/products/form/product_delete_button.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/ui/custom_dialogs.dart';
import '../../../../data/models/product_model.dart';
import '../../../../presentation/providers/product_provider.dart';

class ProductDeleteButton extends StatelessWidget {
  const ProductDeleteButton({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _confirmDelete(context),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
              SizedBox(width: 8),
              Text(
                'Eliminar producto',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await CustomDialogs.showConfirm(
      context: context,
      title: '¿Eliminar producto?',
      message: 'Se eliminará "${product.name}" permanentemente.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      confirmColor: AppColors.error,
    );

    if (confirmed == true && context.mounted) {
      final ok = await context.read<ProductProvider>().deleteProduct(product.id);

      if (context.mounted && ok) {
        CustomDialogs.showSuccess(context, 'Producto eliminado');
        Navigator.of(context).pop(true);
      } else if (context.mounted) {
        CustomDialogs.showError(context, 'Error al eliminar el producto');
      }
    }
  }
}