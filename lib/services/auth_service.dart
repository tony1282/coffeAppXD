import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ApiService _api = ApiService();
  bool _googleInitialized = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Inicializar Google
  Future<void> _initializeGoogle() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            'TU_SERVER_CLIENT_ID_AQUI',
      );
      _googleInitialized = true;
    }
  }

  // LOGIN CON GOOGLE
  Future<User?> signInWithGoogle() async {
    await _initializeGoogle();

    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    final googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await _auth.signInWithCredential(credential);

    final user = userCredential.user;
    if (user == null) return null;

    // Crear o actualizar usuario en Firestore
    final userModel = UserModel(
      userId: user.uid,
      userName: user.displayName ?? '',
      userEmail: user.email ?? '',
      photoUrl: user.photoURL ?? '',
    );

    await _db.collection('users').doc(user.uid).set({
      ...userModel.toMap(),
      'provider': 'google',
      'rol': 'cliente',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await syncUserWithBackend();

    return user;
  }

  // LOGIN CON EMAIL
  Future<User?> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await syncUserWithBackend();

    return cred.user;
  }

  // REGISTRO CON EMAIL
  Future<User?> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user == null) return null;

    // Guardar en Firestore
    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'nombre': name,
      'email': email,
      'provider': 'email',
      'rol': 'cliente',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await syncUserWithBackend();
    
    return user;
  }

  Future<void> syncUserWithBackend() async {
  final user = _auth.currentUser;

  if (user == null) return;

  final idToken = await user.getIdToken();

  await _api.post("/auth/firebase/", {
    "id_token": idToken,
  });
}

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
    await GoogleSignIn.instance.signOut();
  }
}