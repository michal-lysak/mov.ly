import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/favorite_movie_model.dart';
import 'favmovie_service.dart';
import 'favorite_service.dart';

class ForYouPageService {
  final _db = FirebaseFirestore.instance;
  final _favMovieService = FavMovieService();
  final _favoriteService = FavoriteService();

  /// Update recommendations for a user
  Future<void> updateRecommendations(String userId, List<FavoriteMovieRef> recommendedMovies) async {
    final docRef = _db.collection('foryoupage').doc(userId);

    await docRef.set({
      'lastUpdated': FieldValue.serverTimestamp(),
      'recommendedMovies': recommendedMovies.map((f) => f.toMap()).toList(),
    }, SetOptions(merge: true));
  }

  /// Get recommendations for a user
  Future<List<FavoriteMovieRef>> getRecommendations(String userId) async {
    final doc = await _db.collection('foryoupage').doc(userId).get();
    if (!doc.exists) return [];

    final movies = (doc.data()?['recommendedMovies'] as List<dynamic>? ?? []);
    return movies.map((e) => FavoriteMovieRef.fromMap(e)).toList();
  }

  /// Generate recommendations based on user favorites and global movie likes
  Future<List<FavoriteMovieRef>> generateRecommendations(String userId, {int limit = 10}) async {
    // Get user favorites
    final profile = await _favoriteService.getFavorites(userId);
    if (profile == null) return [];

    final keywordCount = <String, int>{};

    // Count keywords from user's favorites weighted by global likeCount
    for (final fav in profile.favorites) {
      final likeCount = await _favMovieService.getLikeCount(fav.movieId);
      for (final kw in fav.keywords) {
        keywordCount[kw] = (keywordCount[kw] ?? 0) + likeCount;
      }
    }

    // Fetch all movies from /favoritemovies
    final snapshot = await FirebaseFirestore.instance.collection('favoritemovies').get();
    final movies = snapshot.docs.map((doc) {
      final data = doc.data();
      final id = int.parse(doc.id);
      final keywords = List<String>.from(data['keywords'] ?? []);
      final likeCount = data['likeCount'] ?? 0;

      // Calculate a simple score based on shared keywords
      int score = 0;
      for (final kw in keywords) {
        score += keywordCount[kw] ?? 0;
      }

      return FavoriteMovieRef(
        movieId: id,
        keywords: keywords,
        favoritedAt: DateTime.now(), // just for structure
      )..score = score;
    }).toList();

    // Sort by score descending
    movies.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));

    return movies.take(limit).toList();
  }
}
