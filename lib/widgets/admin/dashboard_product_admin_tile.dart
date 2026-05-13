import 'package:flutter/material.dart';
import '../../../../config/constants.dart';
import '../../../../models/product_model.dart';
import 'dashboard_tag.dart';
import 'dashboard_icon_btn.dart';

class DashboardProductAdminTile extends StatelessWidget {
  const DashboardProductAdminTile({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
  });

  final Product product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildProductIcon(),
          const SizedBox(width: 12),
          Expanded(child: _buildProductInfo()),
          _buildPriceAndActions(),
        ],
      ),
    );
  }

  Widget _buildProductIcon() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 1),
      ),
      child: Icon(
        product.imageUrl?.isNotEmpty == true ? Icons.image_rounded : Icons.coffee_rounded,
        color: AppColors.primary,
        size: 22,
      ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            DashboardTag(product.category),
            const SizedBox(width: 6),
            if (!product.available)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  'No disponible',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceAndActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '\$${product.price.toStringAsFixed(0)}',
          style: const TextStyle(
            color: AppColors.warning,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            DashboardIconBtn(
              Icons.edit_rounded,
              AppColors.primary,
              onEdit ?? () {},
            ),
            const SizedBox(width: 6),
            DashboardIconBtn(
              Icons.delete_rounded,
              AppColors.error,
              onDelete ?? () {},
            ),
          ],
        ),
      ],
    );
  }
}