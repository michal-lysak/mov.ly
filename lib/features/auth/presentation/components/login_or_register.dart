import 'package:flutter/material.dart';
import 'package:movly/features/auth/presentation/pages/login_page.dart';
import 'package:movly/features/auth/presentation/pages/signup_tab.dart'; // Make sure this import path is correct

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  // This checks the "Index": 0 = Login, 1 = Signup
  int _currentIndex = 0;

  // Toggle to Index 1 (Signup)
  void toggleToRegister() {
    setState(() {
      _currentIndex = 1;
    });
  }

  // Toggle to Index 0 (Login)
  void toggleToLogin() {
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == 0) {
      // Pass the function to switch to register
      return LoginPage(onRegisterTap: toggleToRegister);
    } else {
      // Pass the function to switch back to login
      return SignupPage(onLoginTap: toggleToLogin);
    }
  }
}