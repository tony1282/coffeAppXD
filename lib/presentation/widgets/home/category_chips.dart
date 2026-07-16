import 'package:flutter/material.dart';
import 'package:coffe_app/core/config/constants.dart';

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final void Function(String) onSelect;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  static IconData _iconFor(String category) {
    switch (category.toLowerCase()) {
      case 'todo':
        return Icons.local_fire_department_rounded;
      case 'café frío':
      case 'cafe frío':
      case 'cafe frio':
        return Icons.ac_unit_rounded;
      case 'caliente':
        return Icons.coffee_rounded;
      case 'galletas':
        return Icons.cookie_rounded;
      default:
        return Icons.label_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        MediaQuery.of(context).size.width > 700 ? 24.0 : 16.0;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _Chip(
          label: categories[i],
          icon: _iconFor(categories[i]),
          selected: selected == categories[i],
          onTap: () => onSelect(categories[i]),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
