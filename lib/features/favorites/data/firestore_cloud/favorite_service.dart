import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../movies/data/models/movie.dart';
import '../../../movies/data/services/tmdb_service.dart';

class FavoriteService {
  final _db = FirebaseFirestore.instance;
  final _tmdb = TMDBService();
  // Constant for the list name
  static const String _favoriteListName = 'favorites';
  static const String _watchlistName = 'watchlist';

  /// Add movie to the user's favorites list
  Future<void> favoriteMovie(String userId, int movieId) async {
    final userRef = _db.collection('favoritesperuser').doc(userId);
    await userRef.set({
      _favoriteListName: FieldValue.arrayUnion([
        {'id': movieId, 'addedAt': DateTime.now().toIso8601String()}
      ])
    }, SetOptions(merge: true));

    /// +1 to global
    await _db.collection('favoritemovies').doc(movieId.toString()).set({
      'favoritesCount': FieldValue.increment(1),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Remove movie from the user's favorites list
  Future<void> unfavoriteMovie(String userId, int movieId) async {
    final userRef = _db.collection('favoritesperuser').doc(userId);
    final snap = await userRef.get();
    if (!snap.exists) return;

    final list = List<Map>.from(snap.data()?[_favoriteListName] ?? []);
    final updated = list.where((item) => item['id'] != movieId).toList();
    await userRef.update({_favoriteListName: updated});

    /// -1 to global
    await _db.collection('favoritemovies').doc(movieId.toString()).set({
      'favoritesCount': FieldValue.increment(-1),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Check if a movie is in user's lists (favorites or watchlist)
  Future<Map<String, bool>> getMovieListsStatus(String userId, int movieId) async {
    final userRef = _db.collection('favoritesperuser').doc(userId);
    final snap = await userRef.get();

    if (!snap.exists) return {'isFavorite': false, 'inWatchlist': false};

    final data = snap.data()!;
    final favorites = List<Map>.from(data[_favoriteListName] ?? []);
    final watchlist = List<Map>.from(data[_watchlistName] ?? []);

    return {
      'isFavorite': favorites.any((item) => item['id'] == movieId),
      'inWatchlist': watchlist.any((item) => item['id'] == movieId),
    };
  }

  /// Add movie to any list (keeping this for watchlist/future use)
  Future<void> addToList(String userId, int movieId, String listName) async {
    final userRef = _db.collection('favoritesperuser').doc(userId);
    await userRef.set({
      listName: FieldValue.arrayUnion([
        {'id': movieId, 'addedAt': DateTime.now().toIso8601String()}
      ])
    }, SetOptions(merge: true));
  }

  /// Remove movie from any list (keeping this for watchlist/future use)
  Future<void> removeFromList(String userId, int movieId, String listName) async {
    final userRef = _db.collection('favoritesperuser').doc(userId);
    final snap = await userRef.get();
    if (!snap.exists) return;

    final list = List<Map>.from(snap.data()?[listName] ?? []);
    final updated = list.where((item) => item['id'] != movieId).toList();
    await userRef.update({listName: updated});
  }

  Future<List<Movie?>> fetchFavoriteMovies(String userId) async {
    debugPrint("favMovies: $userId");
    final userRef = _db.collection('favoritesperuser').doc(userId);
    final snap = await userRef.get();

    if (!snap.exists || snap.data()?[_favoriteListName] == null) return [];

    final favorites = List<Map<String, dynamic>>.from(snap.data()?[_favoriteListName]);
    final movieIds = favorites.map((f) => f['id'] as int).toList();

    // Fetch all movies in parallel for faster loading
    final movies = await Future.wait(
        movieIds.map((id) => _tmdb.fetchMovieById(id))
    );

    return movies;
  }

  Future<List<Movie>> fetchTopFavoriteMovies() async {
    final querySnapshot = await _db
        .collection('favoritemovies')
        .orderBy('favoritesCount', descending: true)
        .limit(20)
        .get();

    final movies = await Future.wait(querySnapshot.docs.map((doc) async {
      final movieId = int.tryParse(doc.id); // doc ID is movieId
      if (movieId == null) return null;
      return _tmdb.fetchMovieById(movieId);
    }));

    // Filter out nulls (in case fetching fails)
    return movies.whereType<Movie>().toList();
  }
}