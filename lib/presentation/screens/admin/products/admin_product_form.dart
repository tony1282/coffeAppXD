import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/ui/custom_dialogs.dart';
import '../../../../data/models/product_model.dart';
import '../../../../presentation/providers/product_provider.dart';
import '../../../../presentation/widgets/products/form/product_form_card.dart';
import '../../../../presentation/widgets/products/form/product_form_header.dart';
import '../../../../presentation/widgets/products/form/product_info_section.dart';
import '../../../../presentation/widgets/products/form/product_section_tile.dart';
import '../../../../presentation/widgets/products/form/product_delete_button.dart';
import '../../../../presentation/widgets/products/form/product_image_section.dart';
import '../../../../presentation/widgets/products/form/product_price_section.dart';
import '../../../../presentation/widgets/products/form/product_submit_button.dart';
import '../../../../presentation/widgets/products/form/product_category_picker.dart';
import '../../../../presentation/widgets/products/form/product_availability_section.dart';
// lib/presentation/screens/admin/products/admin_product_form.dart

class AdminProductForm extends StatefulWidget {
  const AdminProductForm({super.key, this.product});

  final ProductModel? product;

  @override
  State<AdminProductForm> createState() => _AdminProductFormState();
}

class _AdminProductFormState extends State<AdminProductForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _imageCtrl;
  late final TextEditingController _stockCtrl;

  late String _category;
  late bool _available;
  bool _hasStock = false;

  bool get _isEditing => widget.product != null;

  // ── Validaciones ──────────────────────────────────────────────
  double? _parsePrice(String text) {
    if (text.trim().isEmpty) return null;
    final normalized = text.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  int? _parseStock(String text) {
    if (text.trim().isEmpty) return null;
    final parsed = int.tryParse(text.trim());
    if (parsed == null || parsed < 0) return null;
    if (parsed > 999999) return 999999;
    return parsed;
  }

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(
      text: p != null ? p.price.toStringAsFixed(2) : '',
    );
    _imageCtrl = TextEditingController(text: p?.imageUrl ?? '');
    _stockCtrl = TextEditingController(
      text: p?.stock != null ? p!.stock.toString() : '',
    );
    _category = p?.category ?? 'Caliente';
    _available = p?.available ?? true;
    _hasStock = p?.stock != null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _imageCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      CustomDialogs.showError(context, 'El nombre del producto es requerido');
      return;
    }

    final price = _parsePrice(_priceCtrl.text);
    if (price == null) {
      CustomDialogs.showError(context, 'Precio inválido');
      return;
    }
    if (price <= 0) {
      CustomDialogs.showError(context, 'El precio debe ser mayor a 0');
      return;
    }
    if (price > 999999) {
      CustomDialogs.showError(context, 'Precio demasiado alto');
      return;
    }

    int? stock;
    if (_hasStock) {
      stock = _parseStock(_stockCtrl.text);
      if (stock == null) {
        CustomDialogs.showError(context, 'Stock inválido');
        return;
      }
    }

    final imageUrl = _imageCtrl.text.trim();
    if (imageUrl.isEmpty) {
      CustomDialogs.showError(context, 'La URL de la imagen es requerida');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final provider = context.read<ProductProvider>();
    final bool ok;

    try {
      if (_isEditing) {
        ok = await provider.updateProduct(
          id: widget.product!.id,
          name: name,
          description: _descCtrl.text.trim(),
          price: price,
          category: _category,
          imageUrl: imageUrl,
          available: _available,
          stock: stock,
        );
      } else {
        ok = await provider.createProduct(
          name: name,
          description: _descCtrl.text.trim(),
          price: price,
          category: _category,
          imageUrl: imageUrl,
          available: _available,
          stock: stock,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomDialogs.showError(context, 'Error inesperado. Intenta de nuevo');
      }
      setState(() => _isSubmitting = false);
      return;
    }

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (ok) {
      final message =
          _isEditing ? 'Producto actualizado ✓' : 'Producto creado ✓';
      CustomDialogs.showSuccess(context, message);
      Navigator.of(context).pop(true);
    } else {
      CustomDialogs.showError(
        context,
        provider.errorMsg ?? 'Error al guardar el producto',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width >= 700 ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ProductFormHeader(
              isEditing: _isEditing,
              productName: widget.product?.name ?? '',
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                      horizontalPadding, 22, horizontalPadding, 32),
                  children: [
                    ProductSectionTitle(title: 'Información básica'),
                    const SizedBox(height: 12),
                    ProductFormCard(
                      children: [
                        ProductInfoSection(
                          nameController: _nameCtrl,
                          descController: _descCtrl,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    ProductSectionTitle(title: 'Precio y categoría'),
                    const SizedBox(height: 12),
                    ProductFormCard(
                      children: [
                        ProductPriceSection(
                          priceController: _priceCtrl,
                          category: _category,
                          onCategoryChanged: (v) =>
                              setState(() => _category = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    ProductSectionTitle(title: 'Imagen'),
                    const SizedBox(height: 12),
                    ProductFormCard(
                      children: [
                        ProductImageSection(
                          imageUrlController: _imageCtrl,
                          initialImageUrl: widget.product?.imageUrl,
                          onImageChanged: () => setState(() {}),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    ProductSectionTitle(title: 'Disponibilidad'),
                    const SizedBox(height: 12),
                    ProductFormCard(
                      children: [
                        ProductAvailabilitySection(
                          available: _available,
                          onAvailableChanged: (v) =>
                              setState(() => _available = v),
                          hasStock: _hasStock,
                          onHasStockChanged: (v) =>
                              setState(() => _hasStock = v),
                          stockController: _stockCtrl,
                          showStockField: _hasStock,
                        ),
                      ],
                    ),
                    const SizedBox(height: 34),
                    ProductSubmitButton(
                      isEditing: _isEditing,
                      submitting: _isSubmitting,
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 14),
                      ProductDeleteButton(product: widget.product!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
