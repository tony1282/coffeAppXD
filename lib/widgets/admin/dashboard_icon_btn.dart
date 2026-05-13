import 'package:flutter/material.dart';
import '../../../config/constants.dart';

class DashboardIconBtn extends StatelessWidget {
  const DashboardIconBtn(this.icon, this.color, this.onTap, {super.key});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.20), width: 1),
        ),
        child: Icon(icon, color: color, size: 13),
      ),
    );
  }
}