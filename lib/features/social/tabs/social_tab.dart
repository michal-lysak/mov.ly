import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:movly/features/social/data/favorites/data/services/socialprofile_service.dart';
import 'package:movly/features/social/data/favorites/data/services/follow_service.dart';
import 'package:movly/features/social/data/favorites/data/cache/social_cache.dart';

import 'package:movly/features/movies/presentation/widgets/searching_bar.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:movly/features/movies/data/cache/poster_cache.dart';

import '../data/favorites/data/models/followed_user.dart';

class SocialTab extends StatefulWidget {
  const SocialTab({
    super.key,
    required this.onUserTap,
    required this.currentUserUsername,
  });

  final Function(String username) onUserTap;
  final String currentUserUsername;

  @override
  State<SocialTab> createState() => _SocialTabState();
}

class _SocialTabState extends State<SocialTab> {
  final TextEditingController _controller = TextEditingController();
  final TMDBService _tmdb = TMDBService();

  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  Future<void> _onChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);

    final socialProfileService =
    Provider.of<SocialProfileService>(context, listen: false);

    final users = await socialProfileService.searchUsers(query);

    if (!mounted) return;

    setState(() {
      _results = users
          .where((u) => u['username'] != widget.currentUserUsername)
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              'Social',
              style: GoogleFonts.afacad(
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SearchingBar(
              controller: _controller,
              onChanged: _onChanged,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? _buildFollowingSection()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  // ================= FOLLOWING =================

  Widget _buildFollowingSection() {
    return Consumer<SocialCache>(
      builder: (context, socialCache, _) {
        final following = socialCache.allFollowing;

        if (following.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              "Not following anyone yet",
              style: GoogleFonts.afacad(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: following.length,
          itemBuilder: (context, index) {
            return _buildUserCard(following[index]);
          },
        );
      },
    );
  }

  Widget _buildUserCard(FollowedUser user) {
    return GestureDetector(
      onTap: () => widget.onUserTap(user.username),
      child: Container(
        height: 155,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage:
                  user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                  child: user.photoUrl.isEmpty
                      ? const Icon(Icons.person, size: 16)
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
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '@${user.username}',
                      style: GoogleFonts.afacad(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (user.favMovieIds.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: user.favMovieIds.length > 5
                      ? 5
                      : user.favMovieIds.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<Movie?>(
                      future:
                      _tmdb.fetchMovieById(user.favMovieIds[index]),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return Container(
                            width: 55,
                            margin: const EdgeInsets.only(right: 8),
                            color: Colors.black26,
                          );
                        }
                        return Container(
                          width: 55,
                          margin: const EdgeInsets.only(right: 8),
                          child: CachedPosterImage.fromMovie(snap.data!),
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
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ================= SEARCH RESULTS =================

  Widget _buildSearchResults() {
    final followService = Provider.of<FollowService>(context, listen: false);

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final user = _results[index];

        final String uid = user['uid'];
        final String username = user['username'];

        return ValueListenableBuilder(
          valueListenable: Hive.box('followingBox').listenable(),
          builder: (context, Box box, child) {
            final bool isFollowing = box.containsKey(uid);

            return GestureDetector(
              onTap: () => widget.onUserTap(username),
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
                          Text(
                            user['name'] ?? username,
                            style: GoogleFonts.afacad(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '@$username',
                            style: GoogleFonts.afacad(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final myUid = FirebaseAuth.instance.currentUser!.uid;

                        if (isFollowing) {
                          await followService.unfollow(
                            myUid: myUid,
                            myUsername: widget.currentUserUsername,
                            theirUid: uid,
                            theirUsername: username,
                          );
                        } else {
                          await followService.follow(
                            myUid: myUid,
                            myUsername: widget.currentUserUsername,
                            theirUid: uid,
                            theirUsername: username,
                          );
                        }
                      },
                      child: Container(
                        height: 30,
                        width: 75,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isFollowing
                              ? Colors.grey[700]
                              : Theme.of(context).colorScheme.surface,
                        ),
                        child: Center(
                          child: Text(
                            isFollowing ? 'Following' : 'Follow',
                            style: GoogleFonts.afacad(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
