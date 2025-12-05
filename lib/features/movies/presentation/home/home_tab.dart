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
import '../../data/cache/backdrop_cache.dart';
import '../widgets/horizontal-posters-scrolling.dart';

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
  bool _isLoading = true; // Controls initial load state

  List<Movie> _forYouMovies = [];

  @override
  void initState() {
    super.initState();

    // 1. Start loading data immediately
    _loadData();

    _pageController.addListener(() {
      final page = _pageController.page ?? 0;
      _activeIndexNotifier.value = page.round();
    });
  }

  // 2. Main orchestration function
  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (mounted) setState(() => _isLoading = true);

    // Step A: Generate recommendations if needed
    await _generateForYouIfNeeded(user);

    List<String> ids = [];
    try {
      // 1. Reference the subcollection
      final subcollectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('foryoupagelist');

      // 2. Fetch all documents in that subcollection
      final querySnapshot = await subcollectionRef.get();

      ids = querySnapshot.docs.map((doc) => doc.id).toList();

      // If your movie ID is stored in a field called 'movieId', use this instead:
      // ids = querySnapshot.docs.map((doc) => doc.data()['movieId'] as String).toList();

    } catch (e) {
      print("Error fetching IDs from subcollection: $e");
    }
    // ---------------------------------------------

    // Step C: Load the actual Movie objects
    if (ids.isNotEmpty) {
      await _loadMoviesFromIds(ids);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _generateForYouIfNeeded(User user) async {
    if (_isGenerating) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final alreadyGenerated = userDoc.data()?['forYouGenerated'] == true;

      if (alreadyGenerated) return;

      if (mounted) setState(() => _isGenerating = true);

      await _forYouService.generateForYouMovies(user.uid);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'forYouGenerated': true});

    } catch (e) {
      print("Error generating: $e");
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _loadMoviesFromIds(List<String> ids) async {
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
        });
      }
    } catch (e) {
      print("Load error: $e");
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
              const SizedBox(height: 40),
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
              const SizedBox(height: 20),

              if (_isLoading || _isGenerating)
                SizedBox(
                  height: cardHeight + 40,
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (_forYouMovies.isEmpty)
                SizedBox(
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
                )
              else
                SizedBox(
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
    );
  }
}

class MovieCard extends StatelessWidget {
  const MovieCard({
    super.key,
    required this.movie,
    required this.width,
    required this.height,
    this.isActive = false,
    this.onTap,
  });

  final Movie movie;
  final double width;
  final double height;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double scale = isActive ? 1.0 : 0.87;
    final double titleFontSize = (height * 0.10).clamp(18.0, 28.0);
    final double metaFontSize = (height * 0.072).clamp(12.0, 18.0);

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Backdrop
              CachedBackdropImage.fromMovie(movie),

              // Fade
              Positioned(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.82),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.bebasNeue(
                        height: 0.9,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            movie.releaseDate.isNotEmpty
                                ? movie.releaseDate.split('-').first
                                : "N/A",
                            style: GoogleFonts.afacad(
                              fontSize: metaFontSize,
                              color: Colors.grey[300],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "·",
                          style: GoogleFonts.afacad(
                            fontSize: metaFontSize,
                            color: Colors.grey[300],
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Categories List
                        Row(
                          children: movie.categories.take(3).map((cat) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: SizedBox(
                                width: 60,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Text(
                                    cat,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.afacad(
                                      fontSize: metaFontSize,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}