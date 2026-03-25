import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../movies/presentation/home/home_page.dart';
import '../../../../movies/presentation/liking_titles.dart';
import '../pages/signup_username_page.dart';
import 'login_or_register.dart'; // Added for profile check

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  // Function to determine the next destination route based on user profile completion
  Future<String> _getDestinationRoute(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final data = userDoc.data();

      // 1. Check if the user has a username (initial setup)
      final bool hasUsername = userDoc.exists && data!.containsKey('username');

      if (!hasUsername) {
        // User is logged in but hasn't set their initial username
        return '/username';
      }
/*
      // 2. Check if the user has completed the main onboarding (e.g., liking titles, setting preferences)
      // This 'is_onboarded' flag must be set to true when the user finishes the /preHome screen.
      final bool isOnboarded = data.containsKey('is_onboarded') && data['is_onboarded'] == true;

      if (!isOnboarded) {
        // User has a username but needs to go through the /preHome flow
        return '/preHome';
      }
*/

      // 3. User is fully setup and can access the main app
      return '/home';

    } catch (e) {
      // Log error and default to a safe start route (like preHome)
      debugPrint('Error checking user profile completeness: $e');
      return '/preHome';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not logged in
        if (!snapshot.hasData) {
          return const LoginOrRegister();
        }

        // Logged in
        final user = snapshot.data!;

        return FutureBuilder<String>(
          future: _getDestinationRoute(user.uid),
          builder: (context, profileSnapshot) {

            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final route = profileSnapshot.data ?? '/home';

            switch (route) {
              case '/username':
                return const SignupUsernamePage();
              case '/preHome':
                return const PreHomePage();
              case '/home':
              default:
                return const HomePage();
            }
          },
        );
      },
    );
  }

}