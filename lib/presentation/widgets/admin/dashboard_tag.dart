import 'package:coffe_app/core/config/constants.dart';
import 'package:flutter/material.dart';

class DashboardTag extends StatelessWidget {
  const DashboardTag(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.textGrey.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.textGrey.withOpacity(0.15), width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textGrey,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}