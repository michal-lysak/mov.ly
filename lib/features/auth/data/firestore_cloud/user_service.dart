import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
    String? photoUrl
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
          'name': name,
          'photoUrl': photoUrl,
        });
      }

      await _usersCollection.doc(userId).set(data);
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  Future<void> setUsername(String userId, String username, String? photoUrl) async {
    try {
      final currentUserDoc = _usersCollection.doc(userId);
      final currentUser = await currentUserDoc.get();

      // 1. Update/Create User Document
      if (!currentUser.exists) {
        await currentUserDoc.set({
          'uid': userId,
          'username': username,
          'photoUrl': photoUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await currentUserDoc.update({
          'username': username,
          'photoUrl': photoUrl,
        });
      }

      // 2. Cleanup old username mapping if user changed it
      final currentData = currentUser.data() as Map<String, dynamic>?;
      if (currentData != null && currentData.containsKey('username')) {
        final oldUsername = currentData['username'] as String;
        if (oldUsername.toLowerCase() != username.toLowerCase()) {
          await _usernamesCollection.doc(oldUsername.toLowerCase()).delete();
        }
      }

      // 3. Set global username index (used for search and availability)
      await _usernamesCollection.doc(username.toLowerCase()).set({
        'uid': userId,
        'username': username,
        'name': currentData?['name'],
        'photoUrl': photoUrl, // Important for showing search result images
      });
    } catch (e) {
      throw Exception("Failed to set username: $e");
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
        'photoUrl': data['photoUrl'] ?? '',
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
        'photoUrl': data['photoUrl'] ?? '',
      };
    } catch (e) {
      debugPrint('Error fetching profile by username: $e');
      return null;
    }
  }
}