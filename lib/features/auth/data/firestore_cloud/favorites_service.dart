import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesService {
  final CollectionReference _favoritesCollection =
      FirebaseFirestore.instance.collection('favorites');

  /// Adds a movie to a user's favorites.
  Future<void> addFavorite(String userId, int movieId) async {
    try {
      await _favoritesCollection.doc(userId).collection('movies').doc(movieId.toString()).set({
        'favoritedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding favorite: $e');
      rethrow;
    }
  }

  // Adds multiple user's favorites in one query
  Future<void> addFavoritesBatch(String userId, List<int> movieIds) async {
    final batch = FirebaseFirestore.instance.batch();
    final userMoviesRef = _favoritesCollection.doc(userId).collection('movies');

    for (final movieId in movieIds) {
      final movieRef = userMoviesRef.doc(movieId.toString());
      batch.set(movieRef, {
        'favoritedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit(); // one atomic query
  }


  /// Removes a movie from a user's favorites.
  Future<void> removeFavorite(String userId, int movieId) async {
    try {
      await _favoritesCollection.doc(userId).collection('movies').doc(movieId.toString()).delete();
    } catch (e) {
      print('Error removing favorite: $e');
      rethrow;
    }
  }

  /// Retrieves all of a user's favorite movies.
  Future<QuerySnapshot> getFavorites(String userId) async {
    try {
      return await _favoritesCollection.doc(userId).collection('movies').get();
    } catch (e) {
      print('Error getting favorites: $e');
      rethrow;
    }
  }
}
