import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:movly/firebase_options.dart';
import 'package:movly/features/auth/presentation/pages/login_page.dart';
import 'themes/light_mode.dart';

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mov.ly',

      theme: lightMode,
      // Start on the login page
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        /*'/home': (context) => const HomePage(),*/
      },
    );
  }
}
