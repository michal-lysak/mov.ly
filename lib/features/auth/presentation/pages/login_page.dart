import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movly/features/auth/data/firebase_auth_repo.dart';
import 'package:movly/features/auth/presentation/components/google_sign_in_button.dart';
//import 'package:movly/features/auth/presentation/components/my_textfield.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuthRepo _authRepo = FirebaseAuthRepo();
  bool _isLoading = false;
  String? _errorMessage;

  /* // text controllers
  final emailController = TextEditingController();
  final pwController = TextEditingController();
*/

  // Google Sign-In
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authRepo.signInWithGoogle();
      if (user != null) {
        // Navigate to home after login
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => _errorMessage = "Google Sign-In cancelled.");
      }
    } catch (e) {
      setState(() => _errorMessage = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            
            children: [
              Text(
                "To use this app, please sign in.",
                style: GoogleFonts.kronaOne(
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),

              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 20),

             _isLoading
                ? 
                    const CircularProgressIndicator()
              : Column(
                children: [
              /*
                // email textfield
                MyTextfield(
                  controller: emailController,
                  hintText: "Email",
                  obscureText: false,
                ),

                const SizedBox(height: 10),

                //pw textfield
                MyTextfield(
                  controller: pwController, 
                  hintText: "Password", 
                  obscureText: true,
                ),
                */

                const SizedBox(height: 10),

                MyGoogleSignInButton(onTap: _signInWithGoogle),
            ],
            ),
            ],
          ),
        ),
      ),
    );
  }
}
