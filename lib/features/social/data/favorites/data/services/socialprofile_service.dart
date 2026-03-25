import 'package:cloud_firestore/cloud_firestore.dart';

class SocialProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _usernames =
  FirebaseFirestore.instance.collection('usernames');

  Future<Map<String, dynamic>?> getProfileByUsername(String username) async {
    final doc = await _usernames.doc(username.toLowerCase()).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;

    return {
      'uid': data['uid'],
      'username': data['username'],
      'name': data['name'],
      'photoUrl': data['photoUrl'] ?? '',
    };
  }


  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final snap = await _usernames
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(20)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'uid': data['uid'],
        'username': data['username'],
        'name': data['name'],
        'photoUrl': data['photoUrl'] ?? '',
      };
    }).toList();
  }
}
