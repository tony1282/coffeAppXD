import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:coffe_app/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _googleInitialized = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Inicializar Google Sign In una sola vez
  Future<void> _initializeGoogle() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '240474115166-a9dgsph1moh247c2klilssr1v7gr5bcr.apps.googleusercontent.com',
      );
      _googleInitialized = true;
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    await _initializeGoogle();

    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    final googleAuth = googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) return null;

    final userModel = UserModel(
      userId: user.uid,
      userName: user.displayName ?? '',
      userEmail: user.email ?? '',
      photoUrl: user.photoURL ?? '',
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(userModel.toMap(), SetOptions(merge: true));

    return userModel;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn.instance.signOut();
  }
}