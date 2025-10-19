import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movly/features/auth/data/firebase_auth_repo.dart';
import 'package:movly/features/auth/presentation/components/google_sign_in_button.dart';
import 'package:movly/features/auth/presentation/components/my_button.dart';
import 'package:movly/features/auth/presentation/components/my_textfield.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuthRepo _authRepo = FirebaseAuthRepo();
  bool _isLoading = false;
  String? _errorMessage;

   // text controllers
  final emailController = TextEditingController();
  final pwController = TextEditingController();

 Future<void> signInWithEmailAndPassword() async {
  final String email = emailController.text.trim();
  final String pw = pwController.text.trim();

  // Show loading
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  if (email.isEmpty || pw.isEmpty) {
    setState(() {
      _isLoading = false;
      _errorMessage = "Email and password cannot be empty.";
    });
    return;
  }

  try {
    // Example using Firebase Auth
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: pw);

    // Login successful → navigate to home
    Navigator.pushReplacementNamed(context, '/home');

  } on FirebaseAuthException catch (e) {
    // Handle specific Firebase errors
    String message;
    if (e.code == 'user-not-found') {
      message = "No user found for that email.";
    } else if (e.code == 'wrong-password') {
      message = "Wrong password provided.";
    } else {
      message = "Login failed: ${e.message}";
    }

    setState(() => _errorMessage = message);
  } catch (e) {
    setState(() => _errorMessage = "Something went wrong: $e");
  } finally {
    setState(() => _isLoading = false);
  }
}


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
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            
            children: [
              Text(
                "To use this app, you need to sign in.",
                style: GoogleFonts.kronaOne(
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),

              

              const SizedBox(height: 20),

             _isLoading
                ? 
                    const CircularProgressIndicator()
              : Column(
                children: [
              
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
                

                const SizedBox(height: 10),

                MyButton(
                  onTap: signInWithEmailAndPassword,
                  text: "Sign in"
                ),


                const SizedBox(height: 10),

                if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
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
