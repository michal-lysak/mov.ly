import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ri.dart';
import 'package:shimmer/shimmer.dart';
import 'package:movly/features/favorites/data/firestore_cloud/favorite_service.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';
import 'package:movly/features/movies/data/cache/poster_cache.dart';

class PreHomePage extends StatefulWidget {
  const PreHomePage({super.key});

  @override
  State<PreHomePage> createState() => _PreHomePageState();
}

class _PreHomePageState extends State<PreHomePage> {
  final favoriteService = FavoriteService();
  final tmdbService = TMDBService();
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  List<Movie> _currentMovies = [];
  Set<int> _selectedMovieIds = {};

  // Unused variable removed, or you can use it for scroll effects later
  // double _titleOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchMovies();
    }
  }

  Future<void> _fetchMovies() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final newMovies =
      await tmdbService.fetchPopularMovies(page: _currentPage);

      if (mounted) {
        setState(() {
          if (newMovies.isEmpty) {
            _hasMore = false;
          } else {
            for (var movie in newMovies) {
              if (!_currentMovies.any((m) => m.id == movie.id)) {
                _currentMovies.add(movie);
              }
            }
            _currentPage++;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching movies: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshMovies() async {
    setState(() {
      _currentMovies.clear();
      _currentPage = 1;
      _hasMore = true;
      _selectedMovieIds.clear();
    });
    await _fetchMovies();
  }

  Future<void> _toggleFavorite(int movieId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      if (_selectedMovieIds.contains(movieId)) {
        await favoriteService.unfavoriteMovie(userId, movieId);
        setState(() {
          _selectedMovieIds.remove(movieId);
        });
      } else {
        await favoriteService.favoriteMovie(userId, movieId);
        setState(() {
          _selectedMovieIds.add(movieId);
        });
      }
    } catch (e) {
      debugPrint('Error favoriting movie: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to favorite movie.')),
      );
    }
  }

  Widget _buildShimmerTile() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade600,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectionCount = _selectedMovieIds.length;

    return Scaffold(
      // Optional: Add a dark background color if not set in main theme
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          Column(
            children: [
              // --- IMPROVED TOP SECTION ---
              Container(
                padding: const EdgeInsets.only(
                    top: 60, bottom: 20, left: 20, right: 20),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Mov.ly',
                      style: GoogleFonts.lilyScriptOne(
                        color: theme.colorScheme.primary,
                        fontSize: 36, // Increased size
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Animated Text Switcher
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: selectionCount == 0
                          ? Text(
                        'Select your favorite movies',
                        key: const ValueKey('instruction'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.afacad(
                          fontSize: 18,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w400,
                        ),
                      )
                          : Container(
                        key: const ValueKey('counter'),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3))
                        ),
                        child: Text(
                          '$selectionCount selected',
                          style: GoogleFonts.afacad(
                            fontSize: 18,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // --- END IMPROVED TOP SECTION ---

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshMovies,
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Added bottom padding for button
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: _currentMovies.length + (_hasMore ? 3 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _currentMovies.length) {
                        return _buildShimmerTile();
                      }

                      final movie = _currentMovies[index];
                      final isSelected = _selectedMovieIds.contains(movie.id);

                      return GestureDetector(
                        onTap: () => _toggleFavorite(movie.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: theme.colorScheme.primary, width: 2)
                                : null,
                            boxShadow: isSelected
                                ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.4), blurRadius: 8)]
                                : [],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedPosterImage.fromMovie(movie),
                                if (isSelected)
                                  Container(
                                    color: Colors.black.withOpacity(0.6),
                                    child: Center(
                                      child: Iconify(
                                        Ri.heart_fill,
                                        size: 35,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),


          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/home');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 38, vertical: 16),
                  child: Text("Continue"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}