import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';

class ForYouPageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _tmdb = TMDBService();

  Stream<List<String>> streamForYouList(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('foryoupagelist')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d['id'].toString()).toList());
  }

  /// Fetch cached ForYou list, update only if needed
  Future<List<String>> getForYouListOnce(String uid) async {
    final colRef = _db.collection('users').doc(uid).collection('foryoupagelist');

    // Try to get from cache first
    try {
      final cacheSnap = await colRef.get(const GetOptions(source: Source.cache));
      if (cacheSnap.docs.isNotEmpty) {
        return cacheSnap.docs.map((d) => d['id'].toString()).toList();
      }
    } catch (_) {
      // Cache miss, fall back to server
    }

    final serverSnap = await colRef.get();
    return serverSnap.docs.map((d) => d['id'].toString()).toList();
  }

  /// Generate ForYou movies.
  /// Returns true only if it actually wrote movies to Firestore.
  Future<bool> generateForYouMovies(String uid) async {
    try {
      final favDocRef = _db.collection('favoritesperuser').doc(uid);
      final forYouCol = _db.collection('users').doc(uid).collection('foryoupagelist');

      // Fetch favorites once
      final favDoc = await favDocRef.get();
      if (!favDoc.exists) return false;

      final List<dynamic> favorites = favDoc.data()?['favorites'] ?? [];
      if (favorites.isEmpty) return false;

      // Safe date parser
      DateTime? parseFavoritedAt(String? s) {
        if (s == null || s.isEmpty) return null;
        try {
          return DateTime.parse(s);
        } catch (_) {
          return null;
        }
      }

      // Sort favorites by favoritedAt descending
      favorites.sort((a, b) {
        final aDate = parseFavoritedAt(a['favoritedAt']);
        final bDate = parseFavoritedAt(b['favoritedAt']);

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1; // push invalid dates to end
        if (bDate == null) return -1;

        return bDate.compareTo(aDate); // newest first
      });

      // Latest favorite timestamp
      final lastUpdate = parseFavoritedAt(favorites.first['favoritedAt']);
      if (lastUpdate == null) return false;

      // Check last generated ForYou (DON'T use cache-only, it can be empty)
      final lastGeneratedSnap = await forYouCol
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      final lastGenerated = lastGeneratedSnap.docs.isNotEmpty
          ? (lastGeneratedSnap.docs.first.data()['timestamp'] as Timestamp?)?.toDate()
          : null;

      if (lastGenerated != null && lastUpdate.compareTo(lastGenerated) <= 0) {
        return false; // nothing changed
      }

      // Generate keywords from favorites
      final ids = favorites.map((f) => f['id'].toString()).toList();
      final keywordDocs = await Future.wait(
        ids.map((id) => _db.collection('favoritemovies').doc(id).get()),
      );

      final keywords = <String>[];
      for (var doc in keywordDocs) {
        if (!doc.exists) continue;
        print(doc.data()?['keywords']);
        final k = doc.data()?['keywords'] ?? [];
        if (k is List && k.isNotEmpty) {
          final shuffled = List.from(k)..shuffle(Random());
          keywords.add(shuffled.first.toString());
        }
      }
      if (keywords.isEmpty) return false;

      final searchKeywords = keywords.toSet().take(5).toList();
      final discovered = <String>[];

      for (final kw in searchKeywords) {
        try {
          print("browsing keyword: $kw");
          final results = await _tmdb.discoverByKeyword(keyword: kw);
          discovered.addAll(results.map((m) => m.id.toString()).take(3));
        } catch (_) {}
      }

      final unique = discovered.toSet().take(20).toList();
      if (unique.isEmpty) return false;

      // Batch write to Firestore
      final batch = _db.batch();

      final existing = await forYouCol.get();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }

      for (final id in unique) {
        batch.set(forYouCol.doc(id), {
          'id': id,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return true; // actually generated and wrote movies
    } catch (e) {
      print("ForYou generation error: $e");
      rethrow;
    }
  }

  void dispose() {}
}
