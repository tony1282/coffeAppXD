// lib/presentation/screens/admin/dialogs/admin_delete_dialog.dart

import 'package:flutter/material.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/theme/text_styles.dart';

class AdminDeleteDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String productName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '¿Eliminar producto?',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Se eliminará "$productName" permanentemente.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}