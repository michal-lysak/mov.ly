import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:movly/features/movies/data/cache/poster_cache.dart';
import '../../../auth/data/firestore_cloud/user_service.dart';
import 'package:movly/features/movies/presentation/widgets/searching_bar.dart';

import '../../../social/data/models/followed_user.dart';
import '../../data/models/movie.dart';
import '../../data/services/tmdb_service.dart';

class SocialTab extends StatefulWidget {
  const SocialTab({
    super.key,
    required this.userService,
    required this.onUserTap,
    required this.currentUserUsername,
  });

  final UserService userService;
  final Function(String uid) onUserTap;
  final String currentUserUsername;

  @override
  State<SocialTab> createState() => _SocialTabState();
}

class _SocialTabState extends State<SocialTab> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  final TMDBService _tmdb = TMDBService();

  @override
  void initState() {
    super.initState();
    // This starts the real-time stream that keeps Hive updated
    widget.userService.listenToFollowingChanges(widget.currentUserUsername);
  }

// --- HELPER FUNCTION: Added inside the class scope ---
  List<FollowedUser> getFollowingListFromCache() {
    final box = Hive.box('followingBox');

    final list = box.keys.map((uid) {
      final data = box.get(uid);

      if (data is Map) {
        return FollowedUser.fromHive(uid.toString(), data);
      }
      return null; // ignore invalid entries
    }).whereType<FollowedUser>().toList();

    // sort alphabetically by username
    list.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));

    return list;
  }



  void _onChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);
    final users = await widget.userService.searchUsers(query);

    if (mounted) {
      setState(() {
        _results = users.where((u) => u['username'] != widget.currentUserUsername).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Keeps "Social" title left
          children: [
            const SizedBox(height: 40),
            Text(
              'Social',
              style: GoogleFonts.afacad(fontSize: 32, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            SearchingBar(controller: _controller, onChanged: _onChanged),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? _buildFollowingSection() // Separate method for clarity
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowingSection() {
    final List<FollowedUser> following = getFollowingListFromCache();

    if (following.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text("Not following anyone yet", style: GoogleFonts.afacad(color: Colors.grey)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: following.length,
      itemBuilder: (context, index) {
        final FollowedUser user = following[index];

        return GestureDetector(
          onTap: () => widget.onUserTap(user.username),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              height: 155,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // USER INFO
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey.shade800,
                          backgroundImage: user.photoUrl.isNotEmpty
                              ? NetworkImage(user.photoUrl)
                              : null,
                          child: user.photoUrl.isEmpty
                              ? const Icon(Icons.person, size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: GoogleFonts.afacad(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '@${user.username}',
                              style: GoogleFonts.afacad(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // MOVIE POSTERS
                    if (user.favMovieIds.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount:
                          user.favMovieIds.length > 5 ? 5 : user.favMovieIds.length,
                          itemBuilder: (context, mIndex) {
                            final int movieId = user.favMovieIds[mIndex];

                            return FutureBuilder<Movie?>(
                              future: _tmdb.fetchMovieById(movieId),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Container(
                                    width: 55,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.movie_filter,
                                        size: 20, color: Colors.white10),
                                  );
                                }

                                final movie = snapshot.data!;
                                return Container(
                                  width: 55,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: CachedPosterImage.fromMovie(movie),
                                );
                              },
                            );
                          },
                        ),
                      )
                    else
                      Text(
                        "No favorites yet",
                        style: GoogleFonts.afacad(
                            fontSize: 12,
                            color: Colors.white24,
                            fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- UI: View shown when searching ---
  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final user = _results[index];
        final String theirUserId = user['uid'];
        final String theirUsername = user['username'] ?? 'user';

        return GestureDetector(
          onTap: () => widget.onUserTap(theirUsername),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: (user['photoUrl'] != null && user['photoUrl'].isNotEmpty)
                      ? NetworkImage(user['photoUrl'])
                      : null,
                  child: (user['photoUrl'] == null || user['photoUrl'].isEmpty)
                      ? const Icon(Icons.person, size: 18)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'] ?? theirUsername,
                          style: GoogleFonts.afacad(fontSize: 17, fontWeight: FontWeight.w600)),
                      Text("@$theirUsername",
                          style: GoogleFonts.afacad(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: Hive.box('followingBox').listenable(),
                  builder: (context, Box box, child) {
                    final bool isFollowing = box.containsKey(theirUserId);
                    return GestureDetector(
                      onTap: () async {
                        if (isFollowing) {
                          await widget.userService.unfollowUser(theirUsername, widget.currentUserUsername, theirUserId);
                        } else {
                          await widget.userService.followUser(theirUsername, widget.currentUserUsername, theirUserId);
                        }
                      },
                      child: Container(
                        height: 30,
                        width: 75,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isFollowing ? Colors.grey[700] : Theme.of(context).colorScheme.surface,
                        ),
                        child: Center(
                          child: Text(isFollowing ? 'Following' : 'Follow',
                              style: GoogleFonts.afacad(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}