import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'data/favorites/data/models/followed_user.dart';
import 'data/favorites/data/services/favorite_service.dart';
import 'data/favorites/data/services/follow_service.dart';

class SocialCache extends ChangeNotifier {
  final Box followingBox;
  Map<int, List<FollowedUser>> _movieToUsersMap = {};
  bool _isSyncing = false;

  SocialCache(this.followingBox) {
    rebuild();
    followingBox.watch().listen((event) => rebuild());
  }

  void rebuild() {
    final users = allFollowing;
    _movieToUsersMap = _buildMovieToUsersMap(users);
    notifyListeners();
  }

  bool isFollowing(String uid) => followingBox.containsKey(uid);

  List<FollowedUser> get allFollowing {
    return followingBox.keys.map((uid) {
      final data = followingBox.get(uid);
      if (data is Map) {
        return FollowedUser.fromHive(uid.toString(), data);
      }
      return null;
    }).whereType<FollowedUser>().toList();
  }

  void addFollowedUser(String uid, String username, {String name = '', String photoUrl = ''}) {
    followingBox.put(uid, {
      'username': username,
      'name': name.isNotEmpty ? name : username,
      'photoUrl': '',
      'favMovies': []
    });
    rebuild();
  }

  void removeFollowedUser(String uid) {
    followingBox.delete(uid);
    rebuild();
  }

  Future<void> loadInitialFollowingFromFirestore(List<Map<String, dynamic>> users) async {
    final Map<dynamic, dynamic> batchUpdate = {};
    for (var user in users) {
      batchUpdate[user['uid']] = {
        'username': user['username'] ?? '',
        'name': user['name'] ?? user['username'] ?? '',
        'photoUrl': user['photoUrl'] ?? '',
        'favMovies': user['favMovies'] ?? []
      };
    }
    await followingBox.putAll(batchUpdate);
    rebuild();
  }

  List<FollowedUser> usersWhoFavorited(int movieId) {
    return _movieToUsersMap[movieId] ?? [];
  }

  Map<int, List<FollowedUser>> _buildMovieToUsersMap(List<FollowedUser> users) {
    final map = <int, List<FollowedUser>>{};
    for (final user in users) {
      for (final movieId in user.favMovieIds) {
        map.putIfAbsent(movieId, () => []).add(user);
      }
    }
    return map;
  }

  Future<void> syncFriendsData({
    required String myUsername,
    required FollowService followService,
    required FavoriteService favoriteService,
  }) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      debugPrint("--- 🔄 Start Syncing Friends ---");

      final followingList = await followService.fetchInitialFollowing(myUsername);
      debugPrint("Found ${followingList.length} friends.");

      final futures = followingList.map((userData) async {
        final String uid = userData['uid'];
        final favIds = await favoriteService.fetchFavoriteMovieIds(uid);

        return {
          'uid': uid,
          'username': userData['username'] ?? '',
          'name': userData['displayName'] ?? userData['username'] ?? '',
          'photoUrl': userData['photoUrl'] ?? '',
          'favMovies': favIds.map((id) => {'id': id}).toList(),
        };
      }).toList();

      final results = await Future.wait(futures);

      final Map<dynamic, dynamic> batchUpdate = {};
      for (var user in results) {
        batchUpdate[user['uid']] = {
          'username': user['username'],
          'name': user['name'],
          'photoUrl': user['photoUrl'],
          'favMovies': user['favMovies'],
        };
      }

      await followingBox.putAll(batchUpdate);
      debugPrint("--- ✅ Friends Sync Complete ---");

    } catch (e) {
      debugPrint("Error syncing social data: $e");
    } finally {
      _isSyncing = false;
    }
  }
}