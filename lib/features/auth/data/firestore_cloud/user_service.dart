import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../movies/data/services/tmdb_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../social/data/models/followed_user.dart';

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
    // 1. Get current user ID (using the actual UID from Auth is safer)
    final String myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (myUid.isEmpty) {
      debugPrint('User not logged in');
      return;
    }

    // Ensure case-consistency for Document IDs
    final String myDocPath = myUsername.toLowerCase();
    final String theirDocPath = theirUsername.toLowerCase();

    try {
      // --- FIRESTORE TRANSACTION: Update both parties ---

      // A. Add YOU to THEIR 'followers' sub-collection
      final theirFollowerDoc = _firestore
          .collection('usernames')
          .doc(theirDocPath)
          .collection('followers')
          .doc(myUid);

      // B. Add THEM to YOUR 'following' sub-collection
      final myFollowingDoc = _firestore
          .collection('usernames')
          .doc(myDocPath)
          .collection('following')
          .doc(theirUserId);

      // Execute both Firestore writes
      await Future.wait([
        theirFollowerDoc.set({
          'username': myUsername,
          'timestamp': FieldValue.serverTimestamp(),
        }),
        myFollowingDoc.set({
          'username': theirUsername,
          'timestamp': FieldValue.serverTimestamp(),
        }),
      ]);

      // --- CACHE HYDRATION: Update your local Hive box ---

      if (!Hive.isBoxOpen('followingBox')) {
        await Hive.openBox('followingBox');
      }

      // Fetch their profile and movies in parallel to update Hive immediately
      final results = await Future.wait([
        _usernamesCollection.doc(theirDocPath).get(),
        _firestore.collection('favoritesperuser').doc(theirUserId).get(),
      ]);

      final targetUserDoc = results[0];
      final favsDoc = results[1];

      final targetData = targetUserDoc.data() as Map<String, dynamic>?;

      // Extract the favorites array (the 1-read strategy)
      final List<dynamic> favMoviesList = (favsDoc.exists)
          ? (favsDoc.data() as Map<String, dynamic>)['favorites'] ?? []
          : [];

      // Save the full package to Hive
      // This ensures your ValueListenableBuilder in SocialTab updates instantly
      await followingBox.put(theirUserId, {
        'username': theirUsername,
        'photoUrl': targetData?['photoUrl'] ?? '',
        'name': targetData?['name'] ?? theirUsername,
        'favMovies': favMoviesList,
      });

      debugPrint('Follow successful: Both Firestore and Hive updated.');
    } catch (e) {
      debugPrint('Error during follow process: $e');
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

      // 1. RECONCILIATION: Cleanup local cache
      final serverIds = snapshot.docs.map((doc) => doc.id).toSet();
      final cachedIds = box.keys.cast<String>().toSet();
      final zombies = cachedIds.difference(serverIds);
      for (var id in zombies) {
        box.delete(id);
      }

      // 2. FETCH & CACHE
      for (final change in snapshot.docChanges) {
        final theirUid = change.doc.id;
        final followData = change.doc.data() as Map<String, dynamic>?;

        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          if (followData != null) {
            final String username = followData['username'];

            // READ 1: Get Profile Info (Name, PFP)
            final userDoc = await _firestore.collection('usernames').doc(username).get();

            // READ 2: Get the single document containing the movie array
            final favsDoc = await _firestore.collection('favoritesperuser').doc(theirUid).get();

            if (userDoc.exists) {
              final userData = userDoc.data()!;

              // Extract the 'favorites' array from the second read
              final List<dynamic> favMoviesList = (favsDoc.exists)
                  ? (favsDoc.data()?['favorites'] ?? [])
                  : [];

              // SAVE EVERYTHING TO HIVE
              box.put(theirUid, {
                'username': username,
                'photoUrl': userData['photoUrl'] ?? '',
                'name': userData['name'] ?? username,
                'favMovies': favMoviesList, // Full array stored locally
              });
            }
          }
        } else if (change.type == DocumentChangeType.removed) {
          box.delete(theirUid);
        }
      }
    });
  }

  List<FollowedUser> getFollowingListFromCache() {
    final box = Hive.box('followingBox');

    return box.keys.map((uid) {
      final data = box.get(uid);

      if (data is Map) {
        return FollowedUser.fromHive(uid.toString(), data);
      }
      return null;
    }).whereType<FollowedUser>().toList();
  }



}