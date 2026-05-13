import 'package:coffe_app/widgets/products/form/product_section_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '/../../config/constants.dart';
import '/../../models/product_model.dart';
import '/../../providers/product_provider.dart';

// Widgets
import 'package:coffe_app/widgets/products/form/product_availability_section.dart';
import 'package:coffe_app/widgets/products/form/product_category_picker.dart';
import 'package:coffe_app/widgets/products/form/product_image_section.dart';
import 'package:coffe_app/widgets/products/form/product_info_section.dart';
import 'package:coffe_app/widgets/products/form/product_price_section.dart';
import 'package:coffe_app/widgets/products/form/product_submit_button.dart';
import 'package:coffe_app/widgets/products/form/product_delete_button.dart';
import 'package:coffe_app/widgets/products/form/product_form_card.dart';
import 'package:coffe_app/widgets/products/form/product_form_header.dart';


class AdminProductForm extends StatefulWidget {
  const AdminProductForm({super.key, this.product});

  final Product? product;

  @override
  State<AdminProductForm> createState() => _AdminProductFormState();
}

class _AdminProductFormState extends State<AdminProductForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _imageCtrl;
  late final TextEditingController _stockCtrl;

  late String _category;
  late bool _available;
  bool _hasStock = false;
  bool _submitting = false;

  bool get _isEditing => widget.product != null;

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
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _submitting = true);

    final provider = context.read<ProductProvider>();
    final bool ok;

    if (_isEditing) {
      ok = await provider.updateProduct(
        id: widget.product!.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.parse(_priceCtrl.text),
        category: _category,
        imageUrl: _imageCtrl.text.trim(),
        available: _available,
        stock: _hasStock && _stockCtrl.text.isNotEmpty
            ? int.tryParse(_stockCtrl.text)
            : null,
      );
    } else {
      ok = await provider.createProduct(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.parse(_priceCtrl.text),
        category: _category,
        imageUrl: _imageCtrl.text.trim(),
        available: _available,
        stock: _hasStock && _stockCtrl.text.isNotEmpty
            ? int.tryParse(_stockCtrl.text)
            : null,
      );
    }

    setState(() => _submitting = false);

    if (!mounted) return;

    if (ok) {
      _showSuccessSnack();
      Navigator.of(context).pop(true);
    } else {
      _showErrorSnack(provider.errorMsg ?? 'Error desconocido');
    }
  }

  void _showSuccessSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing ? 'Producto actualizado ✓' : 'Producto creado ✓',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 32),
                    ProductSubmitButton(
                      isEditing: _isEditing,
                      submitting: _submitting,
                      onPressed: _submitting ? null : _submit,
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 12),
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
