// lib/main.dart

import 'package:coffe_app/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'models/cart_item_model.dart';  // ✅ AGREGAR (si creaste el modelo)
import 'config/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Inicializar Hive para persistencia local
  await Hive.initFlutter();
  
  // ✅ Registrar adaptador (después de ejecutar build_runner)
  Hive.registerAdapter(CartItemModelAdapter());
  
  // ✅ Abrir la caja del carrito
  await Hive.openBox<CartItemModel>('cart');
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Coffee Shop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: true,
        ),
        home: const _AuthGate(),
        routes: {
          '/login':    (_) => const LoginScreen(),
          '/home':     (_) => const HomeScreen(),
          '/register': (_) => const RegisterScreen(),
          '/admin':    (_) => const AdminDashboard(),
        },
      ),
    );
  }
}

// Decide a dónde ir al abrir la app según sesión y rol
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }

        if (!snapshot.hasData) return const LoginScreen();

        return FutureBuilder(
          future: context.read<AuthProvider>().loadUserModel(),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const _Splash();
            }
            final isAdmin = context.read<AuthProvider>().isAdmin;
            return isAdmin ? const AdminDashboard() : const HomeScreen();
          },
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
}