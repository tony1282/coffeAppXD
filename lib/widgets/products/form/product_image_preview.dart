import 'package:flutter/material.dart';
import '/../../config/constants.dart';

class ProductImagePreview extends StatefulWidget {
  const ProductImagePreview({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<ProductImagePreview> createState() => _ProductImagePreviewState();
}

class _ProductImagePreviewState extends State<ProductImagePreview> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.controller.text.trim();

    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty ? _buildEmptyState() : _buildImage(url),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.image_outlined,
            color: AppColors.primary,
            size: 30,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Vista previa de imagen',
          style: TextStyle(
            color: AppColors.textGrey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pega una URL para ver la imagen',
          style: TextStyle(color: AppColors.textGrey, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 170,
      errorBuilder: (_, __, ___) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.broken_image_rounded, color: AppColors.error, size: 32),
          SizedBox(height: 8),
          Text(
            'No se pudo cargar la imagen',
            style: TextStyle(color: AppColors.textGrey, fontSize: 11),
          ),
        ],
      ),
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
    );
  }
}