import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameCtrl  = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl  = TextEditingController();

  bool _showPassword = false;

  static const Color primary    = Color(0xFF3B5EFF);
  static const Color background = Color(0xFFFFFBF8);
  static const Color textDark   = Color(0xFF1A1A1A);
  static const Color textGrey   = Color(0xFF8A8A8A);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            const Text(
              'Crear cuenta ☕',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Regístrate para comenzar',
              style: TextStyle(color: textGrey),
            ),

            const SizedBox(height: 30),

            // Nombre
            TextField(
              controller: nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Email
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Correo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Contraseña
            TextField(
              controller: passCtrl,
              obscureText: !_showPassword,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                suffixIcon: IconButton(
                  icon: Icon(_showPassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botón registro
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        final name  = nameCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final pass  = passCtrl.text.trim();

                        if (name.isEmpty || email.isEmpty || pass.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Completa todos los campos'),
                            ),
                          );
                          return;
                        }

                        try {
                          await auth.registerWithEmail(name, email, pass);
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/home');
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: auth.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Crear cuenta',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Volver a login
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '¿Ya tienes cuenta? Inicia sesión',
                  style: TextStyle(color: primary),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}