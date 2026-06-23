// presentation/providers/auth_provider.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/error/error_handler.dart';
import '../../core/error/failure.dart';
import '../../core/error/error_messages.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/validators.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool isLoading = false;
  UserModel? userModel;

  bool get isAdmin => userModel?.isAdmin ?? false;

  // ============================================================
  // HELPERS
  // ============================================================
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _handleFailure(Failure failure) {
    if (kDebugMode) {
      AppLogger.error('AuthProvider', failure.message);
    }
  }

  // ✅ Limpiar estado
  void clear() {
    userModel = null;
    isLoading = false;
    notifyListeners();
  }

  // ============================================================
  // LOAD USER MODEL
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
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
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
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
    }
  }

  // ============================================================
  // SIGN IN WITH GOOGLE
  // ============================================================
  Future<User?> signInWithGoogle() async {
    _setLoading(true);

    try {
      final user = await _authService.signInWithGoogle().timeout(
        const Duration(seconds: 30),
      );
      if (user != null) await loadUserModel();
      return user;
    } catch (e) {
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOGIN CON EMAIL
  // ============================================================
  Future<User?> loginWithEmail(String email, String password) async {
    if (!Validators.isValidEmail(email)) {
      throw Exception(ErrorMessages.invalidEmail);
    }
    if (!Validators.isValidPassword(password)) {
      throw Exception(ErrorMessages.weakPassword);
    }

    _setLoading(true);

    try {
      final user = await _authService.signInWithEmail(email, password).timeout(
        const Duration(seconds: 20),
      );
      if (user != null) await loadUserModel();
      return user;
    } on FirebaseAuthException catch (e) {
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
      throw Exception(failure.message);
    } on TimeoutException {
      throw Exception(ErrorMessages.timeout);
    } catch (e) {
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
      throw Exception(failure.message);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // REGISTRO CON EMAIL
  // ============================================================
  Future<User?> registerWithEmail({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    if (!Validators.isValidName(name)) {
      throw Exception(ErrorMessages.invalidName);
    }
    if (!Validators.isValidEmail(email)) {
      throw Exception(ErrorMessages.invalidEmail);
    }
    if (!Validators.isValidPassword(password)) {
      throw Exception(ErrorMessages.weakPassword);
    }
    if (phone != null && phone.trim().isNotEmpty && !Validators.isValidPhone(phone)) {
      throw Exception(ErrorMessages.invalidPhone);
    }

    _setLoading(true);

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
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
      throw Exception(failure.message);
    } on TimeoutException {
      throw Exception(ErrorMessages.timeout);
    } catch (e) {
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
      throw Exception(failure.message);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // ACTUALIZAR PERFIL
  // ============================================================
  Future<bool> updateUserProfile({
    String? name,
    String? photoUrl,
    String? phone,
  }) async {
    if (phone != null && phone.trim().isNotEmpty && !Validators.isValidPhone(phone)) {
      return false;
    }

    _setLoading(true);

    try {
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
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.logout().timeout(const Duration(seconds: 10));
      clear();
    } catch (e) {
      final failure = ErrorHandler.handleError(e);
      _handleFailure(failure);
      clear();
    } finally {
      _setLoading(false);
    }
  }
}