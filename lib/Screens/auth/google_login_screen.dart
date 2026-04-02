import 'package:flutter/material.dart';
import 'package:coffe_app/services/auth_service.dart';

class GoogleLoginScreen extends StatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const Color primary = Color(0xFFFF6B35);
  static const Color background = Color(0xFFFFFBF8);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF8A8A8A);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

Future<void> _signInWithGoogle() async {
  setState(() => _isLoading = true);
  try {
    final user = await _authService.signInWithGoogle();
    if (user != null && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  } catch (e) {
    print('❌ ERROR: $e'); // ← agrega esto
    _showError('Error: $e'); // ← y esto para verlo en pantalla
  }
  if (mounted) setState(() => _isLoading = false);
}

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Logo
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.coffee_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'COFFEE SHOP',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Título
                const Text(
                  'Bienvenido ☕',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Preparado con amor, servido fresco.',
                  style: TextStyle(fontSize: 15, color: textGrey),
                ),

                const SizedBox(height: 60),

                // Botón Google
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: primary,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://www.google.com/favicon.ico',
                                width: 22,
                                height: 22,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.g_mobiledata_rounded,
                                  color: primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Continuar con Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const Spacer(),

                Center(
                  child: Text(
                    '© 2024 Coffee Shop. Todos los derechos reservados.',
                    style: TextStyle(
                      fontSize: 11,
                      color: textGrey.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  
}