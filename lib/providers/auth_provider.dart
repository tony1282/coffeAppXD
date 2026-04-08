import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool isLoading = false;

  // 🔹 LOGIN CON GOOGLE
  Future<User?> signInWithGoogle() async {
    isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle();
      return user;
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 LOGIN CON EMAIL
  Future<User?> loginWithEmail(String email, String password) async {
    isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmail(email, password);
      return user;
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 REGISTRO CON EMAIL
  Future<User?> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.registerWithEmail(
        name,
        email,
        password,
      );
      return user;
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 LOGOUT
  Future<void> logout() async {
    await _authService.logout();
  }
}