import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ri.dart';
import 'package:movly/features/auth/data/firestore_cloud/user_service.dart';
import 'package:movly/features/favorites/data/firestore_cloud/favorite_service.dart';
import 'package:movly/features/favorites/data/firestore_cloud/foryoupage_service.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';
import 'package:movly/features/movies/presentation/widgets/movie_sheet.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/models/movie.dart';
import '../../data/cache/backdrop_cache.dart';
import '../widgets/horizontal-posters-scrolling.dart';
import '../widgets/movie_card.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback onOpenLiked;
  final UserService userService;

  const HomeTab({super.key, required this.onOpenLiked, required this.userService});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TMDBService _tmdbService = TMDBService();
  final FavoriteService _favoriteService = FavoriteService();
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

  Widget buildForYouShimmer({
  required double cardWidth,
  required double cardHeight,
  }) {
  return SizedBox(
    height: cardHeight + 40,
    child: PageView.builder(
      controller: _pageController,
      itemCount: 5, // fake items
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double scale = 0.85;

            if (_pageController.position.haveDimensions) {
              final page = _pageController.page ?? 0.0;
              scale = (1 - (page - index).abs() * 0.15).clamp(0.85, 1.0);
            }

            return Center(
              child: Transform.scale(
                scale: scale,
                child: _shimmerCard(cardWidth, cardHeight),
              ),
            );
          },
        );
      },
    ),
  );
}

Widget _shimmerCard(double width, double height) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade600,
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
      ),
    ),
  );
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
                buildForYouShimmer(
                  cardWidth: cardWidth,
                  cardHeight: cardHeight,
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
                              userService: widget.userService,
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
                title: 'People love the most',
                sectionKey: 'top_favorites',
                moviesFuture: _favoriteService.fetchTopFavoriteMovies(),
              ),

              MovieCarousel(
                title: 'Now in Cinemas',
                sectionKey: 'now_playing',
                moviesFuture: _tmdbService.fetchNowPlayingMovies(),
              ),

              MovieCarousel(
                title: 'Popular now',
                sectionKey: 'popular',
                moviesFuture: _tmdbService.fetchPopularMovies(),
              ),

              MovieCarousel(
                title: 'Horror',
                sectionKey: 'horror',
                moviesFuture: _tmdbService.fetchHorrorMovies(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

