import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../movies/data/models/movie.dart';
import '../firebase_auth_repo.dart';

class UserService {
  UserService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _users =
  FirebaseFirestore.instance.collection('users');
  final CollectionReference _usernames =
  FirebaseFirestore.instance.collection('usernames');

  // Hive box for caching following users
  late Box _followingBox;

  // ================= Hive Init =================
  Future<void> initHive() async {
    _followingBox = await Hive.openBox('followingBox');
  }

  Box get followingBox => _followingBox;

  // ================= Firestore =================
  Future<void> createUser(
      String userId, {
        required String email,
        String? username,
        String? name,
        String? photoUrl,
      }) async {
    final data = {
      'email': email,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (username != null) {
      data['username'] = username;
      await _usernames.doc(username.toLowerCase()).set({
        'uid': userId,
        'username': username,
        'name': name,
        'photoUrl': photoUrl,
      });
    }

    await _users.doc(userId).set(data);
  }

  Future<void> logOut() async {
    await clearLocalCache();
    debugPrint("CACHE: cache cleared");
    await FirebaseAuth.instance.signOut();
    debugPrint("AUTH: logged out");
  }

  Future<void> deleteAccount(String userId) async {
    try {
      final _db = FirebaseFirestore.instance;

      // 1️⃣ Delete favorites document
      await _db.collection('favoritesperperson').doc(userId).delete();

      // 2️⃣ Delete 'foryoupagelist' subcollection under 'users/userId'
      final forYouSnap = await _db
          .collection('users')
          .doc(userId)
          .collection('foryoupagelist')
          .get();

      for (var doc in forYouSnap.docs) {
        await doc.reference.delete();
      }

      // 3️⃣ Get user document to retrieve username
      final userDoc = await _users.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final username = userData?['username'];

      // 4️⃣ Delete subcollections under 'usernames/username'
      if (username != null) {
        final usernameRef = _usernames.doc(username.toLowerCase());

        // Delete following
        final followingsSnap = await usernameRef.collection('following').get();
        for (var doc in followingsSnap.docs) {
          await doc.reference.delete();
        }

        // Delete followers
        final followersSnap = await usernameRef.collection('followers').get();
        for (var doc in followersSnap.docs) {
          await doc.reference.delete();
        }

        // Delete username doc itself
        await usernameRef.delete();
      }

      // 5️⃣ Delete user document
      await _users.doc(userId).delete();

      // 6️⃣ Clear local Hive cache
     await clearLocalCache();

      // 7️⃣ Delete Firebase Auth user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await user.delete();
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            debugPrint('Firebase requires recent login before deleting account.');
          } else {
            rethrow;
          }
        }
      } else {
        // 🔹 ADDED: handle case where no user is signed in
        debugPrint('No Firebase user currently signed in; skipping Firebase delete.');
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  Future<void> clearLocalCache() async {
    try {
      // Access already opened boxes
      final moviesBox = Hive.box<Movie>('movies');
      final sectionsBox = Hive.box('sections');
      final followingBox = Hive.box('followingBox');

      // Clear them
      await moviesBox.clear();
      await sectionsBox.clear();
      await followingBox.clear();

      debugPrint('IMPORTANT CACHE: Local cache cleared successfully.');
    } catch (e) {
      debugPrint('IMPORTANT CACHE: Error clearing local cache: $e');
    }
  }




  Future<void> setUsername(String userId, String username, String? photoUrl) async {
    final doc = _users.doc(userId);
    final snap = await doc.get();
    final oldData = snap.data() as Map<String, dynamic>?;

    if (snap.exists) {
      await doc.update({
        'username': username,
        'photoUrl': photoUrl,
      });
    } else {
      await doc.set({
        'uid': userId,
        'username': username,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (oldData?['username'] != null &&
        oldData!['username'].toLowerCase() != username.toLowerCase()) {
      await _usernames.doc(oldData['username'].toLowerCase()).delete();
    }

    await _usernames.doc(username.toLowerCase()).set({
      'uid': userId,
      'username': username,
      'name': oldData?['name'],
      'photoUrl': photoUrl,
    });
  }

  Future<bool> isUsernameAvailable(String username) async {
    final doc = await _usernames.doc(username.toLowerCase()).get();
    return !doc.exists;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) return doc;
      return null;
    } catch (e) {
      debugPrint('Error fetching user $uid: $e');
      return null;
    }
  }
}
