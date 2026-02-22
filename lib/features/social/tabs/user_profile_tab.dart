import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../movies/data/models/movie.dart';
import '../../movies/presentation/widgets/vertical_movies_grid.dart';

import '../data/favorites/data/services/favorite_service.dart';
import '../data/favorites/data/services/socialprofile_service.dart';
import '../data/favorites/data/services/follow_service.dart';

/*
  NOTE:
  This is the user profile tab, it displays the user's name, username, and their favorite movies.
  It fetches the user's profile and favorite movies from Firestore.
  IMPORTANT: The `username` is passed from the previous screen and is used to fetch the profile.
*/
class UserProfileTab extends StatefulWidget {
  final String username;
  final String currentUserUsername;
  final VoidCallback onBack;

  const UserProfileTab({
    super.key,
    required this.username,
    required this.currentUserUsername,
    required this.onBack,
  });

  @override
  State<UserProfileTab> createState() => _UserProfileTabState();
}

class _UserProfileTabState extends State<UserProfileTab> {
  final _socialprofileService = SocialProfileService();
  final _favService = FavoriteService();

  Map<String, dynamic>? _profile;
  List<Movie?> _favorites = [];
  bool _isLoading = true;

  String? _profileUid;
  bool _isSelf = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _socialprofileService.getProfileByUsername(widget.username);

      if (profile == null) {
        if (mounted) {
          setState(() {
            _profile = null;
            _favorites = [];
            _isLoading = false;
          });
        }
        return;
      }

      final uid = profile['uid'] as String;
      final favorites = await _favService.fetchFavoriteMovies(uid);

      final myUid = FirebaseAuth.instance.currentUser?.uid;
      final isSelf = (myUid != null && myUid == uid);

      if (mounted) {
        setState(() {
          _profile = profile;
          _profileUid = uid;
          _isSelf = isSelf;
          _favorites = favorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _profile = null;
          _favorites = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final followService = Provider.of<FollowService>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(_profile?['username'] ?? "Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isLoading
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50.0),
                    child: CircularProgressIndicator(),
                  ),
                )
                    : _profile == null
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_off,
                          size: 50, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        "User not found",
                        style: GoogleFonts.afacad(
                            fontSize: 20, color: Colors.grey),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.3),
                            backgroundImage:
                            (_profile!['photoUrl'] != null &&
                                (_profile!['photoUrl'] as String)
                                    .isNotEmpty)
                                ? NetworkImage(_profile!['photoUrl'])
                                : null,
                            // fallback icon when no photo
                            child: (_profile!['photoUrl'] == null ||
                                (_profile!['photoUrl'] as String)
                                    .isEmpty)
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _profile!['name'] ?? "Unknown",
                            style: GoogleFonts.afacad(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '@${_profile!['username'] ?? "unknown"}',
                            style: GoogleFonts.afacad(
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                            ),
                          ),

                          // Follow button (hidden on your own profile)
                          if (!_isSelf && _profileUid != null) ...[
                            const SizedBox(height: 14),
                            ValueListenableBuilder(
                              valueListenable: Hive.box('followingBox')
                                  .listenable(),
                              builder: (context, Box box, child) {
                                final bool isFollowing =
                                box.containsKey(_profileUid);

                                return GestureDetector(
                                  onTap: () async {
                                    final myUid = FirebaseAuth
                                        .instance.currentUser!.uid;

                                    final theirUid = _profileUid!;
                                    final theirUsername =
                                        _profile!['username'] ??
                                            widget.username;

                                    if (isFollowing) {
                                      await followService.unfollow(
                                        myUid: myUid,
                                        myUsername:
                                        widget.currentUserUsername,
                                        theirUid: theirUid,
                                        theirUsername: theirUsername,
                                      );
                                    } else {
                                      await followService.follow(
                                        myUid: myUid,
                                        myUsername:
                                        widget.currentUserUsername,
                                        theirUid: theirUid,
                                        theirUsername: theirUsername,
                                      );
                                    }
                                  },
                                  child: Container(
                                    height: 34,
                                    width: 110,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      color: isFollowing
                                          ? Colors.grey[700]
                                          : Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                    child: Center(
                                      child: Text(
                                        isFollowing
                                            ? 'Following'
                                            : 'Follow',
                                        style: GoogleFonts.afacad(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        "Favorite Movies",
                        style: GoogleFonts.afacad(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _favorites.isEmpty
                        ? const Center(
                        child: Text("No favorite movies"))
                        : VerticalMovieGrid(
                      movies: _favorites.whereType<Movie>().toList(),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
