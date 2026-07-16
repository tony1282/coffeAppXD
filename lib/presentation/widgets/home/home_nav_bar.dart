import 'package:flutter/material.dart';
import 'package:coffe_app/core/config/constants.dart';

class HomeNavBar extends StatelessWidget {
  final int selected;
  final VoidCallback onMenu;
  final VoidCallback onOrders;
  final VoidCallback onProfile;

  const HomeNavBar({
    super.key,
    required this.selected,
    required this.onMenu,
    required this.onOrders,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.local_cafe_rounded,
            label: 'Menú',
            selected: selected == 0,
            onTap: onMenu,
            compact: !isWide,
          ),
          _NavItem(
            icon: Icons.receipt_long_rounded,
            label: 'Pedidos',
            selected: selected == 1,
            onTap: onOrders,
            compact: !isWide,
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: 'Perfil',
            selected: selected == 2,
            onTap: onProfile,
            compact: !isWide,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: selected ? AppColors.primary : Colors.grey, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              color: selected ? AppColors.primary : Colors.grey,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
