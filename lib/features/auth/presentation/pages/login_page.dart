/*

LOGIN PAGE

ON:
Logged in-> Home Page
Not hav an account -> Register Page

*/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
                // TODO: Implement Google sign in navigation
              },
              child: const Text('Sign In with Google'),
            ),
          ],
        ),
      ),
    );
  }
}