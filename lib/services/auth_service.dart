// lib/services/auth_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'api_service.dart';

// ─── CONSTANTES DE SEGURIDAD ─────────────────────────────────────
class _AuthSecurityConfig {
  static const int minPasswordLength = 8;
  static const int maxEmailLength = 254;
  static const int maxPasswordLength = 128;
  static const int maxNameLength = 100;
  static const Duration operationTimeout = Duration(seconds: 20);
  
  // ✅ NUEVO: límites para teléfono
  static const int maxPhoneLength = 20;
  
  static const List<String> allowedUserFields = [
    'userId', 'userName', 'userEmail', 'photoUrl',
    'provider', 'rol', 'createdAt', 'updatedAt',
    'phone',  // ✅ Agregar phone a whitelist
  ];
}

// ─── ERRORES SANITIZADOS ─────────────────────────────────────────
class _AuthErrors {
  static const String invalidCredentials   = 'Correo o contraseña incorrectos';
  static const String emailAlreadyInUse    = 'Este correo ya está registrado';
  static const String invalidEmail         = 'El correo electrónico no es válido';
  static const String weakPassword         = 'La contraseña debe tener al menos 8 caracteres';
  static const String userDisabled         = 'Esta cuenta ha sido deshabilitada';
  static const String networkError         = 'Sin conexión. Verifica tu internet';
  static const String googleCancelled      = 'Inicio de sesión cancelado';
  static const String googleFailed         = 'No se pudo iniciar sesión con Google';
  static const String sessionExpired       = 'Tu sesión expiró. Inicia sesión nuevamente';
  static const String unknown              = 'Ocurrió un error. Intenta de nuevo';
  static const String syncFailed           = 'Error al sincronizar cuenta. Intenta de nuevo';
  static const String invalidName          = 'El nombre no puede estar vacío';
  static const String emptyEmail           = 'El correo no puede estar vacío';
  static const String emptyPassword        = 'La contraseña no puede estar vacía';
  static const String accountIncomplete    = 'Registro incompleto. Contacta soporte';
  
  // ✅ NUEVOS ERRORES
  static const String invalidPhone         = 'Número de teléfono inválido';
  static const String updateFailed         = 'Error al actualizar el perfil';
}

class AuthService {
  final FirebaseAuth      _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final ApiService        _api  = ApiService();
  bool _googleInitialized = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  void _logSecure(String method, String event, {String? detail}) {
    assert(() {
      final safeDetail = detail != null ? ' | $detail' : '';
      print('[AuthService][$method] $event$safeDetail');
      return true;
    }());
  }

  // ============================================================
  // VALIDACIONES DE INPUT
  // ============================================================
  void _validateEmail(String email) {
    if (email.trim().isEmpty) throw Exception(_AuthErrors.emptyEmail);
    if (email.length > _AuthSecurityConfig.maxEmailLength) {
      throw Exception(_AuthErrors.invalidEmail);
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email.trim())) {
      throw Exception(_AuthErrors.invalidEmail);
    }
  }

  void _validatePassword(String password) {
    if (password.isEmpty) throw Exception(_AuthErrors.emptyPassword);
    if (password.length < _AuthSecurityConfig.minPasswordLength) {
      throw Exception(_AuthErrors.weakPassword);
    }
    if (password.length > _AuthSecurityConfig.maxPasswordLength) {
      throw Exception(_AuthErrors.weakPassword);
    }
  }

  void _validateName(String name) {
    if (name.trim().isEmpty) throw Exception(_AuthErrors.invalidName);
    if (name.trim().length > _AuthSecurityConfig.maxNameLength) {
      throw Exception(_AuthErrors.invalidName);
    }
  }

  // ✅ VALIDACIÓN DE TELÉFONO
  void _validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return;
    
    final trimmed = phone.trim();
    if (trimmed.length > _AuthSecurityConfig.maxPhoneLength) {
      throw Exception(_AuthErrors.invalidPhone);
    }
    
    final phoneRegex = RegExp(r'^[0-9+\-\s()]+$');
    if (!phoneRegex.hasMatch(trimmed)) {
      throw Exception(_AuthErrors.invalidPhone);
    }
  }

  Exception _mapFirebaseAuthError(FirebaseAuthException e) {
    _logSecure('_mapFirebaseAuthError', 'code: ${e.code}');
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return Exception(_AuthErrors.invalidCredentials);
      case 'email-already-in-use':
        return Exception(_AuthErrors.emailAlreadyInUse);
      case 'weak-password':
        return Exception(_AuthErrors.weakPassword);
      case 'user-disabled':
        return Exception(_AuthErrors.userDisabled);
      case 'network-request-failed':
        return Exception(_AuthErrors.networkError);
      case 'session-expired':
      case 'token-expired':
      case 'id-token-expired':
        return Exception(_AuthErrors.sessionExpired);
      default:
        return Exception(_AuthErrors.unknown);
    }
  }

  void _assertValidUser(User? user, String context) {
    if (user == null) {
      _logSecure('_assertValidUser', 'null user after $context');
      throw Exception(_AuthErrors.unknown);
    }
    if (user.uid.isEmpty) {
      _logSecure('_assertValidUser', 'empty uid after $context');
      throw Exception(_AuthErrors.accountIncomplete);
    }
  }

  Map<String, dynamic> _sanitizeFirestoreData(Map<String, dynamic> data) {
    return Map.fromEntries(
      data.entries.where(
        (e) => _AuthSecurityConfig.allowedUserFields.contains(e.key),
      ),
    );
  }

  // ============================================================
  // GOOGLE SIGN IN
  // ============================================================
  Future<void> _initializeGoogle() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '240474115166-a9dgsph1moh247c2klilssr1v7gr5bcr.apps.googleusercontent.com',
      );
      _googleInitialized = true;
    }
  }

  Future<User?> signInWithGoogle() async {
    await _initializeGoogle();

    GoogleSignInAccount? googleUser;
    GoogleSignInAuthentication? googleAuth;

    try {
      googleUser = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      _logSecure('signInWithGoogle', 'GoogleSignInException: ${e.code}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception(_AuthErrors.googleCancelled);
      }
      throw Exception(_AuthErrors.googleFailed);
    } catch (e) {
      _logSecure('signInWithGoogle', 'unexpected during GoogleSignIn: ${e.runtimeType}');
      throw Exception(_AuthErrors.googleFailed);
    }

    try {
      googleAuth = googleUser.authentication;
    } catch (e) {
      _logSecure('signInWithGoogle', 'failed to get authentication: ${e.runtimeType}');
      throw Exception(_AuthErrors.googleFailed);
    }

    if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
      _logSecure('signInWithGoogle', 'null or empty idToken from Google');
      throw Exception(_AuthErrors.googleFailed);
    }

    UserCredential result;
    try {
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      result = await _auth
          .signInWithCredential(credential)
          .timeout(_AuthSecurityConfig.operationTimeout);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } on TimeoutException {
      throw Exception(_AuthErrors.networkError);
    }

    final user = result.user;
    _assertValidUser(user, 'Google signIn');

    try {
      final existing = await _db
          .collection('users')
          .doc(user!.uid)
          .get()
          .timeout(_AuthSecurityConfig.operationTimeout);

      final rolActual = existing.exists
          ? (existing.data()?['rol'] as String? ?? 'cliente')
          : 'cliente';

      final userData = _sanitizeFirestoreData({
        'userId':    user.uid,
        'userName':  user.displayName ?? '',
        'userEmail': user.email       ?? '',
        'photoUrl':  user.photoURL    ?? '',
        'provider':  'google',
        'rol':       rolActual,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _db
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true))
          .timeout(_AuthSecurityConfig.operationTimeout);
    } on FirebaseException catch (e) {
      _logSecure('signInWithGoogle', 'Firestore write failed: ${e.code}');
    }

    try {
      await syncUserWithBackend();
    } catch (e) {
      _logSecure('signInWithGoogle', 'backend sync failed — non-blocking');
    }

    return user;
  }

  // ============================================================
  // LOGIN CON EMAIL
  // ============================================================
  Future<User?> signInWithEmail(String email, String password) async {
    _validateEmail(email);
    _validatePassword(password);

    UserCredential cred;
    try {
      cred = await _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(_AuthSecurityConfig.operationTimeout);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } on TimeoutException {
      throw Exception(_AuthErrors.networkError);
    } catch (e) {
      _logSecure('signInWithEmail', 'unexpected: ${e.runtimeType}');
      throw Exception(_AuthErrors.unknown);
    }

    _assertValidUser(cred.user, 'email signIn');

    try {
      await syncUserWithBackend();
    } catch (e) {
      _logSecure('signInWithEmail', 'backend sync failed — non-blocking');
    }

    return cred.user;
  }

  // ============================================================
  // REGISTRO CON EMAIL (con teléfono opcional)
  // ============================================================
  Future<User?> registerWithEmail(
    String name, 
    String email, 
    String password, {
    String? phone,
  }) async {
    _validateName(name);
    _validateEmail(email);
    _validatePassword(password);
    _validatePhone(phone);  // ✅ Validar teléfono

    UserCredential cred;
    try {
      cred = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(_AuthSecurityConfig.operationTimeout);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } on TimeoutException {
      throw Exception(_AuthErrors.networkError);
    } catch (e) {
      _logSecure('registerWithEmail', 'unexpected: ${e.runtimeType}');
      throw Exception(_AuthErrors.unknown);
    }

    final user = cred.user;
    _assertValidUser(user, 'email register');

    try {
      final userData = _sanitizeFirestoreData({
        'userId':    user!.uid,
        'userName':  name.trim(),
        'userEmail': email.trim(),
        'photoUrl':  '',
        'provider':  'email',
        'rol':       'cliente',
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),  // ✅ Guardar teléfono
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db
          .collection('users')
          .doc(user.uid)
          .set(userData)
          .timeout(_AuthSecurityConfig.operationTimeout);
    } on FirebaseException catch (e) {
      _logSecure('registerWithEmail', 'Firestore failed after Auth create: ${e.code}');
      try {
        await user!.delete();
        _logSecure('registerWithEmail', 'orphan Auth account cleaned up');
      } catch (deleteError) {
        _logSecure('registerWithEmail', 'failed to clean orphan account: ${deleteError.runtimeType}');
      }
      throw Exception(_AuthErrors.accountIncomplete);
    }

    try {
      await syncUserWithBackend();
    } catch (e) {
      _logSecure('registerWithEmail', 'backend sync failed — non-blocking');
    }

    return user;
  }

  // ============================================================
  // ✅ ACTUALIZAR PERFIL DE USUARIO (nombre, foto, teléfono)
  // ============================================================
  Future<bool> updateUserProfile({
    String? name,
    String? photoUrl,
    String? phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _logSecure('updateUserProfile', 'no user logged in');
      return false;
    }

    _validatePhone(phone);  // ✅ Validar teléfono

    try {
      // Actualizar Firebase Auth (nombre y foto)
      if (name != null || photoUrl != null) {
        await user.updateDisplayName(name);
        await user.updatePhotoURL(photoUrl);
        await user.reload();
      }

      // Actualizar Firestore
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (name != null && name.trim().isNotEmpty) {
        updateData['userName'] = name.trim();
      }
      if (photoUrl != null) {
        updateData['photoUrl'] = photoUrl;
      }
      if (phone != null) {
        updateData['phone'] = phone.trim();
      }

      await _db
          .collection('users')
          .doc(user.uid)
          .update(updateData)
          .timeout(_AuthSecurityConfig.operationTimeout);

      _logSecure('updateUserProfile', 'profile updated successfully');
      return true;
    } on FirebaseException catch (e) {
      _logSecure('updateUserProfile', 'FirebaseException: ${e.code}');
      return false;
    } on TimeoutException {
      _logSecure('updateUserProfile', 'timeout');
      return false;
    } catch (e) {
      _logSecure('updateUserProfile', 'unexpected: ${e.runtimeType}');
      return false;
    }
  }

  // ============================================================
  // SYNC BACKEND
  // ============================================================
  Future<void> syncUserWithBackend() async {
    final user = _auth.currentUser;
    if (user == null) {
      _logSecure('syncUserWithBackend', 'skipped — no current user');
      return;
    }

    if (user.uid.isEmpty) {
      _logSecure('syncUserWithBackend', 'skipped — empty uid');
      return;
    }

    String? idToken;
    try {
      idToken = await user
          .getIdToken()
          .timeout(_AuthSecurityConfig.operationTimeout);
    } on FirebaseAuthException catch (e) {
      _logSecure('syncUserWithBackend', 'token fetch failed: ${e.code}');
      throw Exception(_AuthErrors.sessionExpired);
    } on TimeoutException {
      _logSecure('syncUserWithBackend', 'token fetch timeout');
      throw Exception(_AuthErrors.networkError);
    }

    if (idToken == null || idToken.isEmpty) {
      _logSecure('syncUserWithBackend', 'null/empty token — aborting sync');
      throw Exception(_AuthErrors.sessionExpired);
    }

    try {
      await _api
          .post('/auth/firebase/', {'id_token': idToken})
          .timeout(_AuthSecurityConfig.operationTimeout);
    } on TimeoutException {
      _logSecure('syncUserWithBackend', 'API call timeout');
      throw Exception(_AuthErrors.syncFailed);
    } catch (e) {
      _logSecure('syncUserWithBackend', 'API error: ${e.runtimeType}');
      throw Exception(_AuthErrors.syncFailed);
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> logout() async {
    try {
      await _auth
          .signOut()
          .timeout(_AuthSecurityConfig.operationTimeout);
    } on FirebaseAuthException catch (e) {
      _logSecure('logout', 'Firebase signOut error: ${e.code}');
    } on TimeoutException {
      _logSecure('logout', 'Firebase signOut timeout');
    }

    try {
      await GoogleSignIn.instance
          .signOut()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      _logSecure('logout', 'Google signOut skipped or failed — non-blocking');
    }
  }

  // ============================================================
  // FETCH USER MODEL
  // ============================================================
  Future<UserModel?> fetchUserModel(String uid) async {
    if (uid.trim().isEmpty) {
      _logSecure('fetchUserModel', 'empty uid provided');
      return null;
    }

    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get()
          .timeout(_AuthSecurityConfig.operationTimeout);

      if (!doc.exists || doc.data() == null) return null;

      try {
        return UserModel.fromMap(doc.data()!);
      } catch (e) {
        _logSecure('fetchUserModel', 'corrupted doc for uid prefix: ${uid.substring(0, 4)}***');
        return null;
      }
    } on FirebaseException catch (e) {
      _logSecure('fetchUserModel', 'FirebaseException: ${e.code}');
      return null;
    } on TimeoutException {
      _logSecure('fetchUserModel', 'timeout');
      return null;
    } catch (e) {
      _logSecure('fetchUserModel', 'unexpected: ${e.runtimeType}');
      return null;
    }
  }
}