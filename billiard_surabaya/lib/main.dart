import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/providers/auth_provider.dart' as app_auth;
import 'core/providers/billiard_provider.dart';
import 'core/providers/favorite_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/main/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        // Provider autentikasi — dipakai seluruh app
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        // Provider data biliar — pre-fetch data saat pertama kali dibuat
        ChangeNotifierProvider(
          create: (_) => BilliardProvider()..fetchPlaces(),
        ),
        // Provider favorit — state lokal sementara
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
      ],
      child: MaterialApp(
        title: 'Billiard Surabaya',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthGate(),
      ),
    );
  }
}

/// AuthGate memutuskan halaman mana yang ditampilkan
/// berdasarkan status login user dari Firebase.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Masih menunggu status dari Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        // User sudah login → masuk ke app utama
        if (snapshot.hasData && snapshot.data != null) {
          return const MainShell();
        }

        // Belum login → halaman login
        return const LoginPage();
      },
    );
  }
}

/// Layar loading singkat saat menunggu status auth dari Firebase
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.neonGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.sports_bar_rounded,
                color: Colors.black,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Billiard Surabaya',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.neonGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
