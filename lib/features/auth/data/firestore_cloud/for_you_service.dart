import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';

/// Listens for newly favorited movies and writes 5 similar movies
/// into a single top-level `related` collection in Firestore.
class ForYouService {
  final FirebaseFirestore _firestore;
  final TMDBService _tmdbService;

  StreamSubscription<QuerySnapshot>? _favoritesSubscription;
  String? _currentUserId;
  Timer? _regenDebounce;

  ForYouService({
    FirebaseFirestore? firestore,
    TMDBService? tmdbService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _tmdbService = tmdbService ?? TMDBService();

  /// Start listening to a user's favorites and populate related movies
  /// whenever a new favorite is added.
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
              // Debounce regeneration to avoid multiple writes
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
    // Fetch similar movies from TMDB
    final similar = await _tmdbService.fetchSimilarMovies(movieId);
    final topFive = similar.take(5).toList();

    final relatedCollection = _firestore.collection('related');

    final batch = _firestore.batch();

    // Clear old related docs for this parent movie from the single collection
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
        //TODO: connect there movie category
        'posterPath': m.posterPath,
        'releaseDate': m.releaseDate,
        'voteAverage': m.voteAverage,
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'tmdb_similar',
      });
    }

    await batch.commit();
  }

  /// Stop listening and clean up.
  Future<void> dispose() async {
    await _favoritesSubscription?.cancel();
    _favoritesSubscription = null;
    _currentUserId = null;
    _regenDebounce?.cancel();
    _regenDebounce = null;
  }

  /// Builds a personalized list of up to [limit] related movies for a user.
  ///
  /// Strategy:
  /// - Read user's favorite movieIds
  /// - Query `related` for those parentIds (batched by 10 for whereIn)
  /// - Exclude already-favorited titles and deduplicate by `relatedId`
  /// - Score by frequency + voteAverage to rank results
  /// - Return top [limit] as `List<Movie>` constructed from stored fields
  Future<List<Movie>> buildForYouList(String userId, {int limit = 10}) async {
    // 1) Load user favorites
    final favSnap = await _firestore
        .collection('favorites')
        .doc(userId)
        .collection('movies')
        .get();

    if (favSnap.docs.isEmpty) {
      return [];
    }

    final favoriteIds = favSnap.docs
        .map((d) => int.tryParse(d.id))
        .whereType<int>()
        .toList();

    if (favoriteIds.isEmpty) {
      return [];
    }

    // 2) Query related by parentId in batches of 10 (Firestore whereIn limit)
    final Map<int, _ScoredRelated> relatedById = {};

    for (int i = 0; i < favoriteIds.length; i += 10) {
      final chunk = favoriteIds.sublist(
        i,
        i + 10 > favoriteIds.length ? favoriteIds.length : i + 10,
      );

      final query = await _firestore
          .collection('related')
          .where('parentId', whereIn: chunk)
          .get();

      for (final doc in query.docs) {
        final data = doc.data();
        final int? relatedId = (data['relatedId'] ?? data['id']) as int?;
        if (relatedId == null) continue;

        // Skip movies the user already favorited
        if (favoriteIds.contains(relatedId)) continue;

        final double voteAverage = (data['voteAverage'] ?? 0).toDouble();
        final String title = (data['title'] ?? '') as String;
        final String overview = (data['overview'] ?? '') as String;
        final String posterPath = (data['posterPath'] ?? '') as String;
        final String releaseDate = (data['releaseDate'] ?? 'Unknown') as String;

        final existing = relatedById[relatedId];
        if (existing == null) {
          relatedById[relatedId] = _ScoredRelated(
            movieId: relatedId,
            title: title,
            overview: overview,
            posterPath: posterPath,
            releaseDate: releaseDate,
            voteAverage: voteAverage,
            count: 1,
          );
        } else {
          existing.count += 1;
          if (voteAverage > existing.voteAverage) {
            existing.voteAverage = voteAverage;
            existing.title = title;
            existing.overview = overview;
            existing.posterPath = posterPath;
            existing.releaseDate = releaseDate;
          }
        }
      }
    }

    if (relatedById.isEmpty) {
      return [];
    }

    // 3) Score and sort
    final scored = relatedById.values.toList();
    scored.sort((a, b) {
      final aScore = a.count * 2.0 + a.voteAverage * 0.1;
      final bScore = b.count * 2.0 + b.voteAverage * 0.1;
      if (bScore != aScore) return bScore.compareTo(aScore);
      return b.voteAverage.compareTo(a.voteAverage);
    });

    // 4) Build Movie models from stored fields
    final result = <Movie>[];
    for (final item in scored.take(limit)) {
      result.add(
        Movie(
          id: item.movieId,
          title: item.title,
          overview: item.overview,
          posterPath: item.posterPath,
          releaseDate: item.releaseDate,
          voteAverage: item.voteAverage,
        ),
      );
    }

    return result;
  }

  /// Generates and uploads the for-you list under
  /// top-level collection: `/users/{userId}/foryoupagelist`.
  /// This clears existing entries and writes up to [limit] items.
  ///
  /// FIXED: Now properly creates the user document and subcollection path
  Future<void> generateAndSaveForYouList(String userId, {int limit = 10}) async {
    try {
      final list = await buildForYouList(userId, limit: limit);

      // Ensure the user document exists first
      final userDocRef = _firestore.collection('users').doc(userId);

      // Create/update user document to ensure it exists
      await userDocRef.set({
        'lastForYouUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Now work with the subcollection
      final collection = userDocRef.collection('foryoupagelist');

      final batch = _firestore.batch();

      // Clear old items
      final existing = await collection.get();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }

      // Write new items with position for stable ordering
      for (int i = 0; i < list.length; i++) {
        final m = list[i];
        final ref = collection.doc(m.id.toString());
        batch.set(ref, {
          'id': m.id,
          'title': m.title,
          'overview': m.overview,
          'posterPath': m.posterPath,
          'releaseDate': m.releaseDate,
          'voteAverage': m.voteAverage,
          'position': i,
          'createdAt': FieldValue.serverTimestamp(),
          'source': 'for_you_from_related',
        });
      }

      await batch.commit();

      debugPrint('✅ For-you list saved: ${list.length} movies for user $userId');
    } catch (e, st) {
      debugPrint('❌ Error generating for-you list for user $userId: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  /// Manually trigger a for-you list regeneration for the current user
  Future<void> regenerateForYouList({int limit = 10}) async {
    if (_currentUserId == null) {
      debugPrint('⚠️ No user currently listening. Call startListeningForUser first.');
      return;
    }
    await generateAndSaveForYouList(_currentUserId!, limit: limit);
  }

  /// Fetch the saved for-you list from Firestore
  Future<List<Movie>> getForYouList(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('foryoupagelist')
          .orderBy('position')
          .get();

      // Do not auto-generate here to avoid duplicate writes; caller can trigger explicitly

      return _parseForYouListFromSnapshot(snapshot);
    } catch (e, st) {
      debugPrint('❌ Error fetching for-you list for user $userId: $e');
      debugPrint('$st');
      return [];
    }
  }

  List<Movie> _parseForYouListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Movie(
        id: data['id'] as int,
        title: data['title'] as String? ?? '',
        overview: data['overview'] as String? ?? '',
        posterPath: data['posterPath'] as String? ?? '',
        releaseDate: data['releaseDate'] as String? ?? 'Unknown',
        voteAverage: (data['voteAverage'] ?? 0).toDouble(),
      );
    }).toList();
  }

  /// Stream the for-you list in real-time
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
    required this.releaseDate,
    required this.voteAverage,
    required this.count,
  });

  final int movieId;
  String title;
  String overview;
  String posterPath;
  String releaseDate;
  double voteAverage;
  int count;
}