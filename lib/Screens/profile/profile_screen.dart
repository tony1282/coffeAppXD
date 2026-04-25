import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final user   = auth.userModel;
    final nombre = (user?.userName.isNotEmpty == true) ? user!.userName : 'Usuario';
    final email  = user?.userEmail ?? '';
    final foto   = user?.photoUrl  ?? '';
    final rol    = user?.rol       ?? 'cliente';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi perfil',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
              backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
              child: foto.isEmpty
                  ? Text(
                      nombre[0].toUpperCase(),
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
            child: Text(nombre,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A))),
          ),

          const SizedBox(height: 4),

          // ── Email ────────────────────────────────────────────────
          Center(
            child: Text(email,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF8A8A8A))),
          ),

          const SizedBox(height: 10),

          // ── Badge rol ────────────────────────────────────────────
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: auth.isAdmin
                    ? AppColors.primary.withOpacity(0.12)
                    : Colors.green.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                auth.isAdmin ? '⭐ Administrador' : '☕ Cliente',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: auth.isAdmin
                      ? AppColors.primary
                      : Colors.green.shade700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 8),

          // ── Info ─────────────────────────────────────────────────
          _Tile(icon: Icons.person_outline,  label: 'Nombre', value: nombre),
          _Tile(icon: Icons.email_outlined,   label: 'Correo', value: email),
          _Tile(
            icon: Icons.shield_outlined,
            label: 'Rol',
            value: rol[0].toUpperCase() + rol.substring(1),
          ),

          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 16),

          // ── Cerrar sesión ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/login', (_) => false);
                      }
                    },
              icon: auth.isLoading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text('Cerrar sesión',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String   label;
  final String   value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A8A8A),
                    fontWeight: FontWeight.w500)),
            Text(value,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }
}