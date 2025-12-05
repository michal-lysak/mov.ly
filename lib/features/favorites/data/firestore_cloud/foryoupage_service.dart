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

  Future<void> generateForYouMovies(String uid) async {
    try {
      final favDoc = await _db.collection('favoritesperuser').doc(uid).get();
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
      for (var i = 0; i < keywordDocs.length; i++) {
        final doc = keywordDocs[i];
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
          discovered.addAll(
              results.map((m) => m.id.toString()).take(3)); // limit
        } catch (_) {}
      }

      final unique = discovered.toSet().take(20).toList();
      if (unique.isEmpty) return;

      final batch = _db.batch();
      final col =
      _db.collection('users').doc(uid).collection('foryoupagelist');

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

  Future<List<String>> getForYouListOnce(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('foryoupagelist')
        .orderBy('timestamp', descending: true)
        .get();

    return snap.docs.map((d) => d['id'].toString()).toList();
  }

  void dispose() {
  }
}


void dispose() {}
