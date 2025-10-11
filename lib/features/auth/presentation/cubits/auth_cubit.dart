/*

Cubits - responsible for state management

*/

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:movly/features/auth/presentation/cubits/auth_states.dart';
import 'package:movly/features/auth/domain/repos/auth_repo.dart';
import 'package:movly/features/auth/domain/entities/app_user.dart';

class AuthCubit extends Cubit<AuthState> {
    final AuthRepo authRepo; 
    AppUser? _currentUser;

    AuthCubit({required this.authRepo}) : super(AuthInitial());

    //get curernt user
    AppUser? get currentUser => _currentUser;

    // check if user is autenticated
    void checkAuth() async {
        // loading..
        emit(AuthLoading());

        // get current user
        final AppUser? user = await authRepo.getCurrentUser();

        if (user != null) {
            _currentUser = user;
            emit(Authenticated(user));
        } else {
            emit(Unauthenticated());
        }
    }

    // login with email + pw
    Future<void> login(String email, String pw) async {
        try {
            emit(AuthLoading());
            final user = await authRepo.loginWithEmailPassword(email, pw);

            if (user != null) {
                _currentUser = user;
                emit(Authenticated(user));
            } else {
                emit(Unauthenticated());
            } 
        } catch (e) {
            emit(AuthError(e.toString()));
            emit(Unauthenticated());
        }
    }

// Register with email + pw
Future<void> register(String name, String email, String pw) async {
    try {
        emit(AuthLoading());
        final user = await authRepo.registerWithEmailPassword(name, email, pw);

        if (user != null) {
            _currentUser = user;
            emit(Authenticated(user));
        } else {
            emit(Unauthenticated());
        }
    } catch (e) {
        emit(AuthError(e.toString()));
        emit(Unauthenticated());
    }
}

// Logout
Future<void> logout() async {
        emit(AuthLoading());
        await authRepo.logout();
        emit(Unauthenticated());
}

// Forgot pw
Future<String> forgotPassword(String email) async {
    try {
        final message = await authRepo.sendPasswordResetEmail(email);
        return message;
    } catch (e) {
        return e.toString();
    }
}

// Delete Account
Future<void> deleteAccount() async {
    try {
        emit(AuthLoading());
        await authRepo.deleteAccount();
        emit(Unauthenticated());
    } catch (e) {
        emit(AuthError(e.toString()));
        emit(Unauthenticated());
    }
}
// Google sign in
  Future<void> signInWithGoogle() async {
    try {
      emit(AuthLoading());
      final user = await authRepo.signInWithGoogle();

      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }
}