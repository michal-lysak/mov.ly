import 'package:cloud_firestore/cloud_firestore.dart';

class FavMovieService {
  final _db = FirebaseFirestore.instance;

  /// Ensure keywords exist for a movie, create or update document
  Future<void> addOrUpdateMovie(int movieId, List<String> keywords) async {
    final docRef = _db.collection('favoritemovies').doc(movieId.toString());
    await docRef.set({
      'keywords': keywords,
      'lastUpdated': FieldValue.serverTimestamp(),
      'likeCount': FieldValue.increment(0) // initialize if missing
    }, SetOptions(merge: true));
  }

  /// Increment like count for a movie
  Future<void> incrementLike(int movieId) async {
    final docRef = _db.collection('favoritemovies').doc(movieId.toString());
    await docRef.set({'likeCount': FieldValue.increment(1)}, SetOptions(merge: true));
  }

  /// Decrement like count for a movie
  Future<void> decrementLike(int movieId) async {
    final docRef = _db.collection('favoritemovies').doc(movieId.toString());
    await docRef.set({'likeCount': FieldValue.increment(-1)}, SetOptions(merge: true));
  }

  /// Get keywords for a movie
  Future<List<String>> getKeywords(int movieId) async {
    final doc = await _db.collection('favoritemovies').doc(movieId.toString()).get();
    if (!doc.exists) return [];
    return List<String>.from(doc.data()?['keywords'] ?? []);
  }

  /// Get like count
  Future<int> getLikeCount(int movieId) async {
    final doc = await _db.collection('favoritemovies').doc(movieId.toString()).get();
    if (!doc.exists) return 0;
    return doc.data()?['likeCount'] ?? 0;
  }
}
