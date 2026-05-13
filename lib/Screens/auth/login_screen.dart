import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl  = TextEditingController();
  bool _showPassword = false;

  static const Color primary    = Color(0xFF3B5EFF);
  static const Color background = Color(0xFFFFFBF8);
  static const Color textDark   = Color(0xFF1A1A1A);
  static const Color textGrey   = Color(0xFF8A8A8A);

  // Redirige a /admin o /home según el rol cargado en el provider
  void _redirect() {
    if (!mounted) return;
    final isAdmin = context.read<AuthProvider>().isAdmin;
    Navigator.pushReplacementNamed(
      context,
      isAdmin ? '/admin' : '/home',
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                         MediaQuery.of(context).padding.top -
                         MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // Logo
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.coffee_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Text('COFFEE SHOP',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: primary)),
                    ],
                  ),

                  const Spacer(),

                  const Text('Bienvenido ☕',
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: textDark)),
                  const SizedBox(height: 6),
                  const Text('Inicia sesión para continuar',
                      style: TextStyle(color: textGrey)),

                  const SizedBox(height: 30),

                  // Email
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Correo',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
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
                          borderRadius: BorderRadius.circular(14)),
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Botón email ──────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              try {
                                await auth.loginWithEmail(
                                  emailCtrl.text.trim(),
                                  passCtrl.text.trim(),
                                );
                                _redirect();
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: auth.isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text('Iniciar sesión',
                              style: TextStyle(color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Row(children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('o'),
                    ),
                    Expanded(child: Divider()),
                  ]),

                  const SizedBox(height: 16),

                  // ── Botón Google ─────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              try {
                                await auth.signInWithGoogle();
                                _redirect();
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Continuar con Google',
                          style: TextStyle(color: textDark)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/register'),
                      child: const Text('¿No tienes cuenta? Crear cuenta',
                          style: TextStyle(color: primary)),
                    ),
                  ),

                  const Spacer(),

                  Center(
                    child: Text('© 2026 Coffee Shop',
                        style: TextStyle(
                            color: textGrey.withOpacity(0.6))),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}