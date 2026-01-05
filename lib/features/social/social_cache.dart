import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'data/favorites/data/models/followed_user.dart';
import 'data/favorites/data/services/favorite_service.dart';
import 'data/favorites/data/services/follow_service.dart';

class SocialCache extends ChangeNotifier {
  final Box followingBox;
  Map<int, List<FollowedUser>> _movieToUsersMap = {};
  bool _isSyncing = false; // Prevents double loading

  SocialCache(this.followingBox) {
    // Initial build
    rebuild();
    // Listen to Hive changes
    followingBox.watch().listen((event) => rebuild());
  }

  // Rebuild the movie->users map
  void rebuild() {
    final users = allFollowing;
    _movieToUsersMap = _buildMovieToUsersMap(users);
    notifyListeners();
  }

  // Instant check if following
  bool isFollowing(String uid) => followingBox.containsKey(uid);

  // List of all followed users
  List<FollowedUser> get allFollowing {
    return followingBox.keys.map((uid) {
      final data = followingBox.get(uid);
      if (data is Map) {
        return FollowedUser.fromHive(uid.toString(), data);
      }
      return null;
    }).whereType<FollowedUser>().toList();
  }

  // Add user to cache
  void addFollowedUser(String uid, String username) {
    followingBox.put(uid, {
      'username': username,
      'uid': uid,
      'photoUrl': '',
      'displayName': username,
      'favMovieIds': []
    });
    rebuild();
  }

  // Remove user from cache
  void removeFollowedUser(String uid) {
    followingBox.delete(uid);
    rebuild();
  }

  // Load initial following from Firestore
  Future<void> loadInitialFollowingFromFirestore(List<Map<String, dynamic>> users) async {
    for (var user in users) {
      followingBox.put(user['uid'], user);
    }
    rebuild();
  }

  // Public API: who favorited a movie
  List<FollowedUser> usersWhoFavorited(int movieId) {
    return _movieToUsersMap[movieId] ?? [];
  }

  // Build movie->users map
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
    if (_isSyncing) return; // STOP if already running
    _isSyncing = true;

    try {
      debugPrint("--- 🔄 Start Syncing Friends ---");

      // 1. Fetch list of people I follow
      final followingList = await followService.fetchInitialFollowing(myUsername);
      debugPrint("Found ${followingList.length} friends.");

      // 2. Create a batch of Futures to fetch IDs in parallel
      final futures = followingList.map((userData) async {
        final String uid = userData['uid'];

        // ONLY fetch IDs, not full movies
        final favIds = await favoriteService.fetchFavoriteMovieIds(uid);

        return {
          'uid': uid,
          'username': userData['username'],
          'name': userData['displayName'] ?? '',
          'photoUrl': userData['photoUrl'] ?? '',
          'favMovies': favIds.map((id) => {'id': id}).toList(),
        };
      }).toList();

      // 3. Wait for all data to arrive
      final results = await Future.wait(futures);

      // 4. Save to Hive in ONE GO (prevents UI flickering)
      // We create a map of all entries to put them at once
      final Map<dynamic, dynamic> batchUpdate = {};
      for (var user in results) {
        batchUpdate[user['uid']] = user;
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
