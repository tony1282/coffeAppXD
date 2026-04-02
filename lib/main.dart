import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Screens/auth/google_login_screen.dart';
import 'Screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Shop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B35)),
        useMaterial3: true,
      ),
      // StreamBuilder detecta si el usuario ya está logueado o no
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Cargando...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFFFFBF8),
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF6B35),
                ),
              ),
            );
          }
          // Si hay sesión activa → Home
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          // Si no hay sesión → Login
          return const GoogleLoginScreen();
        },
      ),
      routes: {
        '/login': (_) => const GoogleLoginScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}