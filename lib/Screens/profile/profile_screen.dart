// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showErrorSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _logout(BuildContext context, AuthProvider auth) async {
    if (auth.isLoading) return;

    // ✅ Confirmar antes de cerrar sesión
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cerrar sesión',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await auth.logout();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnack(context, 'Error al cerrar sesión. Intenta de nuevo.');
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;
    
    // ✅ Safe access con valores por defecto
    final nombre = (user?.userName ?? '').isNotEmpty ? user!.userName : 'Usuario';
    final email = user?.userEmail ?? 'Sin correo registrado';
    final foto = user?.photoUrl ?? '';
    final rol = user?.rol ?? 'cliente';
    final isAdmin = auth.isAdmin;
    final isLoading = auth.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
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
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
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
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: 4),
          
          // ── Email ────────────────────────────────────────────────
          Center(
            child: Text(
              email,
              style: const TextStyle(fontSize: 14, color: Color(0xFF8A8A8A)),
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
                    : Colors.green.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAdmin ? '⭐ Administrador' : '☕ Cliente',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isAdmin ? AppColors.primary : Colors.green.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 8),
          
          // ── Info ─────────────────────────────────────────────────
          _Tile(icon: Icons.person_outline, label: 'Nombre', value: nombre),
          _Tile(icon: Icons.email_outlined, label: 'Correo', value: email),
          _Tile(
            icon: Icons.shield_outlined,
            label: 'Rol',
            value: rol.isNotEmpty ? '${rol[0].toUpperCase()}${rol.substring(1)}' : 'Cliente',
          ),
          const SizedBox(height: 28),
          const Divider(),
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
                  : const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ✅ Validar URL para evitar errores de imagen
  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }
}

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
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8A8A8A),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}