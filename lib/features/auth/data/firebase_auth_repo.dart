/*


FIREBASE IS OUR BACKEND - can swipe out any backend here...

*/

import 'package:movly/features/auth/domain/entities/app_user.dart';
import 'package:movly/features/auth/domain/repos/auth_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthRepo implements AuthRepo {

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  // LOGIN: Email & Password
  @override
  Future<AppUser?> loginWithEmailPassword(String email, String password) {
    try {
      UserCredential userCredential = await firebaseAuth.sign
    }
    catch (e) {

    }
  }

  

  @override
  Future<AppUser?> loginWithEmailPassword(String email, String password) {
    // TODO: implement loginWithEmailPassword
    throw UnimplementedError();
  }

  @override
  Future<AppUser?> registerWithEmailPassword(String name, String email, String password) {
    // TODO: implement registerWithEmailPassword
    throw UnimplementedError();
  }
  
  @override
  Future<void> deleteAccount() {
    // TODO: implement deleteAccount
    throw UnimplementedError();
  }
  
  @override
  Future<AppUser?> getCurrentUser() {
    // TODO: implement getCurrentUser
    throw UnimplementedError();
  }
  
  @override
  Future<void> logout() {
    // TODO: implement logout
    throw UnimplementedError();
  }
  
  @override
  Future<String> sendPasswordResetEmail(String email) {
    // TODO: implement sendPasswordResetEmail
    throw UnimplementedError();
  }

  
}