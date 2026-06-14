import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/providers/favorite_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/main/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // ignore: avoid_print
    print('Firebase init error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Membungkus aplikasi dengan ChangeNotifierProvider agar State Management temanmu tetap berjalan
    return ChangeNotifierProvider(
      create: (context) => FavoriteProvider(),
      child: MaterialApp(
        title: 'Billiard Surabaya',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        // Sesuai screenshot struktur foldermu, arahkan ke halaman utama yang dibuat temanmu
        // Gantilah 'HomeScreen()' dengan nama Class halaman utama milik temanmu jika berbeda
        home: const MainShell(),
      ),
    );
  }
}