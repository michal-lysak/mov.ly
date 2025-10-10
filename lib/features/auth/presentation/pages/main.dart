import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:movly/features/auth/presentation/pages/login_page.dart';
import '../../data/firebase_options.dart';
 

void main() async {
  // firebase setup
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Movly',
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}