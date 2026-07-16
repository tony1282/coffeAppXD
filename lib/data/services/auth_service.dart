import 'dart:async';
import 'api_service.dart';
import '../models/user_model.dart';
import '../../core/config/api_config.dart';
import '../../core/error/exceptions.dart';
import '../../core/utils/validators.dart';
import '../../core/error/error_messages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// data/services/auth_service.dart

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ApiService _api = ApiService();
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
        throw AuthException(ErrorMessages.googleCancelled);
      }
      throw AuthException(ErrorMessages.googleFailed);
    } catch (e) {
      _logSecure('signInWithGoogle',
          'unexpected during GoogleSignIn: ${e.runtimeType}');
      throw AuthException(ErrorMessages.googleFailed);
    }

    if (googleUser == null) {
      throw AuthException(ErrorMessages.googleFailed);
    }

    try {
      googleAuth = await googleUser.authentication;
    } catch (e) {
      _logSecure(
          'signInWithGoogle', 'failed to get authentication: ${e.runtimeType}');
      throw AuthException(ErrorMessages.googleFailed);
    }

    if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
      throw AuthException(ErrorMessages.googleFailed);
    }

    UserCredential result;
    try {
      final credential =
          GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      result = await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException(ErrorMessages.googleFailed);
    }

    final user = result.user;
    if (user == null || user.uid.isEmpty) {
      throw AuthException(ErrorMessages.accountIncomplete);
    }

    try {
      final existing = await _db.collection('users').doc(user.uid).get();
      final rolActual = existing.exists
          ? (existing.data()?['rol'] as String? ?? 'cliente')
          : 'cliente';

      final userData = {
        'userId': user.uid,
        'userName': user.displayName ?? '',
        'userEmail': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'provider': 'google',
        'rol': rolActual,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _db
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      _logSecure('signInWithGoogle', 'Firestore write failed: ${e.code}');
    }

    try {
      await syncUserWithBackend(
        name: user.displayName ?? '',
        email: user.email ?? '',
        photoUrl: user.photoURL ?? '',
      );
    } catch (e) {
      _logSecure('signInWithGoogle', 'backend sync failed — non-blocking');
    }

    return user;
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return ErrorMessages.invalidCredentials;
      case 'email-already-in-use':
        return ErrorMessages.emailAlreadyInUse;
      case 'weak-password':
        return ErrorMessages.weakPassword;
      case 'user-disabled':
        return ErrorMessages.userDisabled;
      case 'network-request-failed':
        return ErrorMessages.noInternet;
      default:
        return ErrorMessages.unknown;
    }
  }

  // ============================================================
  // LOGIN CON EMAIL
  // ============================================================
  Future<User?> signInWithEmail(String email, String password) async {
    if (!Validators.isValidEmail(email)) {
      throw AuthException(ErrorMessages.invalidEmail);
    }
    if (!Validators.isValidPassword(password)) {
      throw AuthException(ErrorMessages.weakPassword);
    }

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = cred.user;
      if (user == null || user.uid.isEmpty) {
        throw AuthException(ErrorMessages.accountIncomplete);
      }

      try {
        await syncUserWithBackend(
          name: user.displayName ?? '',
          email: user.email ?? '',
          photoUrl: user.photoURL ?? '',
        );
      } catch (e) {
        _logSecure('signInWithEmail', 'backend sync failed — non-blocking');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException(ErrorMessages.unknown);
    }
  }

  // ============================================================
  // REGISTRO CON EMAIL
  // ============================================================
  Future<User?> registerWithEmail(
    String name,
    String email,
    String password, {
    String? phone,
  }) async {
    if (!Validators.isValidName(name)) {
      throw AuthException(ErrorMessages.invalidName);
    }
    if (!Validators.isValidEmail(email)) {
      throw AuthException(ErrorMessages.invalidEmail);
    }
    if (!Validators.isValidPassword(password)) {
      throw AuthException(ErrorMessages.weakPassword);
    }
    if (!Validators.isValidPhone(phone)) {
      throw AuthException(ErrorMessages.invalidPhone);
    }

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = cred.user;
      if (user == null || user.uid.isEmpty) {
        throw AuthException(ErrorMessages.accountIncomplete);
      }

      // ✅ ACTUALIZAR NOMBRE EN FIREBASE AUTH
      await user.updateDisplayName(name.trim());
      await user.reload();

      final userData = {
        'userId': user.uid,
        'userName': name.trim(),
        'userEmail': email.trim(),
        'photoUrl': '',
        'provider': 'email',
        'rol': 'cliente',
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _db.collection('users').doc(user.uid).set(userData);

      try {
        await syncUserWithBackend(
          name: name.trim(),
          email: email.trim(),
          photoUrl: '',
        );
      } catch (e) {
        _logSecure('registerWithEmail', 'backend sync failed — non-blocking');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException(ErrorMessages.unknown);
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
    final user = _auth.currentUser;
    if (user == null) return false;

    if (!Validators.isValidPhone(phone)) return false;

    try {
      if (name != null || photoUrl != null) {
        await user.updateDisplayName(name);
        await user.updatePhotoURL(photoUrl);
        await user.reload();
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (name != null && name.trim().isNotEmpty)
        updateData['userName'] = name.trim();
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;
      if (phone != null) updateData['phone'] = phone.trim();

      await _db.collection('users').doc(user.uid).update(updateData);

      return true;
    } catch (e) {
      _logSecure('updateUserProfile', 'error: ${e.runtimeType}');
      return false;
    }
  }

  // ============================================================
  // SYNC BACKEND (AHORA ENVÍA NOMBRE Y EMAIL)
  // ============================================================
  Future<void> syncUserWithBackend({
    String? name,
    String? email,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.uid.isEmpty) return;

    String? idToken;
    try {
      idToken = await user.getIdToken();
    } catch (e) {
      throw AuthException(ErrorMessages.sessionExpired);
    }

    if (idToken == null || idToken.isEmpty) {
      throw AuthException(ErrorMessages.sessionExpired);
    }

    try {
      // ✅ ENVIAR NOMBRE Y EMAIL EN EL BODY
      await _api.post(ApiConfig.authFirebaseEndpoint, {
        'id_token': idToken,
        'name': name ?? user.displayName ?? '',
        'email': email ?? user.email ?? '',
        'photo_url': photoUrl ?? user.photoURL ?? '',
      });
    } catch (e) {
      _logSecure('syncUserWithBackend', 'API error: ${e.runtimeType}');
      rethrow;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      _logSecure('logout', 'Firebase signOut error: ${e.runtimeType}');
    }

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  // ============================================================
  // FETCH USER MODEL
  // ============================================================
  Future<UserModel?> fetchUserModel(String uid) async {
    if (uid.trim().isEmpty) return null;

    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;

      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      _logSecure('fetchUserModel', 'error: ${e.runtimeType}');
      return null;
    }
  }
}
