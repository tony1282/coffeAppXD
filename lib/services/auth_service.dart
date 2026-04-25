import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final FirebaseAuth      _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final ApiService        _api  = ApiService();
  bool _googleInitialized = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── Inicializar Google ───────────────────────────────────────────
  Future<void> _initializeGoogle() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '240474115166-a9dgsph1moh247c2klilssr1v7gr5bcr.apps.googleusercontent.com',
      );
      _googleInitialized = true;
    }
  }

  // ── Leer UserModel desde Firestore ───────────────────────────────
  Future<UserModel?> fetchUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  // ── LOGIN CON GOOGLE ─────────────────────────────────────────────
  Future<User?> signInWithGoogle() async {
    await _initializeGoogle();

    final googleUser  = await GoogleSignIn.instance.authenticate();
    final googleAuth  = googleUser.authentication;
    final credential  = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
    final result      = await _auth.signInWithCredential(credential);
    final user        = result.user;
    if (user == null) return null;

    // Conservar rol existente si ya tenía cuenta
    final existing   = await _db.collection('users').doc(user.uid).get();
    final rolActual  = existing.exists ? (existing.data()?['rol'] ?? 'cliente') : 'cliente';

    await _db.collection('users').doc(user.uid).set({
      'userId':    user.uid,
      'userName':  user.displayName ?? '',
      'userEmail': user.email       ?? '',
      'photoUrl':  user.photoURL    ?? '',
      'provider':  'google',
      'rol':       rolActual,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await syncUserWithBackend();
    return user;
  }

  // ── LOGIN CON EMAIL ──────────────────────────────────────────────
  Future<User?> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email, password: password,
    );
    await syncUserWithBackend();
    return cred.user;
  }

  // ── REGISTRO CON EMAIL ───────────────────────────────────────────
  Future<User?> registerWithEmail(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: password,
    );
    final user = cred.user;
    if (user == null) return null;

    await _db.collection('users').doc(user.uid).set({
      'userId':    user.uid,
      'userName':  name,
      'userEmail': email,
      'photoUrl':  '',
      'provider':  'email',
      'rol':       'cliente',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await syncUserWithBackend();
    return user;
  }

  // ── SYNC BACKEND ─────────────────────────────────────────────────
  Future<void> syncUserWithBackend() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final idToken = await user.getIdToken();
    await _api.post("/auth/firebase/", {"id_token": idToken});
  }

  // ── LOGOUT ───────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    try { await GoogleSignIn.instance.signOut(); } catch (_) {}
  }
}