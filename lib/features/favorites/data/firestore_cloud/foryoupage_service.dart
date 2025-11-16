import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';

class ForYouPageService {
  final _db = FirebaseFirestore.instance;
  final _tmdb = TMDBService();

  /// Stream only IDs for poster carousel
  Stream<List<String>> streamForYouList(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('foryoupagelist')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d['id'].toString()).toList());
  }

  /// Generate For You movies (store only IDs)
  Future<void> generateForYouMovies(String uid) async {
    try {
      // Latest 10 favorites
      final latest = await _db
          .collection('users')
          .doc(uid)
          .collection('favoritesperuser')
          .orderBy('addedAt', descending: true)
          .limit(10)
          .get();

      // Older 5 favorites
      final lastLatest = latest.docs.isNotEmpty
          ? (latest.docs.last['addedAt'] as Timestamp).toDate()
          : DateTime.now();

      final older = await _db
          .collection('users')
          .doc(uid)
          .collection('favoritesperuser')
          .where('addedAt', isLessThan: lastLatest)
          .limit(5)
          .get();

      final movieIds = [
        ...latest.docs.map((d) => d['movieId'].toString()),
        ...older.docs.map((d) => d['movieId'].toString()),
      ];

      if (movieIds.isEmpty) return;

      // Pick ONE keyword per movie
      final keywordDocs = await Future.wait(
        movieIds.map((id) => _db.collection('favoritemovies').doc(id).get()),
      );

      final keywords = <String>[];
      for (var doc in keywordDocs) {
        if (!doc.exists) continue;
        final List<dynamic> k = doc['keywords'];
        if (k.isNotEmpty) {
          k.shuffle();
          keywords.add(k.first);
        }
      }

      if (keywords.isEmpty) return;

      final searchKeywords = keywords.take(5).toList();

      // Discover movies from TMDB
      final discovered = <String>[];
      for (final kw in searchKeywords) {
        final results = await _tmdb.discoverByKeyword(keyword: kw);
        discovered.addAll(results.map((m) => m.id.toString()).take(5));
      }

      // Remove duplicates
      final unique = discovered.toSet().toList();

      // Save only IDs
      final col =
      _db.collection('users').doc(uid).collection('foryoupagelist');

      for (var id in unique) {
        await col.doc(id).set({
          'id': id,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("ForYou generation error: $e");
    }
  }

  void dispose() {}
}
