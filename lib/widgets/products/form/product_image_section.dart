// lib/screens/admin/products/widgets/product_image_section.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../config/constants.dart';
import '../../../../services/api_service.dart';

class ProductImageSection extends StatefulWidget {
  const ProductImageSection({
    super.key,
    required this.imageUrlController,
    required this.onImageChanged,
    this.initialImageUrl,
  });

  final TextEditingController imageUrlController;
  final VoidCallback onImageChanged;
  final String? initialImageUrl;

  @override
  State<ProductImageSection> createState() => _ProductImageSectionState();
}

class _ProductImageSectionState extends State<ProductImageSection> {
  File? _selectedImage;
  String? _imageUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initialImageUrl;
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      widget.imageUrlController.text = _imageUrl!;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        await _uploadImage(File(pickedFile.path));
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() => _isUploading = true);

    try {
      final apiService = ApiService();
      final uploadedUrl = await apiService.uploadImage(imageFile);
      
      setState(() {
        _imageUrl = uploadedUrl;
        widget.imageUrlController.text = uploadedUrl;
      });
      
      widget.onImageChanged();
      _showSuccess('Imagen subida correctamente');
    } catch (e) {
      _showError('Error al subir imagen: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _selectedImage = null;
      _imageUrl = null;
      widget.imageUrlController.text = '';
    });
    widget.onImageChanged();
    _showSuccess('Imagen eliminada');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Seleccionar imagen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildImagePreview(),
        const SizedBox(height: 12),
        _buildActionButtons(),
        if (_isUploading) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 8),
          const Text(
            'Subiendo imagen...',
            style: TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
        ],
        if (_imageUrl != null && _imageUrl!.isNotEmpty && !_isUploading) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Imagen guardada',
                    style: const TextStyle(fontSize: 12, color: AppColors.success),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImagePreview() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        height: 180,
        width: double.infinity,
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _selectedImage != null
              ? Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                )
              : _imageUrl != null && _imageUrl!.isNotEmpty
                  ? Image.network(
                      _imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.primary,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => _buildEmptyPreview(
                        Icons.broken_image_rounded,
                        'No se pudo cargar la imagen',
                      ),
                    )
                  : _buildEmptyPreview(
                      Icons.image_outlined,
                      'Toca para seleccionar una imagen',
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyPreview(IconData icon, String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 40),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.photo_library_rounded,
            label: 'Galería',
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.camera_alt_rounded,
            label: 'Cámara',
            onTap: () => _pickImage(ImageSource.camera),
          ),
        ),
        if (_imageUrl != null || _selectedImage != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.delete_rounded,
              label: 'Eliminar',
              color: AppColors.error,
              onTap: _removeImage,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppColors.primary,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}