import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movly/features/favorites/data/firestore_cloud/foryoupage_service.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';
import '../../data/cache/backdrop_cache.dart';
import '../../data/models/movie.dart';
import '../widgets/movie_card.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TMDBService _tmdbService = TMDBService();
  final PageController _pageController = PageController(viewportFraction: 0.8);
  final ForYouPageService _forYouService = ForYouPageService();

  bool _isGenerating = false;
  bool _hasGenerated = false;
  bool _isLoadingMovies = false;

  List<Movie> _forYouMovies = [];

  @override
  void initState() {
    super.initState();
    _generateForYouIfNeeded();
  }

  Future<void> _generateForYouIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _isGenerating) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final alreadyGenerated = userDoc.data()?['forYouGenerated'] == true;

      if (alreadyGenerated) {
        _hasGenerated = true;
        return;
      }

      if (mounted) {
        setState(() {
          _isGenerating = true;
        });
      }

      await _forYouService.generateForYouMovies(user.uid);

      // Mark as generated
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'forYouGenerated': true});

      if (mounted) {
        setState(() {
          _hasGenerated = true;
          _isGenerating = false;
        });
      }

    } catch (e) {
      print("Error generating For You movies: $e");
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _loadForYouMovies(List<String> ids) async {
    if (_isLoadingMovies || ids.isEmpty) return;

    if (mounted) {
      setState(() => _isLoadingMovies = true);
    }

    try {
      final movies = <Movie>[];
      for (final id in ids) {
        try {
          final movie = await _tmdbService.fetchMovieById(id);
          if (movie != null && movie.backdropPath != null) {
            movies.add(movie);
          }
        } catch (e) {
          print("Failed loading movie $id: $e");
        }
      }

      if (mounted) {
        setState(() {
          _forYouMovies = movies;
          _isLoadingMovies = false;
        });
      }

    } catch (e) {
      print("Load error: $e");
      if (mounted) {
        setState(() => _isLoadingMovies = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _forYouService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in")),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.8;
    final cardHeight = cardWidth / (16 / 9);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 16),
                child: Text(
                  'Home',
                  style: GoogleFonts.afacad(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // FOR YOU CAROUSEL
              StreamBuilder<List<String>>(
                stream: _forYouService.streamForYouList(user.uid),
                builder: (context, snapshot) {
                  final ids = snapshot.data ?? [];

                  // Load only once
                  if (ids.isNotEmpty &&
                      _forYouMovies.isEmpty &&
                      !_isLoadingMovies &&
                      !_isGenerating) {
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _loadForYouMovies(ids));
                  }

                  if (_isGenerating || _isLoadingMovies) {
                    return SizedBox(
                      height: cardHeight + 40,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (_forYouMovies.isEmpty) {
                    return SizedBox(
                      height: cardHeight + 40,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            "Add some favorites to get recommendations!",
                            style: GoogleFonts.afacad(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    height: cardHeight + 40,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _forYouMovies.length,
                      itemBuilder: (context, index) {
                        final movie = _forYouMovies[index];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Stack(
                            children: [
                              CachedBackdropImage.fromMovie(movie),
                             /* Container(
                                child: Text(
                                  _forYouMovies[index].title,
                                  style: GoogleFonts.afacad(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                ),
                                ),
                              )*/
                            ],
                          ),

                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // FRESH FINDS
              FutureBuilder<List<Movie>>(
                future: _tmdbService.fetchPopularMovies(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final movies = snapshot.data!;
                  return _buildMoviesHorizontalList(
                    "Fresh Finds",
                    movies,
                    cardWidth: (screenWidth * 0.4).clamp(150, 200),
                    cardHeight:
                    (screenWidth * 0.4 * (3 / 2)).clamp(225, 300),
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoviesHorizontalList(
      String title,
      List<Movie> movies, {
        double? cardWidth,
        double? cardHeight,
      }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final w = cardWidth ?? (screenWidth * 0.4).clamp(150, 200);
    final h = cardHeight ?? w * (3 / 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Text(
            title,
            style: GoogleFonts.afacad(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            padding: const EdgeInsets.only(left: 15),
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Padding(
                padding: const EdgeInsets.only(right: 15),
                child: MovieCard(
                  movie: movie,
                  width: w,
                  height: h,
                  onTap: () {},
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
