import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../movies/data/services/tmdb_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _usersCollection =
  FirebaseFirestore.instance.collection('users');
  final CollectionReference _usernamesCollection =
  FirebaseFirestore.instance.collection('usernames');

  late Box followingBox;

  StreamSubscription<QuerySnapshot>? _followingSub;

  UserService() {
    if (Hive.isBoxOpen('followingBox')) {
      followingBox = Hive.box('followingBox');
    }
  }

  Future<void> initHive() async {
    if (!Hive.isBoxOpen('followingBox')) {
      followingBox = await Hive.openBox('followingBox');
    } else {
      followingBox = Hive.box('followingBox');
    }
  }






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

  Future<void> followUser(String theirUsername, String myUsername, String theirUserId) async {
    final currentUserDoc = _usernamesCollection.doc(myUsername);
    final currentUser = await currentUserDoc.get();

    try {
      // Add to their followers
      final theirFollowerDoc = _firestore
          .collection('usernames')
          .doc(theirUsername)
          .collection('followers')
          .doc(currentUser['uid']);

      await theirFollowerDoc.set({
        'username': myUsername, // store your username in their followers
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Add to my following
      final myFollowingDoc = _firestore
          .collection('usernames')
          .doc(myUsername)
          .collection('following')
          .doc(theirUserId);

      await myFollowingDoc.set({
        'username': theirUsername,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!Hive.isBoxOpen('followingBox')) {
        await Hive.openBox('followingBox');
      }

      // Update local cache
      followingBox.put(theirUserId, theirUsername);

      debugPrint('Follow successful! Cache updated.');
    } catch (e) {
      debugPrint('Error following user: $e');
    }
  }

  Future<void> unfollowUser(String theirUsername, String myUsername, String theirUserId) async {
    // 1. Optimistic Update
    if (Hive.isBoxOpen('followingBox')) {
      followingBox.delete(theirUserId);
    }

    try {
      final currentUserDoc = await _usernamesCollection.doc(myUsername).get();
      final currentUid = currentUserDoc['uid'];

      // 2. Remove from their followers
      await _usernamesCollection.doc(theirUsername).collection('followers').doc(currentUid).delete();

      // 3. Remove from my following
      await _usernamesCollection.doc(myUsername).collection('following').doc(theirUserId).delete();

    } catch (e) {
      debugPrint('Error unfollowing: $e');
      // Revert if failed
      if (Hive.isBoxOpen('followingBox')) {
        followingBox.put(theirUserId, theirUsername);
      }
    }
  }

  Future<void> loadFollowingCache(String myUsername) async {
    final snapshot = await _firestore
        .collection('usernames')
        .doc(myUsername)
        .collection('following')
        .get();

    final Map<String, String> data = {
      for (var doc in snapshot.docs) doc.id: doc['username'] as String,
    };

    await followingBox.putAll(data);
    debugPrint('Following cache loaded: ${data.length} users');
  }

  bool isFollowing(String userId) {
    if (!Hive.isBoxOpen('followingBox')) return false;
    return followingBox.containsKey(userId);
  }


  /*bool isFollower(String userId) {
    return followersBox.containsKey(userId);
  }
*/


  void listenToFollowingChanges(String myUsername) {
    _followingSub?.cancel();

    _followingSub = _firestore
        .collection('usernames')
        .doc(myUsername)
        .collection('following')
        .snapshots()
        .listen((snapshot) async {

      if (!Hive.isBoxOpen('followingBox')) {
        await Hive.openBox('followingBox');
      }
      final box = Hive.box('followingBox');

      // 1. RECONCILIATION (Cleanup "Zombie" records)
      // Get all IDs currently on the server
      final serverIds = snapshot.docs.map((doc) => doc.id).toSet();
      // Get all IDs currently in Hive
      final cachedIds = box.keys.cast<String>().toSet();

      // Find IDs that are in Hive but NOT on the server anymore
      final zombies = cachedIds.difference(serverIds);
      for (var id in zombies) {
        box.delete(id);
      }

      // 2. REAL-TIME UPDATES
      for (final change in snapshot.docChanges) {
        final userId = change.doc.id;
        final data = change.doc.data();

        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            if (data != null) {
              box.put(userId, data['username']);
            }
            break;
          case DocumentChangeType.removed:
            box.delete(userId);
            break;
        }
      }
    });
  }


}