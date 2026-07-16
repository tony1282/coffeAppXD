import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/constants.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/ui/custom_dialogs.dart';
import '../../../presentation/providers/auth_provider.dart';
// lib/presentation/screens/auth/login_screen.dart


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;

  // ── Diálogo para pedir teléfono ──────────────────────────────
  Future<void> _showPhoneDialog(AuthProvider auth) async {
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Completa tu perfil',
          style: AppTextStyles.titleLarge,
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Para continuar, necesitamos tu número de teléfono:',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  hintText: 'Ej: +52 123 456 7890',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El teléfono es obligatorio';
                  }
                  final phoneRegex = RegExp(r'^[0-9+\-\s()]+$');
                  if (!phoneRegex.hasMatch(value.trim())) {
                    return 'Teléfono inválido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGrey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
                await auth.updateUserProfile(phone: phoneCtrl.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Guardar',
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Google Sign In ─────────────────────────────────────────────
  Future<void> _handleGoogleSignIn(AuthProvider auth) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final user = await auth.signInWithGoogle();

      if (user != null && mounted) {
        final userModel = auth.userModel;

        if (userModel?.phone == null || userModel!.phone!.isEmpty) {
          await _showPhoneDialog(auth);
        }

        await auth.loadUserModel();

        if (mounted) {
          CustomDialogs.showSuccess(context, '¡Bienvenido!');
          _redirect();
        }
      }
    } catch (e) {
      if (mounted) {
        CustomDialogs.showError(
          context,
          'Error al iniciar con Google: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Login con email ────────────────────────────────────────────
  Future<void> _loginWithEmail(AuthProvider auth) async {
    if (_isLoading) return;

    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      CustomDialogs.showError(context, 'Por favor ingresa correo y contraseña');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await auth.loginWithEmail(email, password);
      if (mounted) {
        CustomDialogs.showSuccess(context, '¡Bienvenido!');
        _redirect();
      }
    } catch (e) {
      if (mounted) {
        CustomDialogs.showError(
          context,
          'Error al iniciar sesión: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
    final horizontalPadding = MediaQuery.of(context).size.width > 700 ? 36.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                  SizedBox(height: MediaQuery.of(context).size.height > 700 ? 48 : 24),

                  // ── Logo ──────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.coffee_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'COFFEE SHOP',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ── Títulos ──────────────────────────────────
                  Text(
                    'Bienvenido ☕',
                    style: AppTextStyles.displayMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Inicia sesión para continuar',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ── Email ────────────────────────────────────
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      hintText: 'ejemplo@correo.com',
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Contraseña ──────────────────────────────
                  TextField(
                    controller: passCtrl,
                    obscureText: !_showPassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _loginWithEmail(auth),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppColors.textGrey,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Botón login ─────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (_isLoading || auth.isLoading)
                          ? null
                          : () => _loginWithEmail(auth),
                      child: (_isLoading || auth.isLoading)
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Iniciar sesión'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('o'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Botón Google ────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: (_isLoading || auth.isLoading)
                          ? null
                          : () => _handleGoogleSignIn(auth),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.card,
                        side: BorderSide(color: AppColors.textGrey.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.g_mobiledata_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Continuar con Google',
                            style: AppTextStyles.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Registro ────────────────────────────────
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/register'),
                      child: Text(
                        '¿No tienes cuenta? Crear cuenta',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ── Footer ──────────────────────────────────
                  Center(
                    child: Text(
                      '© 2026 Coffee Shop',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textGrey.withOpacity(0.6),
                      ),
                    ),
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