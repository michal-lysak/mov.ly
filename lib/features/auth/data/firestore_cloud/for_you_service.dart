import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';

class ForYouService {
  final FirebaseFirestore _firestore;
  final TMDBService _tmdbService;

  StreamSubscription<QuerySnapshot>? _favoritesSubscription;
  String? _currentUserId;
  Timer? _regenDebounce;

  // TMDB image base URL
  static const String _tmdbImageBase = 'https://image.tmdb.org/t/p/w500';

  /// Convert relative path to full URL
  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return '$_tmdbImageBase$path';
  }

  ForYouService({
    FirebaseFirestore? firestore,
    TMDBService? tmdbService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _tmdbService = tmdbService ?? TMDBService();

  void startListeningForUser(String userId) {
    _favoritesSubscription?.cancel();
    _currentUserId = userId;

    final favoritesMovies =
    _firestore.collection('favorites').doc(userId).collection('movies');

    _favoritesSubscription = favoritesMovies.snapshots().listen(
          (snapshot) async {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final movieId = int.tryParse(change.doc.id);
            if (movieId == null) continue;
            try {
              await _populateRelatedForMovie(movieId);
              _scheduleRegenerateForYou(userId);
            } catch (e, st) {
              debugPrint('Error populating related for $movieId: $e');
              debugPrint('$st');
            }
          }
        }
      },
      onError: (error) => debugPrint('Favorites listener error: $error'),
      cancelOnError: false,
    );
  }

  void _scheduleRegenerateForYou(String userId, {int limit = 10}) {
    _regenDebounce?.cancel();
    _regenDebounce = Timer(const Duration(seconds: 2), () {
      generateAndSaveForYouList(userId, limit: limit);
    });
  }

  Future<void> _populateRelatedForMovie(int movieId) async {
    final similar = await _tmdbService.fetchSimilarMovies(movieId);
    final topFive = similar.take(5).toList();

    final relatedCollection = _firestore.collection('related');
    final batch = _firestore.batch();

    final existingForParent = await relatedCollection
        .where('parentId', isEqualTo: movieId)
        .get();

    for (final doc in existingForParent.docs) {
      batch.delete(doc.reference);
    }

    for (final Movie m in topFive) {
      final docRef = relatedCollection.doc('${movieId}_${m.id}');
      batch.set(docRef, {
        'parentId': movieId,
        'relatedId': m.id,
        'id': m.id,
        'title': m.title,
        'overview': m.overview,
        'posterPath': _getFullImageUrl(m.posterPath),
        'backdropPath': _getFullImageUrl(m.backdropPath),
        'releaseDate': m.releaseDate,
        'voteAverage': m.voteAverage,
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'tmdb_similar',
      });
    }

    await batch.commit();
  }

  Future<void> dispose() async {
    await _favoritesSubscription?.cancel();
    _favoritesSubscription = null;
    _currentUserId = null;
    _regenDebounce?.cancel();
    _regenDebounce = null;
  }

  Future<List<Movie>> buildForYouList(String userId, {int limit = 10}) async {
    final favSnap = await _firestore
        .collection('favorites')
        .doc(userId)
        .collection('movies')
        .get();

    if (favSnap.docs.isEmpty) return [];

    final favoriteIds = favSnap.docs
        .map((d) => int.tryParse(d.id))
        .whereType<int>()
        .toList();

    if (favoriteIds.isEmpty) return [];

    final Map<int, _ScoredRelated> relatedById = {};

    for (int i = 0; i < favoriteIds.length; i += 10) {
      final chunk = favoriteIds.sublist(
        i,
        (i + 10 > favoriteIds.length) ? favoriteIds.length : i + 10,
      );

      final query = await _firestore
          .collection('related')
          .where('parentId', whereIn: chunk)
          .get();

      for (final doc in query.docs) {
        final data = doc.data();
        final int? relatedId = (data['relatedId'] ?? data['id']) as int?;
        if (relatedId == null) continue;
        if (favoriteIds.contains(relatedId)) continue;

        final double voteAverage = (data['voteAverage'] ?? 0).toDouble();
        final String title = (data['title'] ?? '') as String;
        final String overview = (data['overview'] ?? '') as String;
        final String? posterPath = data['posterPath'] as String?;
        final String? backdropPath = data['backdropPath'] as String?;
        final String releaseDate = data['releaseDate'] ?? 'Unknown';

        final existing = relatedById[relatedId];
        if (existing == null) {
          relatedById[relatedId] = _ScoredRelated(
            movieId: relatedId,
            title: title,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath, // ✅ added
            releaseDate: releaseDate,
            voteAverage: voteAverage,
            count: 1,
          );
        } else {
          existing.count++;
          if (voteAverage > existing.voteAverage) {
            existing
              ..voteAverage = voteAverage
              ..title = title
              ..overview = overview
              ..posterPath = posterPath
              ..backdropPath = backdropPath // ✅ update
              ..releaseDate = releaseDate;
          }
        }
      }
    }

    if (relatedById.isEmpty) return [];

    final scored = relatedById.values.toList()
      ..sort((a, b) {
        final aScore = a.count * 2.0 + a.voteAverage * 0.1;
        final bScore = b.count * 2.0 + b.voteAverage * 0.1;
        if (bScore != aScore) return bScore.compareTo(aScore);
        return b.voteAverage.compareTo(a.voteAverage);
      });

    return scored.take(limit).map((item) {
      return Movie(
        id: item.movieId,
        title: item.title,
        overview: item.overview,
        posterPath: item.posterPath,
        backdropPath: item.backdropPath, // ✅ used here
        releaseDate: item.releaseDate,
        voteAverage: item.voteAverage,
      );
    }).toList();
  }

  Future<void> generateAndSaveForYouList(String userId, {int limit = 10}) async {
    try {
      final list = await buildForYouList(userId, limit: limit);

      final userDocRef = _firestore.collection('users').doc(userId);
      await userDocRef.set({
        'lastForYouUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final collection = userDocRef.collection('foryoupagelist');
      final batch = _firestore.batch();

      final existing = await collection.get();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }

      for (int i = 0; i < list.length; i++) {
        final m = list[i];
        batch.set(collection.doc(m.id.toString()), {
          'id': m.id,
          'title': m.title,
          'overview': m.overview,
          'posterPath': m.posterPath,
          'backdropPath': m.backdropPath, // ✅ saving correctly
          'releaseDate': m.releaseDate,
          'voteAverage': m.voteAverage,
          'position': i,
          'createdAt': FieldValue.serverTimestamp(),
          'source': 'for_you_from_related',
        });
      }

      await batch.commit();
    } catch (e, st) {
      debugPrint('❌ Error generating for-you list for user $userId: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  Future<void> regenerateForYouList({int limit = 10}) async {
    if (_currentUserId == null) {
      debugPrint('⚠️ No user currently listening.');
      return;
    }
    await generateAndSaveForYouList(_currentUserId!, limit: limit);
  }

  Future<List<Movie>> getForYouList(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('foryoupagelist')
          .orderBy('position')
          .get();

      return _parseForYouListFromSnapshot(snapshot);
    } catch (_) {
      return [];
    }
  }

  List<Movie> _parseForYouListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Movie(
        id: data['id'] as int,
        title: data['title'] ?? '',
        overview: data['overview'] ?? '',
        posterPath: data['posterPath'],
        backdropPath: data['backdropPath'], // ✅ read correctly
        releaseDate: data['releaseDate'] ?? 'Unknown',
        voteAverage: (data['voteAverage'] ?? 0).toDouble(),
      );
    }).toList();
  }

  Stream<List<Movie>> streamForYouList(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('foryoupagelist')
        .orderBy('position')
        .snapshots()
        .map(_parseForYouListFromSnapshot);
  }
}

class _ScoredRelated {
  _ScoredRelated({
    required this.movieId,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
    required this.count,
  });

  final int movieId;
  String title;
  String overview;
  String? posterPath;
  String? backdropPath;
  String releaseDate;
  double voteAverage;
  int count;
}
