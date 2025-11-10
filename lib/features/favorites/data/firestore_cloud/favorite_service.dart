import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../movies/data/services/tmdb_service.dart';

class FavoriteService {
  final _db = FirebaseFirestore.instance;
  final _tmdb = TMDBService();

  /// Ensure movie exists globally with keywords and counter
  Future<void> _ensureMovieExists(int movieId) async {
    final ref = _db.collection('favoritemovies').doc(movieId.toString());
    final snap = await ref.get();

    if (!snap.exists || (snap.data()?['keywords'] == null)) {
      final keywords = await _tmdb.fetchMovieKeywords(movieId);

      await ref.set({
        'keywords': keywords,
        'lastUpdated': FieldValue.serverTimestamp(),
        'favoritesCount': FieldValue.increment(0),
      }, SetOptions(merge: true));
    }
  }

  /// Favorite movie (global + user)
  Future<void> favoriteMovie(String userId, int movieId) async {
    await _ensureMovieExists(movieId);

    // Increment global counter
    await _db.collection('favoritemovies')
        .doc(movieId.toString())
        .update({'favoritesCount': FieldValue.increment(1)});

    // Add movie to user's list (store only ID & timestamp)
    final userRef = _db.collection('favoritesperuser').doc(userId);

    await userRef.set({
      'isPublic': true,
      'favorites': FieldValue.arrayUnion([
        {
          'id': movieId,
          'favoritedAt': DateTime.now().toIso8601String(),
        }
      ])
    }, SetOptions(merge: true));
  }

  /// Unfavorite movie
  Future<void> unfavoriteMovie(String userId, int movieId) async {
    // Remove from user
    final userRef = _db.collection('favoritesperuser').doc(userId);
    final snap = await userRef.get();

    if (snap.exists) {
      final favorites = List<Map>.from(snap.data()?['favorites'] ?? []);
      final updated = favorites.where((item) => item['id'] != movieId).toList();
      await userRef.update({'favorites': updated});
    }

    // Decrement global counter
    await _db.collection('favoritemovies')
        .doc(movieId.toString())
        .update({'favoritesCount': FieldValue.increment(-1)});
  }
}
