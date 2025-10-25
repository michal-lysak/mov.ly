import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  /// Creates a new user document in Firestore.
  Future<void> createUser(String userId, {required String email/*, String? displayName*/}) async {
    try {
      await _usersCollection.doc(userId).set({
        'email': email,
        //'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  /// Retrieves a user document from Firestore.
  Future<DocumentSnapshot?> getUser(String userId) async {
    try {
      final snapshot = await _usersCollection.doc(userId).get();
      return snapshot;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  /// Updates a user's data in Firestore.
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(userId).update(data);
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }
}
