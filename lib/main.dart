import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
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
      title: 'Movly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mov.ly',
          style: GoogleFonts.lilyScriptOne(
            fontSize: 28,
          ),
        ),
        centerTitle: true,
      ),

      body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            
            children: [
              Text(
                "To use this app, please sign in.",
                style: GoogleFonts.kronaOne(
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ),
          
              const SizedBox(height: 50),

              ElevatedButton(
                onPressed: () {
                  // Navigate to the sign-in screen
                },
                child: const Text('Sign In with Google'),
              ),
              ],
          ),
      ),
    );
  }
}