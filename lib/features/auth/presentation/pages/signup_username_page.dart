import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movly/features/auth/data/firestore_cloud/user_service.dart';
import '../components/my_textfield.dart';

class SignupUsernamePage extends StatefulWidget {
  const SignupUsernamePage({super.key});

  @override
  State<SignupUsernamePage> createState() => _SignupUsernamePageState();
}

class _SignupUsernamePageState extends State<SignupUsernamePage> {
  final UserService userService = UserService();
  String? errorMessage;

  // Text editing controller
  final usernameController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // centers content vertically
            children: [
              Text(
                'Create your unique username',
                style: GoogleFonts.afacad(
                    fontWeight: FontWeight.bold,
                    fontSize: 24),
              ),

              const SizedBox(height: 20),

              MyTextField(
                controller: usernameController,
                hintText: 'Username',
                obscureText: false,
              ),

              const SizedBox(height: 20),

              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: const GoogleFonts.afacad(color: Colors.red),
                ),

              GestureDetector(
                onTap: () async {
                  final firebaseUser = FirebaseAuth.instance.currentUser;
                  if (firebaseUser == null) return;

                  try {
                    // Check if the username is empty first
                    if (usernameController.text.trim().isEmpty) {
                      setState(() {
                        errorMessage = 'Username cannot be empty.';
                      });
                      return;
                    }

                    // Attempt to set the username in Firestore
                    await userService.setUsername(
                      firebaseUser.uid,
                      usernameController.text.trim(),
                    );

                    // ✅ Username set successfully
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/preHome', (route) => false);
                    }

                  } catch (e) {
                    // show error under the textfield
                    setState(() {
                      errorMessage = e.toString().replaceFirst('Exception: ', 'Error: ');
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: Center(
                    child: Text(
                      'Continue',
                      textAlign: .center,
                      style: GoogleFonts.afacad(
                          fontWeight: FontWeight.bold,
                          fontSize: 24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}