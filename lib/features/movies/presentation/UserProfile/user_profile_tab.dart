import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movly/features/favorites/data/firestore_cloud/favorite_service.dart';
import '../../../auth/data/firestore_cloud/user_service.dart';
import '../../data/models/movie.dart';
import '../widgets/vertical_movies_grid.dart';
/*
  NOTE:
  This is the user profile tab, it displays the user's name, username, and their favorite movies.
  It fetches the user's profile and favorite movies from Firestore.
  IMPORTANT: The `username` is passed from the previous screen and is used to fetch the profile.
*/
class UserProfileTab extends StatefulWidget {
  final String username;
  final VoidCallback onBack;

  const UserProfileTab({
    super.key,
    required this.username,
    required this.onBack
  });

  @override
  State<UserProfileTab> createState() => _UserProfileTabState();
}

class _UserProfileTabState extends State<UserProfileTab> {
  final _userService = UserService();
  final _favService = FavoriteService();

  Map<String, dynamic>? _profile;
  List<Movie?> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _userService.getUserProfileByUsername(widget.username);

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

      if (mounted) {
        setState(() {
          _profile = profile;
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
                      const Icon(Icons.person_off, size: 50, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        "User not found",
                        style: GoogleFonts.afacad(fontSize: 20, color: Colors.grey),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 30),
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                            backgroundImage: _profile!['photoUrl'] != null
                                ? NetworkImage(_profile!['photoUrl']!)
                                : null,
                          ),
                          SizedBox(height: 16),
                          Text(
                            _profile!['name'] ?? "Unknown",
                            style: GoogleFonts.afacad(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,

                            ),
                          ),

                      Text(
                        "@" + _profile!['username'] ?? "Unknown",
                        style: GoogleFonts.afacad(
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                        ? const Center(child: Text("No favorite movies"))
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