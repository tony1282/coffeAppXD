// lib/core/ui/custom_dialogs.dart

import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../theme/text_styles.dart';

class CustomDialogs {
  // ── SnackBar de éxito ──────────────────────────
  static void showSuccess(BuildContext context, String message) {
    _showOverlay(context, message, AppColors.success, Icons.check_circle_rounded);
  }

  // ── SnackBar de error ──────────────────────────
  static void showError(BuildContext context, String message) {
    _showOverlay(context, message, AppColors.error, Icons.error_rounded);
  }

  // ── SnackBar de info ───────────────────────────
  static void showInfo(BuildContext context, String message) {
    _showOverlay(context, message, AppColors.primary, Icons.info_rounded);
  }

  // ── SnackBar de advertencia ────────────────────
  static void showWarning(BuildContext context, String message) {
    _showOverlay(context, message, AppColors.warning, Icons.warning_rounded);
  }

  // ── Overlay forzado (siempre arriba) ──────────
  static void _showOverlay(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    // 👇 OBTENER OVERLAY
    final overlay = Overlay.of(context);
    
    // 👇 CREAR ENTRY
    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,  // 👈 ARRIBA (debajo de la barra de estado)
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // 👇 Botón para cerrar manualmente
                  GestureDetector(
                    onTap: () => overlayEntry.remove(),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // 👇 INSERTAR EN OVERLAY
    overlay.insert(overlayEntry);

    // 👇 AUTO-CERRAR DESPUÉS DE 2.5 SEGUNDOS
    Future.delayed(const Duration(milliseconds: 2500), () {
      try {
        overlayEntry.remove();
      } catch (_) {}
    });
  }

  // ── Diálogo de confirmación ────────────────────
  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    Color confirmColor = AppColors.primary,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          title,
          style: AppTextStyles.titleLarge,
        ),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              cancelText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGrey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              confirmText,
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Diálogo de carga ───────────────────────────
  static void showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Cargando...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Cerrar diálogo de carga ────────────────────
  static void hideLoading(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}