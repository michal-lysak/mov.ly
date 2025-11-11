import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // List of movies currently displayed (fetched per page)
  List<Movie> _currentMovies = [];

  @override
  void initState() {
    super.initState();
    _fetchMovies();
    _scrollController.addListener(_onScroll);
  }

  void _startForYouListener(String userId) {
    //forYouService.startListeningForUser(userId);
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

  /// Fetch next page of movies from TMDB
  Future<void> _fetchMovies() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final newMovies = await tmdbService.fetchPopularMovies(page: _currentPage);

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

  /// Pull-to-refresh movies
  Future<void> _refreshMovies() async {
    setState(() {
      _currentMovies.clear();
      _currentPage = 1;
      _hasMore = true;
    });
    await _fetchMovies();
  }

  /// Toggle favorite for a single movie
  Future<void> _toggleFavorite(int movieId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await favoriteService.favoriteMovie(userId, movieId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Movie favorited!')),
      );
    } catch (e) {
      debugPrint('Error favoriting movie: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to favorite movie.')),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ------ UI ------
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              children: [
                const SizedBox(height: 25),
                SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mov.ly',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lilyScriptOne(fontSize: 30),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 50),
                          child: Text(
                            'Select your favorite movies',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.kronaOne(fontSize: 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshMovies,
                    child: Stack(
                      children: [
                        GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(17),
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: _currentMovies.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _currentMovies.length) {
                              return _isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : const SizedBox.shrink();
                            }

                            final movie = _currentMovies[index];

                            return GestureDetector(
                              onTap: () => _toggleFavorite(movie.id),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedPosterImage.fromMovie(movie),
                                ],
                              ),
                            );
                          },
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 140,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating button: Continue
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
