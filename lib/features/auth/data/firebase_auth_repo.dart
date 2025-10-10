/*


FIREBASE IS OUR BACKEND - can swipe out any backend here...

*/

import 'package:movly/features/auth/domain/entities/app_user.dart';
import 'package:movly/features/auth/domain/repos/auth_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthRepo implements AuthRepo {

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  // DELETE ACCOUNT
  @override
  Future<void> deleteAccount() async {
    try {
    // get current user
    final user = firebaseAuth.currentUser;

    // check if there is a logged in user
    if (user == null) throw Exception('No user logged in.');

  await logout();
  } catch (e) {
    throw Exception('failed to delete account: $e');
  }
  }
  
  //REGISTER: Email & Password
  @override
  Future<AppUser?> registerWithEmailPassword(
      String name, String email, String password) async {
    try {
      // attempt sign up
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

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
  
  // LOGIN: Email & Password
  @override
  Future<AppUser?> loginWithEmailPassword(String email, String password) async {
    try {
      // attempt sign in
      UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      // create user
      AppUser user = AppUser(
        uid: userCredential.user!.uid,
        email: email,
      );

      // return user
      return user;
    }

    // catch any errors...
    catch (e) {
      throw Exception('Login failed: $e');
    }
  }
  
  //GET CURRENT USER
  @override
  Future<AppUser?> getCurrentUser() async {
    // get current logged in user from firebase
    final firebaseUser = firebaseAuth.currentUser;

    // no logged in user
    if(firebaseUser == null) return null;

    // logged in user exists
    return AppUser(uid: firebaseUser.uid, email: firebaseUser.email!);
  }
  
  // LOGOUT
  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }
  
  // RESET PASSWORD
  @override
  Future<String> sendPasswordResetEmail(String email) async {
     try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
      return "Password reset email! Check your inbox.";
     } catch (e) {
      return "An error occured: $e";
     }
  }
}