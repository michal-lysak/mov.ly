  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flutter/foundation.dart';

import '../../../movies/data/models/movie.dart';
import '../../../movies/data/services/tmdb_service.dart';

  class UserService {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final CollectionReference _usersCollection =
    FirebaseFirestore.instance.collection('users');
    final CollectionReference _usernamesCollection =
    FirebaseFirestore.instance.collection('usernames');

    final TMDBService _tmdb = TMDBService();

    /// Creates a new user document
    Future<void> createUser(String userId, {
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
          await _usernamesCollection.doc(username.toLowerCase()).set({
            'uid': userId,
            'username': username,
          });
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
        await _usernamesCollection.doc(username.toLowerCase()).set({
          'uid': userId,
          'username': username,
        });

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
        final doc = await _usernamesCollection
            .doc(username.toLowerCase())
            .get();
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

    /// Search users by username
    Future<List<Map<String, dynamic>>> searchUsers(String query) async {
      if (query.isEmpty) return [];

      final snap = await _firestore
          .collection('usernames')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();

      return snap.docs.map((doc) =>
      {
        ...doc.data(),
        'uid': doc.id,
      }).toList();
    }

    /// Fetch full user profile after clicking
    Future<Map<String, dynamic>?> getUserProfile(String uid) async {
      try {
        debugPrint("profile: $uid");
        // 1. Direct Target: Go straight to the document using the ID
        final doc = await _usernamesCollection.doc(uid).get();

        // 2. Check Existence
        if (!doc.exists) return null;

        // 3. Extract Data
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return null;

        // 4. Return merged data
        return {...data, 'uid': uid};
      } catch (e) {
        debugPrint('Error fetching profile: $e');
        return null;
      }
    }
  }