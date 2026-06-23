// lib/presentation/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/constants.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/ui/custom_dialogs.dart';
import '../../../presentation/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool _showPassword = false;
  bool _acceptTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  // ── Validaciones ──────────────────────────────────────────────
  String? _validateName(String value) {
    if (value.trim().isEmpty) return 'El nombre es obligatorio';
    if (value.length > 100) return 'El nombre es demasiado largo';
    return null;
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) return 'El correo es obligatorio';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Correo inválido';
    return null;
  }

  String? _validatePhone(String value) {
    if (value.trim().isEmpty) return null;
    final phoneRegex = RegExp(r'^[0-9+\-\s()]+$');
    if (!phoneRegex.hasMatch(value.trim())) return 'Teléfono inválido';
    if (value.length > 20) return 'Teléfono demasiado largo';
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'La contraseña es obligatoria';
    if (value.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
    if (value.length > 128) return 'La contraseña es demasiado larga';
    return null;
  }

  // ── Registro ──────────────────────────────────────────────────
  Future<void> _register(AuthProvider auth) async {
    if (_isLoading || auth.isLoading) return;

    // Validar campos
    final nameError = _validateName(nameCtrl.text);
    final emailError = _validateEmail(emailCtrl.text);
    final phoneError = _validatePhone(phoneCtrl.text);
    final passError = _validatePassword(passCtrl.text);

    if (nameError != null) {
      CustomDialogs.showError(context, nameError);
      return;
    }
    if (emailError != null) {
      CustomDialogs.showError(context, emailError);
      return;
    }
    if (phoneError != null) {
      CustomDialogs.showError(context, phoneError);
      return;
    }
    if (passError != null) {
      CustomDialogs.showError(context, passError);
      return;
    }
    if (!_acceptTerms) {
      CustomDialogs.showError(context, 'Debes aceptar los términos y condiciones');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await auth.registerWithEmail(
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passCtrl.text,
        phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
      );

      if (mounted) {
        CustomDialogs.showSuccess(context, '¡Cuenta creada exitosamente!');
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        CustomDialogs.showError(
          context,
          'Error al registrarse: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isLoading = _isLoading || auth.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            Text(
              'Crear cuenta ☕',
              style: AppTextStyles.displayMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Regístrate para comenzar',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textGrey,
              ),
            ),

            const SizedBox(height: 30),

            // ── Nombre ─────────────────────────────────────────
            TextField(
              controller: nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej: Juan Pérez',
              ),
            ),

            const SizedBox(height: 14),

            // ── Email ──────────────────────────────────────────
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                hintText: 'ejemplo@correo.com',
              ),
            ),

            const SizedBox(height: 14),

            // ── Teléfono ──────────────────────────────────────
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
                hintText: 'Ej: +52 123 456 7890',
              ),
            ),

            const SizedBox(height: 14),

            // ── Contraseña ────────────────────────────────────
            TextField(
              controller: passCtrl,
              obscureText: !_showPassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _register(auth),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                hintText: 'Mínimo 6 caracteres',
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.textGrey,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Términos y condiciones ──────────────────────
            Row(
              children: [
                Checkbox(
                  value: _acceptTerms,
                  onChanged: (value) =>
                      setState(() => _acceptTerms = value ?? false),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _acceptTerms = !_acceptTerms),
                    child: Text(
                      'Acepto los términos y condiciones',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Botón registro ──────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _register(auth),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Crear cuenta'),
              ),
            ),

            const SizedBox(height: 16),

            // ── Volver a login ──────────────────────────────
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '¿Ya tienes cuenta? Inicia sesión',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                  ),
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