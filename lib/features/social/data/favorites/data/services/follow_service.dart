import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../social_cache.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> follow({
    required String myUid,
    required String myUsername,
    required String theirUid,
    required String theirUsername,
  }) async {
    await Future.wait([
      _firestore
          .collection('usernames')
          .doc(theirUsername.toLowerCase())
          .collection('followers')
          .doc(myUid)
          .set({
        'username': myUsername,
        'timestamp': FieldValue.serverTimestamp(),
      }),
      _firestore
          .collection('usernames')
          .doc(myUsername.toLowerCase())
          .collection('following')
          .doc(theirUid)
          .set({
        'username': theirUsername,
        'timestamp': FieldValue.serverTimestamp(),
      }),
    ]);
  }

  Future<void> unfollow({
    required String myUid,
    required String myUsername,
    required String theirUid,
    required String theirUsername,
  }) async {
    await Future.wait([
      _firestore
          .collection('usernames')
          .doc(theirUsername.toLowerCase())
          .collection('followers')
          .doc(myUid)
          .delete(),
      _firestore
          .collection('usernames')
          .doc(myUsername.toLowerCase())
          .collection('following')
          .doc(theirUid)
          .delete(),
    ]);
  }

  void listenToFollowing({
    required String myUsername,
    required SocialCache cache,
  }) {
    _firestore
        .collection('usernames')
        .doc(myUsername.toLowerCase())
        .collection('following')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;
        final uid = change.doc.id;
        final username = data['username'] ?? '';

        if (change.type == DocumentChangeType.added) {
          cache.addFollowedUser(uid, username);
        } else if (change.type == DocumentChangeType.removed) {
          cache.removeFollowedUser(uid);
        }
      }
    });
  }

  /// ✅ Fetch initial list of users the current user is following
  Future<List<Map<String, dynamic>>> fetchInitialFollowing(String myUsername) async {
    final snapshot = await _firestore
        .collection('usernames')
        .doc(myUsername.toLowerCase())
        .collection('following')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        'username': data['username'] ?? doc.id,
        'displayName': data['username'] ?? doc.id,
        'photoUrl': '', // optional, you can fetch separately
        'favMovieIds': [], // optional, populate if needed
      };
    }).toList();
  }
}
