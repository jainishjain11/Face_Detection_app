import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/session_history_screen.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const FaceAIProApp());
}

class FaceAIProApp extends StatelessWidget {
  const FaceAIProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FaceAI Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(
          AppTheme.darkTheme.textTheme,
        ),
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(
          AppTheme.darkTheme.textTheme,
        ),
      ),
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/signup': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/camera': (context) => const CameraScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/session-history': (context) => const SessionHistoryScreen(),
      },
    );
  }
}
