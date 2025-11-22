import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalFavorites {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Toggle favorite for the currently logged-in user.
  /// Returns `true` if the movie is now favorited, `false` if unfavorited.
  Future<bool?> toggleFavorite(int movieId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    final docRef = _firestore.collection('users').doc(userId).collection('favorites').doc('$movieId');

    try {
      final doc = await docRef.get();
      if (doc.exists) {
        // Movie is already favorited → remove
        await docRef.delete();
        return false;
      } else {
        // Movie not favorited → add
        await docRef.set({'movieId': movieId, 'favoritedAt': FieldValue.serverTimestamp()});
        return true;
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      return null;
    }
  }

  /// Check if the current user has favorited a specific movie.
  /// Returns `true` if favorited, `false` if not, `null` on error.
  Future<bool?> isFavorite(int movieId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    try {
      final doc = await _firestore.collection('users')
          .doc(userId)
          .collection('favorites')
          .doc('$movieId')
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking favorite: $e');
      return null;
    }
  }
}
