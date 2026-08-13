import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'theme/theme.dart';
import 'theme/app_colors.dart';
import 'state/app_state.dart';
import 'services/cart_service.dart';
import 'screens/auth/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('dotenv load note: $e');
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const DapzoApp());
}

class DapzoApp extends StatelessWidget {
  const DapzoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(
          create: (_) => AppState(),
        ),
        ChangeNotifierProvider<CartService>(
          create: (_) => CartService(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final appState = context.watch<AppState>();
          AppColors.isDarkMode = appState.isDarkMode;

          return MaterialApp(
            title: 'Dapzo',
            debugShowCheckedModeBanner: false,
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: AppTheme.light,
            darkTheme: AppTheme.light,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}