import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/entities/app_user.dart';
import '../domain/repos/auth_repo.dart';
import 'firestore_cloud/user_service.dart';

class FirebaseAuthRepo implements AuthRepo {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // LOGIN: Email & Password
  @override
  Future<AppUser?> loginWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);

      final doc = await _userService.getUser(userCredential.user!.uid);
      final data = doc?.data() as Map<String, dynamic>?;

      return AppUser(
        uid: userCredential.user!.uid,
        email: email,
        username: data?['username'], // nullable
        name: data?['name'],
      );
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // REGISTER: Email & Password
  @override
  Future<AppUser?> registerWithEmailPassword(String name, String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);

      await _userService.createUser(
        userCredential.user!.uid,
        email: email,
        name: name,
        // username will be null initially
      );

      return AppUser(
        uid: userCredential.user!.uid,
        email: email,
        username: null,
        name: name,
      );
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // GOOGLE SIGN IN
  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      final gUser = await GoogleSignIn().signIn();
      if (gUser == null) return null;

      final gAuth = await gUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _userService.createUser(
          firebaseUser.uid,
          email: firebaseUser.email ?? '',
        );
        return AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          username: null,
          name: null,
        );
      } else {
        final doc = await _userService.getUser(firebaseUser.uid);
        final data = doc?.data() as Map<String, dynamic>?;

        return AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          username: data?['username'], // null if not set
          name: data?['name'],
        );
      }
    } catch (e) {
      debugPrint("Google Sign-In error: $e");
      return null;
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    final doc = await _userService.getUser(firebaseUser.uid);
    final data = doc?.data() as Map<String, dynamic>?;

    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      username: data?['username'],
      name: data?['name'],
    );
  }

  @override
  Future<void> logout() async => _firebaseAuth.signOut();

  @override
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No user logged in.');
    await user.delete();
    await logout();
  }

  @override
  Future<String> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return "Password reset email sent!";
    } catch (e) {
      return "An error occurred: $e";
    }
  }
}
