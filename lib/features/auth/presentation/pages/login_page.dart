import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movly/features/auth/data/firebase_auth_repo.dart';
import 'package:movly/features/auth/presentation/components/google_sign_in_button.dart';
import 'package:movly/features/auth/presentation/components/my_button.dart';
import 'package:movly/features/auth/presentation/components/my_textfield.dart';
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
      _errorMessage = "Email and password cannot be empty.";
    });
    return;
  }

  try {
    final user = await _authRepo.loginWithEmailPassword(email, pw);

  if (user != null) {
    // Login succeeded, user object is available
    Navigator.pushReplacementNamed(context, '/preHome');
  } else {
    // Login returned null (unexpected, but possible depending on your repo)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Login failed: no user returned.")),
    );
  }

  } on FirebaseAuthException catch (e) {
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
        if (user.username != null && user.username!.isNotEmpty) {
          // If username exists, go straight to home
          Navigator.pushReplacementNamed(context, '/preHome');
        } else {
          // Otherwise, ask user to create a username
          Navigator.pushReplacementNamed(context, '/username');
        }
      } else {
        setState(() => _errorMessage = "Google Sign-In cancelled.");
      }
    } catch (e) {
      setState(() => _errorMessage = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }


  // forgot password box
void openForgotPassword() {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text("Forgot Password"),
      content: MyTextField(
          controller: emailController,
          hintText: "Enter email..",
          obscureText: false
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(
            "Cancel",
            style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary),
          ),
        ),
        TextButton(
          onPressed: () async {
            final message = await _authRepo.sendPasswordResetEmail(emailController.text.trim());

            if (message.isNotEmpty) {
              setState(() => _errorMessage = message);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Password reset email sent."),
                ),
              );
            }
            Navigator.pop(dialogContext);
          },
          child: const Text(
              "Reset Password",
              style: TextStyle(
                  color: Colors.black,
          )
          ),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Mov.ly',
          style: GoogleFonts.lilyScriptOne(
            fontSize: 28,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                  mainAxisAlignment: .center,
          
                children: [
                  const SizedBox(height: 40),

                  Icon(
                    Icons.login,
                    size: 75,
                  ),

                  SizedBox(height: 10),

                  Text(
                    "Welcome",
                    style: GoogleFonts.bebasNeue(
                      fontSize: 52,
                      //fontWeight: .w600
                    ),
                    textAlign: TextAlign.center,
                  ),
          
                  Text(
                    "You need to sign in",
                    style: TextStyle(
                      fontSize: 20,
                      //fontWeight: .w600
                    ),
                    textAlign: TextAlign.center,
                  ),
          
          
                  const SizedBox(height: 30),
          
                 _isLoading
                    ?
                        const CircularProgressIndicator()
                  : Column(
                    children: [
          
                    // email textfield
                    MyTextField(
                      controller: emailController,
                      hintText: "Email",
                      obscureText: false,
                    ),
          
                    const SizedBox(height: 10),
          
                    //pw textfield
                    MyTextField(
                      controller: pwController,
                      hintText: "Password",
                      obscureText: true,
                    ),
          
                    //const SizedBox(height: 5),
          
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                      GestureDetector(
                         onTap: () => openForgotPassword(),
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                            //decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],),
          
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
                      Row(
                          mainAxisAlignment: .center,
                          children: [
                            Text(
                                'Not signed in? '
                            ),
          
                            GestureDetector(
                              child: Text(
                                'Register now',
                                style: TextStyle(
                                    color: Colors.blue
                                ),
                              ),
                            )
                          ]
                      ),
                    
                    SizedBox(height: 30),
                    MyGoogleSignInButton(onTap: _signInWithGoogle),
          
                      //SizedBox(height: 20),
          
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
