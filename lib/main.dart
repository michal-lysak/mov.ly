import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:movly/features/auth/presentation/components/auth_gate.dart'; // <-- Import the AuthGate
import 'package:movly/features/auth/presentation/pages/signup_username_page.dart';
import 'package:movly/features/movies/presentation/liking_titles.dart'; // Assuming this is PreHomePage
import 'package:movly/features/movies/presentation/home/home_page.dart';
import 'package:movly/firebase_options.dart';
import 'features/auth/presentation/components/auth_gate.dart';
import 'themes/dark_mode.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mov.ly',
      theme: darkMode,

      // 🎯 Set the home to the AuthGate. It handles whether to show
      // LoginOrRegister (logged out) or Home (logged in).
      home: const AuthGate(),

      // Keep the routes for navigation WITHIN the app,
      // but remove the redundant 'login' route.
      routes: {
        // Assuming LikingTitles is the actual widget for the '/preHome' route:
        '/preHome': (context) => const PreHomePage(),
        '/home': (context) => const HomePage(),
        '/username': (context) => const SignupUsernamePage(),
      },
    );
  }
}