import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../../movies/data/models/movie.dart';
import '../../../../../movies/data/services/tmdb_service.dart';

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
        {'id': movieId, 'favoritedAt': DateTime.now().toIso8601String()}
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
        {'id': movieId, 'favoritedAt': DateTime.now().toIso8601String()}
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

Stream<Map<String, List<Movie>>> streamUserLists(String userId) {
  final userRef = _db.collection('favoritesperuser').doc(userId);

  return userRef.snapshots().asyncMap((snap) async {
    if (!snap.exists || snap.data() == null) {
      return {
        'favorites': [],
        'watchlist': [],
      };
    }

    final data = snap.data()!;

    final favRaw = List<Map<String, dynamic>>.from(data['favorites'] ?? []);
    final watchRaw = List<Map<String, dynamic>>.from(data['watchlist'] ?? []);

    final favIds = favRaw.map((f) => f['id'] as int).toList();
    final watchIds = watchRaw.map((f) => f['id'] as int).toList();

    final favMovies = await Future.wait(
      favIds.map((id) => _tmdb.fetchMovieById(id)),
    );

    final watchMovies = await Future.wait(
      watchIds.map((id) => _tmdb.fetchMovieById(id)),
    );

    return {
      'favorites': favMovies.whereType<Movie>().toList(),
      'watchlist': watchMovies.whereType<Movie>().toList(),
    };
  });
}


  Future<List<Movie?>> fetchFavoriteMovies(String userId) async {
    debugPrint("favMovies: $userId");

    try {
      // Check privacy setting
      final userSnap = await _db.collection('favoritesperuser').doc(userId).get();

      if (!userSnap.exists) return [];

      final isPublic = userSnap.data()?['isPublic'];

      if (isPublic != true) {
        // Favorites are private
        return [];
      }

      // Fetch favorites
      final favSnap =
      await _db.collection('favoritesperuser').doc(userId).get();

      if (!favSnap.exists ||
          favSnap.data()?[_favoriteListName] == null) {
        return [];
      }

      final favorites =
      List<Map<String, dynamic>>.from(favSnap.data()?[_favoriteListName]);

      final movieIds =
      favorites.map((f) => f['id'] as int).toList();

      // Fetch all movies in parallel
      final movies = await Future.wait(
        movieIds.map((id) => _tmdb.fetchMovieById(id)),
      );

      return movies;
    } catch (e) {
      debugPrint("Error fetching favorites: $e");
      return [];
    }
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
  }Future<List<int>> fetchFavoriteMovieIds(String userId) async {
    try {
      final userRef = _db.collection('favoritesperuser').doc(userId);
      final snap = await userRef.get();

      if (!snap.exists || snap.data() == null) return [];

      final data = snap.data()!;
      if (!data.containsKey(_favoriteListName)) return [];

      final favorites = List<Map<dynamic, dynamic>>.from(data[_favoriteListName]);

      // Extract just the integer IDs
      return favorites
          .map((f) => f['id'] as int?)
          .whereType<int>()
          .toList();
    } catch (e) {
      debugPrint("Error fetching fav IDs for $userId: $e");
      return [];
    }
  }


}