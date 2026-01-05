import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show a loading circle while checking the auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // User is NOT logged in
          if (!snapshot.hasData) {
            return const LoginOrRegister();
          }

          // User IS logged in (has data)
          final user = snapshot.data!;

          // Use FutureBuilder to wait for the profile completion check
          return FutureBuilder<String>(
            future: _getDestinationRoute(user.uid),
            builder: (context, profileSnapshot) {

              // Show loading while checking profile status
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // The check is complete. Use the determined route.
              final String nextRoute = profileSnapshot.data ?? '/preHome'; // Default to /home if null

              // Perform navigation after the frame is built
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Navigate to the determined destination: /username, /preHome, or /home
                Navigator.of(context).pushReplacementNamed(nextRoute);
              });

              // Return a blank container while navigation occurs
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}