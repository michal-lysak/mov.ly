import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Note: Assuming these imports exist in your project structure
import 'package:movly/features/auth/data/firebase_auth_repo.dart';
import 'package:movly/features/auth/presentation/components/my_button.dart';
import 'package:movly/features/auth/presentation/components/my_textfield.dart';

class SignupPage extends StatefulWidget {
  // Callback function provided by the parent (LoginOrRegister) to switch to login view
  final void Function()? onLoginTap;

  const SignupPage({super.key, required this.onLoginTap});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Text editing controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final pwController = TextEditingController();
  final confirmPwController = TextEditingController();

  // Authentication and state management
  final FirebaseAuthRepo _authRepo = FirebaseAuthRepo();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    pwController.dispose();
    confirmPwController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    final String name = nameController.text.trim();
    final String email = emailController.text.trim();
    final String password = pwController.text.trim();
    final String confirmPassword = confirmPwController.text.trim();

    // 1. Initial State & Validation Check
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = "Passwords do not match.";
        _isLoading = false;
      });
      return;
    }

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = "All fields are required.";
        _isLoading = false;
      });
      return;
    }

    // 2. Firebase Registration
    try {
      final user = await _authRepo.registerWithEmailPassword(name, email, password);

      if (!mounted) return;

      if (user != null) {
        // Registration succeeded. Navigate to the username creation page.
        // This is the correct path after registration!
        Navigator.pushReplacementNamed(context, '/username');

      } else {
        setState(() => _errorMessage = "Registration failed: no user returned.");
      }

    } on FirebaseAuthException catch (e) {
      String message;
      // Provide user-friendly error messages based on Firebase codes
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else {
        message = "Registration failed: ${e.message}";
      }
      setState(() => _errorMessage = message);

    } catch (e) {
      setState(() => _errorMessage = "Something went wrong. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Mov.ly', style: GoogleFonts.lilyScriptOne(fontSize: 28)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  const Icon(Icons.person_add, size: 75),
                  const SizedBox(height: 10),
                  Text("Create Account", style: GoogleFonts.bebasNeue(fontSize: 52)),
                  const Text("Let's get you started", style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 30),

                  // Name Field
                  MyTextField(controller: nameController, hintText: "Name", obscureText: false),
                  const SizedBox(height: 10),

                  // Email Field
                  MyTextField(controller: emailController, hintText: "Email", obscureText: false),
                  const SizedBox(height: 10),

                  // Password Field
                  MyTextField(controller: pwController, hintText: "Password", obscureText: true),
                  const SizedBox(height: 10),

                  // Confirm Password Field
                  MyTextField(controller: confirmPwController, hintText: "Confirm Password", obscureText: true),

                  // Error message display
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Loading Indicator or Sign Up Button
                  _isLoading
                      ? const CircularProgressIndicator()
                      : MyButton(onTap: signUp, text: "Sign Up"),

                  const SizedBox(height: 20),

                  // Link back to Login (calls the toggle function from the parent)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: GoogleFonts.afacad(

                        )),
                      GestureDetector(
                        onTap: widget.onLoginTap,
                        child: Text(
                          'Login now',
                          style: GoogleFonts.afacad(
                            color: Colors.blue, 
                            fontWeight: .bold),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}