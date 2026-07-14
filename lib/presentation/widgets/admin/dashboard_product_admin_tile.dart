import 'dashboard_icon_btn.dart';
import 'package:flutter/material.dart';
import '../../../data/models/product_model.dart';
import '../../../../../core/config/constants.dart';

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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _statusColor.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Imagen
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 58,
              height: 58,
              color: AppColors.primary.withOpacity(0.08),
              child: product.imageUrl?.isNotEmpty == true
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.coffee_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    )
                  : Icon(Icons.coffee_rounded,
                      color: AppColors.primary, size: 26),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.textGrey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _statusLabel,
                            style: TextStyle(
                              color: _statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.inventory_2_outlined,
                        size: 13, color: AppColors.textGrey.withOpacity(0.7)),
                    const SizedBox(width: 3),
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

          const SizedBox(width: 4),

          // Acciones verticales
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DashboardIconBtn(
                  Icons.edit_rounded, AppColors.primary, onEdit ?? () {}),
              const SizedBox(height: 8),
              DashboardIconBtn(
                  Icons.delete_rounded, AppColors.error, onDelete ?? () {}),
            ],
          ),
        ],
      ),
    );
  }
}
