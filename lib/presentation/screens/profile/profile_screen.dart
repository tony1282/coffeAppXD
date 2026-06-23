// lib/presentation/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/ui/custom_dialogs.dart';
import '../../../presentation/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, AuthProvider auth) async {
    if (auth.isLoading) return;

    // ✅ Confirmar antes de cerrar sesión
    final confirmed = await CustomDialogs.showConfirm(
      context: context,
      title: 'Cerrar sesión',
      message: '¿Estás seguro de que quieres cerrar sesión?',
      confirmText: 'Cerrar sesión',
      cancelText: 'Cancelar',
      confirmColor: AppColors.error,
    );

    if (confirmed != true) return;

    try {
      await auth.logout();
      if (context.mounted) {
        CustomDialogs.showSuccess(context, 'Sesión cerrada correctamente');
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    } catch (e) {
      if (context.mounted) {
        CustomDialogs.showError(context, 'Error al cerrar sesión. Intenta de nuevo.');
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;

    final nombre = (user?.userName ?? '').isNotEmpty ? user!.userName : 'Usuario';
    final email = user?.userEmail ?? 'Sin correo registrado';
    final foto = user?.photoUrl ?? '';
    final rol = user?.rol ?? 'cliente';
    final isAdmin = auth.isAdmin;
    final isLoading = auth.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Mi perfil',
          style: AppTextStyles.titleLarge,
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // ── Avatar ──────────────────────────────────────────────
          Center(
            child: CircleAvatar(
              radius: 52,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              backgroundImage: _isValidUrl(foto) ? NetworkImage(foto) : null,
              child: (!_isValidUrl(foto) && foto.isEmpty)
                  ? Text(
                      _getInitials(nombre),
                      style: AppTextStyles.displayMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14),

          // ── Nombre ──────────────────────────────────────────────
          Center(
            child: Text(
              nombre,
              style: AppTextStyles.displaySmall,
            ),
          ),
          const SizedBox(height: 4),

          // ── Email ────────────────────────────────────────────────
          Center(
            child: Text(
              email,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGrey,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Badge rol ────────────────────────────────────────────
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isAdmin
                    ? AppColors.primary.withOpacity(0.12)
                    : AppColors.success.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAdmin ? '⭐ Administrador' : '☕ Cliente',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isAdmin ? AppColors.primary : AppColors.success,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 8),

          // ── Info ─────────────────────────────────────────────────
          _Tile(
            icon: Icons.person_outline,
            label: 'Nombre',
            value: nombre,
          ),
          _Tile(
            icon: Icons.email_outlined,
            label: 'Correo',
            value: email,
          ),
          _Tile(
            icon: Icons.shield_outlined,
            label: 'Rol',
            value: rol.isNotEmpty ? '${rol[0].toUpperCase()}${rol.substring(1)}' : 'Cliente',
          ),
          const SizedBox(height: 28),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),

          // ── Cerrar sesión ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : () => _logout(context, auth),
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout, color: AppColors.error),
              label: Text(
                'Cerrar sesión',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Widget de información ──────────────────────────────────────────
class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}