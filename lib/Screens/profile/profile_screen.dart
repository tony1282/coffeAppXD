import 'package:flutter/material.dart';
import '../../config/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // HU04 / HU05 / HU06 – Conecta con tu AuthProvider
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi perfil',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Conecta tu AuthProvider aquí',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}