import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _usersCollection =
  FirebaseFirestore.instance.collection('users');
  final CollectionReference _usernamesCollection =
  FirebaseFirestore.instance.collection('usernames');

  /// Creates a new user document WITHOUT username
  Future<void> createUser(
      String userId, {
        required String email,
        String? username,
        String? name,
      }) async {
    try {
      final data = {
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (username != null) {
        data['username'] = username;
        await _usernamesCollection.doc(username.toLowerCase()).set({'uid': userId});
      }

      await _usersCollection.doc(userId).set(data);
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  /// Sets or updates the username AFTER registration
  Future<void> setUsername(String userId, String username) async {
    try {
      final currentUserDoc = _usersCollection.doc(userId);
      final currentUser = await currentUserDoc.get();

// If user doc doesn't exist, create it
      if (!currentUser.exists) {
        await currentUserDoc.set({'createdAt': FieldValue.serverTimestamp()});
      }

      final currentData = currentUser.data() as Map<String, dynamic>?;

// Remove old username if exists
      if (currentData != null && currentData.containsKey('username')) {
        final oldUsername = currentData['username'] as String;
        await _usernamesCollection.doc(oldUsername.toLowerCase()).delete();
      }

// Add new username
      await _usernamesCollection.doc(username.toLowerCase()).set({'uid': userId});

// Update user
      await currentUserDoc.set(
        {'username': username},
        SetOptions(merge: true),
      );

    } catch (e) {
      debugPrint('Error setting username: $e');
      rethrow;
    }
    }


  /// Checks if a username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final doc = await _usernamesCollection.doc(username.toLowerCase()).get();
      return !doc.exists;
    } catch (e) {
      debugPrint('Error checking username: $e');
      return false;
    }
  }

  /// Retrieves a user document
  Future<DocumentSnapshot?> getUser(String userId) async {
    try {
      return await _usersCollection.doc(userId).get();
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }
}
