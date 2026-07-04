// lib/main.dart

import 'package:coffe_app/presentation/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/admin/admin_dashboard.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/order_provider.dart';
import 'presentation/providers/product_provider.dart';
import 'presentation/providers/cart_provider.dart';
import 'presentation/providers/payment_provider.dart';
import 'data/models/cart_item_model.dart';
import 'core/config/constants.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(CartItemModelAdapter());
  await Hive.openBox<CartItemModel>('cart');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: MaterialApp(
        title: 'Coffee Shop',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
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

// ✅ FIX: StatefulWidget para mantener el Future estable.
// Si _AuthGate es StatelessWidget, cada notifyListeners() del AuthProvider
// reconstruye el widget y crea un nuevo Future → bucle infinito:
// loadUserModel → notifyListeners → rebuild → loadUserModel → ...
// Al guardar el Future en estado, solo se ejecuta una vez por sesión.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  Future<void>? _loadFuture;
  String? _lastUid;

  void _triggerLoad(String uid) {
    // Solo crea un nuevo Future si cambió el usuario
    if (_lastUid == uid && _loadFuture != null) return;
    _lastUid = uid;
    _loadFuture = context.read<AuthProvider>().loadUserModel();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          _loadFuture = null;
          _lastUid = null;
          return const LoginScreen();
        }

        final uid = snapshot.data!.uid;
        _triggerLoad(uid);

        return FutureBuilder<void>(
          future: _loadFuture,
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const _Splash();
            }
            if (roleSnap.hasError) {
              return const LoginScreen();
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