import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/favorite_provider.dart';
import 'features/main/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const BilliardSurabayaApp());
}

class BilliardSurabayaApp extends StatelessWidget {
  const BilliardSurabayaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
      ],
      child: MaterialApp(
        title: 'Billiard Surabaya',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainShell(),
      ),
    );
  }
}
