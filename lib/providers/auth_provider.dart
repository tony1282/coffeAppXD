import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool      isLoading = false;
  UserModel? userModel;

  bool get isAdmin => userModel?.isAdmin ?? false;

  // Carga el UserModel (con rol) desde Firestore
  Future<void> loadUserModel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { userModel = null; notifyListeners(); return; }
    userModel = await _authService.fetchUserModel(user.uid);
    notifyListeners();
  }

  // ── LOGIN CON GOOGLE ────────────────────────────────────────────
  Future<User?> signInWithGoogle() async {
    isLoading = true; notifyListeners();
    try {
      final user = await _authService.signInWithGoogle();
      await loadUserModel();
      return user;
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  // ── LOGIN CON EMAIL ─────────────────────────────────────────────
  Future<User?> loginWithEmail(String email, String password) async {
    isLoading = true; notifyListeners();
    try {
      final user = await _authService.signInWithEmail(email, password);
      await loadUserModel();
      return user;
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  // ── REGISTRO CON EMAIL ──────────────────────────────────────────
  Future<User?> registerWithEmail(String name, String email, String password) async {
    isLoading = true; notifyListeners();
    try {
      final user = await _authService.registerWithEmail(name, email, password);
      await loadUserModel();
      return user;
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  // ── LOGOUT ──────────────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.logout();
    userModel = null;
    notifyListeners();
  }
}