/*

FIREBASE IS OUR BACKEND - You can swap out any backend here..

*/

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:movly/features/auth/data/firestore_cloud/user_service.dart';
import '../domain/entities/app_user.dart';
import '../domain/repos/auth_repo.dart';
import 'firestore_cloud/user_service.dart';

class FirebaseAuthRepo implements AuthRepo {
  // access to firebase
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // LOGIN: Email & Password
  @override
  Future<AppUser?> loginWithEmailPassword(String email, String password) async {
    try {
      // attempt sign in
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      // create user
      AppUser user = AppUser(
        uid: userCredential.user!.uid,
        email: email,
      );

      return user;
    }

    // catch any errors...
    catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // REGISTER: Email & Password
  @override
  Future<AppUser?> registerWithEmailPassword(
      String name, String email, String password) async {
    try {
      // attempt sign up
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // create user in firestore
      await _userService.createUser(
        userCredential.user!.uid,
        email: email,
        //displayName: name,
      );

      // create user
      AppUser user = AppUser(uid: userCredential.user!.uid, email: email);

      // return user
      return user;
    }

    // any errors..
    catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // DELETE ACCOUNT
  @override
  Future<void> deleteAccount() async {
    try {
      // get current user
      final user = _firebaseAuth.currentUser;

      // check if there is a logged in user
      if (user == null) throw Exception('No user logged in..');

      // delete account
      await user.delete();

      // logout
      await logout();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // GET CURRENT USER
  @override
  Future<AppUser?> getCurrentUser() async {
    // get current logged in user from firebase
    final firebaseUser = _firebaseAuth.currentUser;

    // no logged in user
    if (firebaseUser == null) return null;

    // logged in user exists
    return AppUser(uid: firebaseUser.uid, email: firebaseUser.email!);
  }

  // LOGOUT
  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  // RESET PASSWORD
  @override
  Future<String> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return "Password reset email sent! Check your inbox";
    } catch (e) {
      return "An error occured: $e";
    }
  }

  // GOOGLE SIGN IN
  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      // begin the interactive sign-in process
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      // user cancelled sign-in
      if (gUser == null) return null;

      // obtain auth details from request
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      // create a credential for the user
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      // sign in with these credentials
      UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      // firebase user
      final firebaseUser = userCredential.user;

      // user cancelled sign-in process
      if (firebaseUser == null) return null;

      // if new user, create a new document in firestore
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _userService.createUser(
          firebaseUser.uid,
          email: firebaseUser.email ?? '',
          //displayName: firebaseUser.displayName,
        );
      }

      AppUser appUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
      );

      return appUser;
    } catch (e) {
      print(e);
      return null;
    }
  }
}