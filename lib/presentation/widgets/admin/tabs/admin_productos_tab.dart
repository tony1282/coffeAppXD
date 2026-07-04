// lib/presentation/widgets/admin/tabs/admin_productos_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/ui/custom_dialogs.dart';
import '../../../../data/models/product_model.dart';
import '../../../../presentation/providers/product_provider.dart';
import '../../../../presentation/widgets/admin/dashboard_product_admin_tile.dart';
import '../../../../presentation/widgets/admin/tabs/admin_delete_dialog.dart';
import '../../../screens/admin/products/admin_product_form.dart'; // ← Importar el formulario

class AdminProductosTab extends StatefulWidget {
  final Future<void> Function() onRefresh;

  const AdminProductosTab({
    super.key,
    required this.onRefresh,
  });

  @override
  State<AdminProductosTab> createState() => _AdminProductosTabState();
}

class _AdminProductosTabState extends State<AdminProductosTab> {
  String _filtroCategoria = 'Todos';

  List<String> _buildCategories(List<ProductModel> products) {
    final cats = products.map((p) => p.category).toSet().toList()..sort();
    return ['Todos', ...cats];
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirmed = await AdminDeleteDialog.show(
      context: context,
      productName: product.name,
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<ProductProvider>();
    final success = await provider.deleteProduct(product.id);

    if (!mounted) return;
    if (success) {
      CustomDialogs.showSuccess(context, '${product.name} eliminado');
      await widget.onRefresh();
    } else {
      CustomDialogs.showError(context, provider.errorMsg ?? 'Error al eliminar');
    }
  }

  // 🔥 MODIFICADO: Ahora navega a AdminProductForm en lugar de mostrar un bottom sheet
  void _showProductForm({ProductModel? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AdminProductForm(product: product),
        settings: const RouteSettings(name: 'AdminProductForm'),
      ),
    ).then((result) {
      // Si el resultado es true, refrescar la lista
      if (result == true && mounted) {
        widget.onRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final categories = _buildCategories(provider.products);
        final lista = _filtroCategoria == 'Todos'
            ? provider.products
            : provider.products
                .where((p) => p.category == _filtroCategoria)
                .toList();

        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: Column(
            children: [
              _buildFilterBar(categories),
              _buildProductCounter(lista.length),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  children: lista
                      .map((p) => DashboardProductAdminTile(
                            product: p,
                            onEdit: () => _showProductForm(product: p),
                            onDelete: () => _deleteProduct(p),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterBar(List<String> categories) {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final active = _filtroCategoria == categories[i];
            return GestureDetector(
              onTap: () => setState(() => _filtroCategoria = categories[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                decoration: BoxDecoration(
                  color:
                      active ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? AppColors.primary
                        : AppColors.textGrey.withOpacity(0.2),
                  ),
                ),
                child: Center(
                  child: Text(
                    categories[i],
                    style: AppTextStyles.labelSmall.copyWith(
                      color: active ? Colors.white : AppColors.textGrey,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductCounter(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count productos',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textGrey,
            ),
          ),
          GestureDetector(
            onTap: () => _showProductForm(), // ← Ahora llama al mismo método
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Nuevo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}