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
        // Return cached data immediately
        return cacheSnap.docs.map((d) => d['id'].toString()).toList();
      }
    } catch (_) {
      // Cache miss, fall back to server
    }

    // If cache empty, fetch from server
    final serverSnap = await colRef.get();
    return serverSnap.docs.map((d) => d['id'].toString()).toList();
  }

  /// Generate ForYou movies, but check if favorites changed before heavy read
  Future<void> generateForYouMovies(String uid) async {
    try {
      final favDocRef = _db.collection('favoritesperuser').doc(uid);

      // Only fetch timestamp first to minimize read
      final favMeta = await favDocRef.get(const GetOptions(source: Source.cache));
      final lastUpdate = favMeta.exists ? favMeta['lastUpdated'] : null;

      // Check if we already generated recently
      final forYouCol = _db.collection('users').doc(uid).collection('foryoupagelist');
      final lastGeneratedSnap = await forYouCol
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get(const GetOptions(source: Source.cache));
      final lastGenerated = lastGeneratedSnap.docs.isNotEmpty
          ? lastGeneratedSnap.docs.first['timestamp']
          : null;

      // Skip generation if nothing changed
      if (lastUpdate != null && lastGenerated != null && lastUpdate.compareTo(lastGenerated) <= 0) {
        return;
      }

      // Now fetch full favorites only if needed
      final favDoc = await favDocRef.get();
      if (!favDoc.exists) return;
      final List<dynamic> favorites = favDoc['favorites'] ?? [];
      if (favorites.isEmpty) return;

      favorites.sort((a, b) =>
          (b['favoritedAt'] as Comparable).compareTo(a['favoritedAt']));

      final ids = favorites.map((f) => f['id'].toString()).toList();
      final keywordDocs = await Future.wait(
        ids.map((id) => _db.collection('favoritemovies').doc(id).get()),
      );

      final keywords = <String>[];
      for (var doc in keywordDocs) {
        if (!doc.exists) continue;
        final k = doc['keywords'] ?? [];
        if (k.isNotEmpty) {
          final shuffled = List.from(k)..shuffle(Random());
          keywords.add(shuffled.first.toString());
        }
      }
      if (keywords.isEmpty) return;

      final searchKeywords = keywords.toSet().take(5).toList();
      final discovered = <String>[];

      for (final kw in searchKeywords) {
        try {
          final results = await _tmdb.discoverByKeyword(keyword: kw);
          discovered.addAll(results.map((m) => m.id.toString()).take(3));
        } catch (_) {}
      }

      final unique = discovered.toSet().take(20).toList();
      if (unique.isEmpty) return;

      // Batch write to Firestore
      final batch = _db.batch();
      final col = _db.collection('users').doc(uid).collection('foryoupagelist');
      final existing = await col.get();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }
      for (final id in unique) {
        batch.set(col.doc(id), {
          'id': id,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      print("ForYou generation error: $e");
      rethrow;
    }
  }

  void dispose() {
  }
}


void dispose() {}
