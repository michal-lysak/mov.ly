import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ri.dart';
import 'package:movly/features/favorites/data/firestore_cloud/foryoupage_service.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';
import 'package:movly/features/movies/presentation/widgets/movie_sheet.dart';
import '../../data/models/movie.dart';
import '../widgets/horizontal-posters-scrolling.dart';
import '../widgets/movie_card.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback onOpenLiked;

  const HomeTab({super.key, required this.onOpenLiked});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TMDBService _tmdbService = TMDBService();
  final PageController _pageController = PageController(viewportFraction: 0.8);
  final ForYouPageService _forYouService = ForYouPageService();
  final ValueNotifier<int> _activeIndexNotifier = ValueNotifier<int>(0);

  bool _isGenerating = false;
  bool _hasGenerated = false;
  bool _isLoadingMovies = false;

  List<Movie> _forYouMovies = [];

  @override
  void initState() {
    super.initState();
    _generateForYouIfNeeded();

    _pageController.addListener(() {
      final page = _pageController.page ?? 0;
      _activeIndexNotifier.value = page.round();
    });
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
          final movie = await _tmdbService.fetchMovieById(int.parse(id));
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
    _activeIndexNotifier.dispose();
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              // HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                child: Row(
                  children: [

                    Text(
                      'Home',
                      style: GoogleFonts.afacad(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),



                    const Spacer(),
                    GestureDetector(
                      onTap: widget.onOpenLiked,
                      child: Iconify(
                        Ri.heart_fill,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 20),
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
                          padding: const EdgeInsets.all(0.0),
                          child: ValueListenableBuilder<int>(
                            valueListenable: _activeIndexNotifier,
                            builder: (context, activeIndex, child) {
                              return MovieCard(
                                movie: movie,
                                width: cardWidth,
                                height: cardHeight,
                                isActive: index == activeIndex,
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => MovieSheet(movie: movie),
                                  );
                                },

                              );

                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              MovieCarousel(
                  title: 'Now in Cinemas',
                  moviesFuture: _tmdbService.fetchNowPlayingMovies()
              ),

              MovieCarousel(
                title: "Popular now",
                moviesFuture: _tmdbService.fetchPopularMovies(),
              ),

              MovieCarousel(
                  title: 'Horror',
                  moviesFuture: _tmdbService.fetchHorrorMovies()
              ),
            ],
          ),
        ),
      ),
    ); // Scaffold
  }
}