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
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        };
        if (username != null) {
          data['username'] = username;
          await _usernamesCollection.doc(username.toLowerCase()).set({
            'uid': userId,
            'username': username,
            'name': name
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
        
        final String? name = currentData?['name'];

        // Remove old username if exists
        if (currentData != null && currentData.containsKey('username')) {
          final oldUsername = currentData['username'] as String;
          await _usernamesCollection.doc(oldUsername.toLowerCase()).delete();
        }

        // Add new username
        await _usernamesCollection.doc(username.toLowerCase()).set({
          'uid': userId,
          'username': username,
          'name': name
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

    /// Search users by username prefix
    Future<List<Map<String, dynamic>>> searchUsers(String query) async {
      if (query.isEmpty) return [];

      final snap = await _firestore
          .collection('usernames')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();

      return snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'name': data['name'],
          'username': data['username'],
          'uid': data['uid'],
        };
      }).toList();
    }

    /// Get full profile by username
    Future<Map<String, dynamic>?> getUserProfileByUsername(
        String username) async {
      try {
        final doc = await _firestore
            .collection('usernames')
            .doc(username)
            .get();

        if (!doc.exists) return null;

        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return null;

        // Return all three fields + ensure UID is included
        return {
          'name': data['name'],
          'username': data['username'],
          'uid': data['uid'],
        };
      } catch (e) {
        debugPrint('Error fetching profile by username: $e');
        return null;
      }
    }
  }
