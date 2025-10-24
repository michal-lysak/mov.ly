import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:movly/features/movies/presentation/widgets/cached_poster_image.dart';

class PreHomePage extends StatefulWidget {
  const PreHomePage({super.key});

  @override
  State<PreHomePage> createState() => _PreHomePageState();
}

class _PreHomePageState extends State<PreHomePage> {

  final tmdbService = TMDBService();
  final ScrollController _scrollController = ScrollController();

  List<Movie> _movies = [];
  final _favoriteIds = <int>{};
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;


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

  // Fetch movies
  Future<void> _fetchMovies() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final newMovies = await tmdbService.fetchPopularMovies(page: _currentPage);

      setState(() {
        if (newMovies.isEmpty) {
          _hasMore = false;
        } else {
          // Only add movies that are not already in _movies
          for (var movie in newMovies) {
            if (_movies.any((m) => m.id == movie.id)) {
              debugPrint('Skipping duplicate movie: ${movie.title}');
            } else {
              _movies.add(movie);
            }
          }
          _currentPage++;
        }
      });
    } catch (e) {
      debugPrint('Error fetching movies: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }


    // Refresh option
    Future<void> _refreshMovies() async {
      setState(() {
        _movies.clear();
        _currentPage = 1;
        _movies.clear();
        _hasMore = true;
      });
      await _fetchMovies();
      await _fetchMovies();
    }

    // Cleanup
    @override
    void dispose() {
      _scrollController.dispose();
      super.dispose();
    }

  @override

  Widget build(BuildContext context) {


    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 90),
            Text(
              'Mov.ly',
              style: GoogleFonts.lilyScriptOne(
                fontSize: 40
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Choose your favorite movies',
              style: GoogleFonts.kronaOne(
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // The movie grid with a fade overlay below:
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshMovies,
                child: Stack(
                  children: [
                    // Movie grid
                    GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: _movies.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _movies.length) {
                          return const Center(child: CircularProgressIndicator());
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
                                    color: Theme.of(context).colorScheme.primary,
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
                            backgroundColor: Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            // Do something on continue
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
              ),
            ),

          ],
        ),
      ),
    );
  }
}