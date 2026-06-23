import 'package:flutter/material.dart';
import '../../../../../core/config/constants.dart';
import '../../../data/models/product_model.dart';
import 'dashboard_icon_btn.dart';

class DashboardProductAdminTile extends StatelessWidget {
  const DashboardProductAdminTile({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
  });

  final ProductModel product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  Color get _statusColor {
    final stock = product.stock ?? 0;
    if (!product.available || stock == 0) return AppColors.error;
    if (stock <= 10) return AppColors.warning;
    return AppColors.success;
  }

  String get _statusLabel {
    final stock = product.stock ?? 0;
    if (!product.available || stock == 0) return 'Agotado';
    if (stock <= 10) return 'Bajo Stock';
    return 'Disponible';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Imagen
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 52,
              height: 52,
              color: AppColors.primary.withOpacity(0.08),
              child: product.imageUrl?.isNotEmpty == true
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.coffee_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    )
                  : Icon(Icons.coffee_rounded,
                      color: AppColors.primary, size: 24),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.textGrey.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${product.stock ?? 0} en stock',
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Acciones verticales
          Column(
            children: [
              DashboardIconBtn(
                  Icons.edit_rounded, AppColors.primary, onEdit ?? () {}),
              const SizedBox(height: 6),
              DashboardIconBtn(
                  Icons.delete_rounded, AppColors.error, onDelete ?? () {}),
            ],
          ),
        ],
      ),
    );
  }
}