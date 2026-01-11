import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../cache/social_cache.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Follow a user: Updates both the target's 'followers' and your 'following'
  Future<void> follow({
    required String myUid,
    required String myUsername,
    required String theirUid,
    required String theirUsername,
  }) async {
    await Future.wait([
      _firestore
          .collection('usernames')
          .doc(theirUsername.toLowerCase())
          .collection('followers')
          .doc(myUid)
          .set({
        'username': myUsername,
        'timestamp': FieldValue.serverTimestamp(),
      }),
      _firestore
          .collection('usernames')
          .doc(myUsername.toLowerCase())
          .collection('following')
          .doc(theirUid)
          .set({
        'username': theirUsername,
        'timestamp': FieldValue.serverTimestamp(),
      }),
    ]);
  }

  /// Unfollow a user: Deletes records from both collections
  Future<void> unfollow({
    required String myUid,
    required String myUsername,
    required String theirUid,
    required String theirUsername,
  }) async {
    await Future.wait([
      _firestore
          .collection('usernames')
          .doc(theirUsername.toLowerCase())
          .collection('followers')
          .doc(myUid)
          .delete(),
      _firestore
          .collection('usernames')
          .doc(myUsername.toLowerCase())
          .collection('following')
          .doc(theirUid)
          .delete(),
    ]);
  }

  /// Listen to real-time changes in the following list
  void listenToFollowing({
    required String myUsername,
    required SocialCache cache,
  }) {
    _firestore
        .collection('usernames')
        .doc(myUsername.toLowerCase())
        .collection('following')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final uid = change.doc.id;
        final data = change.doc.data();
        if (data == null) continue;

        final username = data['username'] ?? '';

        if (change.type == DocumentChangeType.added) {
          // Fetch the main user document to get the pfp with safety checks
          _firestore.collection('users').doc(uid).get().then((userDoc) {
            final userData = userDoc.data();

            // Safety Check: Look for common field variations
            final String pfp = userData?['photoUrl'] ??
                userData?['photoURL'] ??
                userData?['profilePicture'] ??
                '';

            final String name = userData?['displayName'] ?? username;

            cache.addFollowedUser(uid, username, name: name, photoUrl: pfp);
          });
        } else if (change.type == DocumentChangeType.removed) {
          cache.removeFollowedUser(uid);
        }
      }
    });
  }

  /// ✅ Fetch following list using ONLY the 'usernames' collection
  Future<List<Map<String, dynamic>>> fetchInitialFollowing(String myUsername) async {
    // 1. Get the list of usernames you follow
    final snapshot = await _firestore
        .collection('usernames')
        .doc(myUsername.toLowerCase())
        .collection('following')
        .get();

    final List<Map<String, dynamic>> followedUsersWithData = [];

    for (var doc in snapshot.docs) {
      // In this structure, the doc.id is likely the UID,
      // but we need the 'username' string to find their profile doc.
      final followingData = doc.data();
      final String targetUsername = followingData['username'] ?? '';
      final String uid = doc.id;

      if (targetUsername.isEmpty) continue;

      try {
        // 2. Fetch the profile directly from the top-level usernames collection
        final userProfileDoc = await _firestore
            .collection('usernames')
            .doc(targetUsername.toLowerCase())
            .get();

        if (!userProfileDoc.exists) {
          debugPrint("⚠️ WARNING: Profile for '$targetUsername' not found in /usernames/");
          // Add fallback data so the UI doesn't break
          followedUsersWithData.add({
            'uid': uid,
            'username': targetUsername,
            'displayName': targetUsername,
            'photoUrl': '',
          });
          continue;
        }

        final profileData = userProfileDoc.data()!;

        // CHECK: Flexible field naming for the profile picture
        final String pfp = profileData['photoUrl'] ??
            profileData['photoURL'] ??
            profileData['profilePicture'] ??
            '';

        followedUsersWithData.add({
          'uid': uid, // Kept for backend operations (likes, follows)
          'username': targetUsername,
          'displayName': profileData['displayName'] ?? targetUsername,
          'photoUrl': pfp,
          'favMovieIds': profileData['favMovieIds'] ?? [],
        });

      } catch (e) {
        debugPrint("❌ ERROR fetching profile for $targetUsername: $e");
      }
    }

    return followedUsersWithData;
  }
}