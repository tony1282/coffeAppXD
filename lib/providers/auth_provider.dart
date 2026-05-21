// lib/providers/auth_provider.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool isLoading = false;
  UserModel? userModel;

  bool get isAdmin => userModel?.isAdmin ?? false;

  // ============================================================
  // DEFENSIVE + SANITIZACIÓN
  // ============================================================
  String _sanitizeFirebaseError(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('network')) return 'Sin conexión a internet';
    if (msg.contains('wrong-password') || msg.contains('user-not-found'))
      return 'Correo o contraseña incorrectos';
    if (msg.contains('email-already-in-use')) return 'El correo ya está registrado';
    if (msg.contains('weak-password')) return 'La contraseña debe tener al menos 6 caracteres';
    if (msg.contains('too-many-requests')) return 'Demasiados intentos. Espera unos minutos';
    return 'Error inesperado. Intenta de nuevo';
  }

  bool _isValidEmail(String email) {
    return email.contains('@') && email.length <= 254;
  }

  bool _isValidPassword(String pwd) => pwd.length >= 6;
  
  // ✅ VALIDACIÓN DE TELÉFONO
  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[0-9+\-\s()]+$');
    return phone.trim().isNotEmpty && phone.length <= 20 && phoneRegex.hasMatch(phone);
  }

  // ============================================================
  // LOAD USER MODEL (con defensa)
  // ============================================================
  Future<void> loadUserModel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      userModel = null;
      notifyListeners();
      return;
    }

    try {
      final model = await _authService.fetchUserModel(user.uid).timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      userModel = model;
    } catch (e) {
      userModel = null;
    }
    notifyListeners();
  }

  // ✅ Refrescar datos del usuario
  Future<void> refreshUserModel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final model = await _authService.fetchUserModel(user.uid);
      if (model != null) {
        userModel = model;
        notifyListeners();
      }
    } catch (e) {
      // Silencioso
    }
  }

  // ✅ Limpiar estado
  void clear() {
    userModel = null;
    isLoading = false;
    notifyListeners();
  }

  // ============================================================
  // SIGN IN WITH GOOGLE
  // ============================================================
  Future<User?> signInWithGoogle() async {
    isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle().timeout(
        const Duration(seconds: 30),
      );
      if (user != null) await loadUserModel();
      return user;
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // LOGIN CON EMAIL (validación + sanitización)
  // ============================================================
  Future<User?> loginWithEmail(String email, String password) async {
    if (!_isValidEmail(email)) throw Exception('Correo inválido');
    if (!_isValidPassword(password)) throw Exception('La contraseña es muy corta');

    isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmail(email, password).timeout(
        const Duration(seconds: 20),
      );
      if (user != null) await loadUserModel();
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_sanitizeFirebaseError(e));
    } on TimeoutException {
      throw Exception('La solicitud tardó demasiado');
    } catch (e) {
      throw Exception('Error inesperado');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // REGISTRO CON EMAIL (con teléfono opcional)
  // ============================================================
  Future<User?> registerWithEmail({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    if (name.trim().isEmpty) throw Exception('El nombre es obligatorio');
    if (!_isValidEmail(email)) throw Exception('Correo inválido');
    if (!_isValidPassword(password)) throw Exception('La contraseña debe tener al menos 6 caracteres');
    
    // ✅ Validar teléfono si se proporciona
    if (phone != null && phone.trim().isNotEmpty && !_isValidPhone(phone)) {
      throw Exception('Teléfono inválido');
    }

    isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.registerWithEmail(
        name.trim(),
        email.trim(),
        password,
        phone: phone?.trim(),
      ).timeout(const Duration(seconds: 20));
      
      if (user != null) await loadUserModel();
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_sanitizeFirebaseError(e));
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado');
    } catch (e) {
      throw Exception('Error en el registro');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ACTUALIZAR PERFIL (nombre, foto, teléfono)
  // ============================================================
  Future<bool> updateUserProfile({
    String? name,
    String? photoUrl,
    String? phone,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      // ✅ Validar teléfono si se proporciona
      if (phone != null && phone.trim().isNotEmpty && !_isValidPhone(phone)) {
        throw Exception('Teléfono inválido');
      }

      final success = await _authService.updateUserProfile(
        name: name,
        photoUrl: photoUrl,
        phone: phone,
      );
      
      if (success) {
        await refreshUserModel();
      }
      
      return success;
    } catch (e) {
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // LOGOUT (seguro)
  // ============================================================
  Future<void> logout() async {
    isLoading = true;
    notifyListeners();

    try {
      await _authService.logout().timeout(const Duration(seconds: 10));
      clear();
    } catch (_) {
      clear();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}