import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:movly/features/movies/presentation/liking_titles.dart';
import 'package:movly/features/movies/presentation/home/home_page.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';
import 'package:movly/firebase_options.dart';
import 'package:movly/features/auth/presentation/pages/login_page.dart';
import 'themes/light_mode.dart';
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

      theme: lightMode,
      // Start on the login page
      initialRoute: '/preHome',
      routes: {
        '/login': (context) => const LoginPage(),
        '/preHome': (context) => const PreHomePage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
   