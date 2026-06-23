import 'package:flutter/material.dart';
import '/../../core/config/constants.dart';

class ProductFormDivider extends StatelessWidget {
  const ProductFormDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.textGrey.withOpacity(0.10),
      ),
    );
  }
}