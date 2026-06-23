// lib/widgets/home/home_header.dart

import 'package:coffe_app/core/config/constants.dart';
import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onSearchTap;
  final Widget? actions;

  const HomeHeader({
    super.key,
    required this.onSearchTap,
    this.actions,
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.coffee_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'COFFEE SHOP XD',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: onSearchTap,
              ),
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