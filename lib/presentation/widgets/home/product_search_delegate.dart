// lib/presentation/widgets/home/product_search_delegate.dart

import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/ui/custom_dialogs.dart';
import '../../../data/models/product_model.dart';

class ProductSearchDelegate extends SearchDelegate<ProductModel?> {
  final List<ProductModel> products;
  final void Function(ProductModel) onAddToCart;
  final void Function(ProductModel) onTap;

  ProductSearchDelegate({
    required this.products,
    required this.onAddToCart,
    required this.onTap,
  });

  @override
  String get searchFieldLabel => 'Buscar productos...';

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          hintStyle: TextStyle(color: Colors.white70),
        ),
      );

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    if (query.trim().isEmpty) {
      return Center(
        child: Text(
          'Escribe para buscar...',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textGrey,
          ),
        ),
      );
    }

    final results = products
        .where((p) =>
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            p.description.toLowerCase().contains(query.toLowerCase()) ||
            p.category.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.textGrey,
            ),
            const SizedBox(height: 8),
            Text(
              'Sin resultados para "$query"',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final p = results[index];
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: AppColors.surface,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              p.imageUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52,
                height: 52,
                color: AppColors.surface,
                child: Icon(
                  Icons.local_cafe,
                  color: AppColors.textGrey,
                ),
              ),
            ),
          ),
          title: Text(
            p.name,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            p.category,
            style: AppTextStyles.bodySmall,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${p.price.toStringAsFixed(2)}',
                style: AppTextStyles.priceSmall,
              ),
              GestureDetector(
                onTap: () {
                  onAddToCart(p);
                  CustomDialogs.showSuccess(context, '${p.name} agregado');
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '+',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          onTap: () {
            close(context, p);
            onTap(p);
          },
        );
      },
    );
  }
}