// lib/widgets/home/home_header.dart

import 'package:flutter/material.dart';
import '../../../config/constants.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onSearchTap;
  final Widget? actions;  // ← AGREGAR

  const HomeHeader({
    super.key, 
    required this.onSearchTap,
    this.actions,  // ← AGREGAR
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo con imagen de red
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/logoXD.jpeg',
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'COFFEE SHOP XD',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const Spacer(),
              // Botón de búsqueda
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: onSearchTap,
              ),
              // Acciones adicionales (carrito)
              if (actions != null) ...[
                const SizedBox(width: 4),
                actions!,
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Elige tu café ☕',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          const Text(
            'Preparado con amor, servido fresco.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}