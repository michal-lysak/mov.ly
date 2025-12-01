import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/data/firestore_cloud/user_service.dart';
import '../../../movies/data/models/movie.dart';

class UserProfileTab extends StatefulWidget {
  final String uid;
  final VoidCallback onBack;

  const UserProfileTab({super.key, required this.uid, required this.onBack});

  @override
  State<UserProfileTab> createState() => _UserProfileTabState();
}

class _UserProfileTabState extends State<UserProfileTab> {
  final _userService = UserService();
  Map<String, dynamic>? _profile;
  List<Movie?> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _userService.getUserProfile(widget.uid);
    final favorites = await _userService.getUserFavorites(widget.uid);

    setState(() {
      _profile = profile;
      _favorites = favorites;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Top bar with back arrow
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.only(top: 20, left: 8, right: 8, bottom: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                ),
                Text(
                  _profile?['username'] ?? "Profile",
                  style: GoogleFonts.afacad(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
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
                ],
              ),
            )
                : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profile!['username'] ?? "Unknown",
                    style: GoogleFonts.afacad(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Favorite Movies",
                    style: GoogleFonts.afacad(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _favorites.isEmpty
                        ? const Center(child: Text("No favorite movies"))
                        : ListView.builder(
                      itemCount: _favorites.length,
                      itemBuilder: (context, index) {
                        final movie = _favorites[index];
                        return ListTile(
                          title: Text(movie?.title ?? "Unknown"),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
