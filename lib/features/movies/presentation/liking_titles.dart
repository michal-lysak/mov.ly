import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movly/features/auth/data/firestore_cloud/favorites_service.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';
import 'package:movly/features/movies/presentation/widgets/cached_poster_image.dart';

import '../../auth/data/firestore_cloud/for_you_service.dart';

class PreHomePage extends StatefulWidget {
  const PreHomePage({super.key});

  @override
  State<PreHomePage> createState() => _PreHomePageState();
}

class _PreHomePageState extends State<PreHomePage> {
  final favoritesService = FavoritesService();
  final tmdbService = TMDBService();
  final forYouService = ForYouService();

  final ScrollController _scrollController = ScrollController();

  final List<Movie> _movies = [];
  final _favoriteIds = <int>{};
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  // State for the continue button
  bool _isSaving = false;
  bool _isSaveSuccessful = false;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
    _scrollController.addListener(_onScroll);


  }
  void _startForYouListener(String userId) {
    forYouService.startListeningForUser(userId);
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

  // Fetch movies
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
            // Only add movies that are not already in _movies
            for (var movie in newMovies) {
              if (_movies.any((m) => m.id == movie.id)) {
                debugPrint('Skipping duplicate movie: \${movie.title}');
              } else {
                _movies.add(movie);
              }
            }
            _currentPage++;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching movies: \$e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Refresh option
  Future<void> _refreshMovies() async {
    setState(() {
      _movies.clear();
      _currentPage = 1;
      _hasMore = true;
    });
    await _fetchMovies();
  }

  // Cleanup
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }



// ------ UI ------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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

            // The movie grid with a fade overlay below:
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshMovies,
                child: Stack(
                  children: [
                    // Movie grid
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
                      itemCount: _movies.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _movies.length) {
                          return _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : const SizedBox.shrink();
                        }

                        final movie = _movies[index];
                        final isSelected = _favoriteIds.contains(movie.id);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              isSelected
                                  ? _favoriteIds.remove(movie.id)
                                  : _favoriteIds.add(movie.id);
                            });
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedPosterImage.fromMovie(movie),
                              if (isSelected)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.favorite,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Cinematic fade overlay at the bottom
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

                    // Floating "Continue" button
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 32,
                      child: Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  setState(() {
                                    _isSaving = true;
                                    _isSaveSuccessful = false;
                                  });

                                  final userId =
                                      FirebaseAuth.instance.currentUser?.uid;

                                  if (userId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Please log in to save favorites.')),
                                    );
                                    setState(() => _isSaving = false);
                                    return;
                                  }

                                  if (_favoriteIds.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Please select at least one movie!')),
                                    );
                                    setState(() => _isSaving = false);
                                    return;
                                  }

                                  try {
                                    await favoritesService.addFavoritesBatch(
                                        userId, _favoriteIds.toList());

                                    // Start the ForYou listener
                                    _startForYouListener(userId);

                                    setState(() {
                                      _isSaving = false;
                                      _isSaveSuccessful = true;
                                    });

                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Favorites saved successfully!')),
                                    );

                                    // Revert icon after 2 seconds
                                    Future.delayed(
                                        const Duration(seconds: 2), () {
                                      if (mounted) {
                                        setState(() => _isSaveSuccessful = false);
                                      }
                                    });
                                  } catch (e) {
                                    setState(() => _isSaving = false);
                                    debugPrint(
                                        '❌ Error adding favorites: \$e');
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Failed to save favorites.')),
                                    );
                                  }
                               Navigator.pushReplacementNamed(context, '/home');
                                },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 38, vertical: 16),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : _isSaveSuccessful
                                    ? const Icon(Icons.done)
                                    : const Text("Continue"),
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
    );
  }
}