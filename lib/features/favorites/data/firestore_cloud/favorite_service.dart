import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../movies/data/services/tmdb_service.dart';
import '../../model/favorite_movie_model.dart';
import 'favmovie_service.dart';

class FavoriteService {
  final _db = FirebaseFirestore.instance;
  final _favMovieService = FavMovieService();
  final _tmdbService = TMDBService(); // reads API from .env

  /// Add favorite movie to user
  Future<void> addFavoriteMovie(String userId, int movieId) async {
    List<String> keywords = await _getKeywords(movieId);

    final favoriteRef = FavoriteMovieRef(
      movieId: movieId,
      keywords: keywords,
      favoritedAt: DateTime.now(),
    );

    final userDocRef = _db.collection('favoritesperuser').doc(userId);

    // Add movie to user's favorites
    await userDocRef.set({
      'isPublic': true,
      'favorites': FieldValue.arrayUnion([favoriteRef.toMap()])
    }, SetOptions(merge: true));

    // Ensure movie exists globally and increment likeCount
    await _favMovieService.addOrUpdateMovie(movieId, keywords);
    await _favMovieService.incrementLike(movieId);
  }

  /// Remove favorite movie
  Future<void> removeFavoriteMovie(String userId, int movieId) async {
    final userDocRef = _db.collection('favoritesperuser').doc(userId);
    final snapshot = await userDocRef.get();
    if (!snapshot.exists) return;

    final favorites = (snapshot.data()?['favorites'] as List<dynamic>? ?? []);
    final updated = favorites.where((f) => f['id'] != movieId).toList();

    await userDocRef.update({'favorites': updated});
    await _favMovieService.decrementLike(movieId);
  }

  /// Toggle public/private
  Future<void> setPublicStatus(String userId, bool isPublic) async {
    await _db.collection('favoritesperuser').doc(userId)
        .set({'isPublic': isPublic}, SetOptions(merge: true));
  }

  /// Get user's favorites
  Future<FavoriteMoviesProfile?> getFavorites(String userId) async {
    final doc = await _db.collection('favoritesperuser').doc(userId).get();
    if (!doc.exists) return null;
    return FavoriteMoviesProfile.fromMap(doc.data()!);
  }

  /// Private: get keywords (from global collection or TMDB)
  Future<List<String>> _getKeywords(int movieId) async {
    List<String> keywords = await _favMovieService.getKeywords(movieId);
    if (keywords.isNotEmpty) return keywords;

    // Fetch from TMDB if missing
    keywords = await _tmdbService.fetchMovieKeywords(movieId);

    // Store in global collection
    await _favMovieService.addOrUpdateMovie(movieId, keywords);
    return keywords;
  }
}
