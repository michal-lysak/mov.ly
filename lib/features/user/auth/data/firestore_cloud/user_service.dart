import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UserService {
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
