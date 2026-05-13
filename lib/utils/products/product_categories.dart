import 'package:flutter/material.dart';

class ProductCategories {
  static const List<String> all = [
    'Caliente',
    'Café frío',
    'Galletas',
    'Postres',
    'Bebidas',
    'Sin categoría',
  ];

  static const Map<String, IconData> icons = {
    'Caliente': Icons.local_cafe_rounded,
    'Café frío': Icons.icecream_rounded,
    'Galletas': Icons.cookie_rounded,
    'Postres': Icons.cake_rounded,
    'Bebidas': Icons.local_drink_rounded,
    'Sin categoría': Icons.label_rounded,
  };
}