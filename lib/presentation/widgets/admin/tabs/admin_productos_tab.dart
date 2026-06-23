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

  void _showProductForm({ProductModel? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ProductFormSheet(
        product: product,
        onSaved: widget.onRefresh,
      ),
    );
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
            onTap: () => _showProductForm(),
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

// ─── Product Form Sheet ───────────────────────────────────────────────────────

class _ProductFormSheet extends StatefulWidget {
  final ProductModel? product;
  final Future<void> Function() onSaved;

  const _ProductFormSheet({this.product, required this.onSaved});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _category;
  late final TextEditingController _imageUrl;
  late final TextEditingController _stock;
  late bool _available;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p?.price.toString() ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _imageUrl = TextEditingController(text: p?.imageUrl ?? '');
    _stock = TextEditingController(text: p?.stock?.toString() ?? '');
    _available = p?.available ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _category.dispose();
    _imageUrl.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final provider = context.read<ProductProvider>();
    final p = widget.product;
    bool success;

    if (p == null) {
      success = await provider.createProduct(
        name: _name.text.trim(),
        description: _description.text.trim(),
        price: double.parse(_price.text),
        category: _category.text.trim(),
        imageUrl: _imageUrl.text.trim(),
        available: _available,
        stock: _stock.text.isNotEmpty ? int.tryParse(_stock.text) : null,
      );
    } else {
      success = await provider.updateProduct(
        id: p.id,
        name: _name.text.trim(),
        description: _description.text.trim(),
        price: double.parse(_price.text),
        category: _category.text.trim(),
        imageUrl: _imageUrl.text.trim(),
        available: _available,
        stock: _stock.text.isNotEmpty ? int.tryParse(_stock.text) : null,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      await widget.onSaved();
      Navigator.pop(context);
      CustomDialogs.showSuccess(
        context,
        p == null ? 'Producto creado' : 'Producto actualizado',
      );
    } else {
      CustomDialogs.showError(
          context, provider.errorMsg ?? 'Error al guardar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Editar producto' : 'Nuevo producto',
                style: AppTextStyles.titleMedium
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _field(_name, 'Nombre', required: true),
              _field(_description, 'Descripción'),
              _field(_price, 'Precio', keyboardType: TextInputType.number,
                  required: true, validator: (v) {
                if (double.tryParse(v ?? '') == null) return 'Precio inválido';
                return null;
              }),
              _field(_category, 'Categoría', required: true),
              _field(_imageUrl, 'URL de imagen'),
              _field(_stock, 'Stock', keyboardType: TextInputType.number),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Disponible'),
                value: _available,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _available = v),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isEdit ? 'Guardar cambios' : 'Crear producto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    bool required = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null
                : null),
      ),
    );
  }
}
