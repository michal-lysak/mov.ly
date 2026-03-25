// home_tab.dart (your HomeTab file) — full file with the fixed generation logic
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ri.dart';
import 'package:shimmer/shimmer.dart';

// Your internal imports
import 'package:movly/features/movies/data/services/tmdb_service.dart';
import 'package:movly/features/movies/presentation/widgets/movie_sheet.dart';
import '../../../social/data/favorites/data/services/favorite_service.dart';
import '../../../social/data/favorites/data/services/foryoupage_service.dart';
import '../../data/models/movie.dart';
import '../widgets/horizontal-posters-scrolling.dart';
import '../widgets/movie_card.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback onAccountOptions_Tap;
  final VoidCallback onFavWatch_Tap;

  const HomeTab({super.key, required this.onAccountOptions_Tap, required this.onFavWatch_Tap});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin {
  final TMDBService _tmdbService = TMDBService();
  final FavoriteService _favoriteService = FavoriteService();
  final PageController _pageController = PageController(viewportFraction: 0.8);
  final ForYouPageService _forYouService = ForYouPageService();
  final ValueNotifier<int> _activeIndexNotifier = ValueNotifier<int>(0);

  bool _isGenerating = false;
  bool _isLoading = true;
  List<Movie> _forYouMovies = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();

    _pageController.addListener(() {
      final page = _pageController.page ?? 0;
      _activeIndexNotifier.value = page.round();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _forYouService.dispose();
    _activeIndexNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (mounted) setState(() => _isLoading = true);

    await _generateForYouIfNeeded(user);

    List<String> ids = [];
    try {
      final subcollectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('foryoupagelist');

      final querySnapshot = await subcollectionRef.get();
      // safer: read stored 'id' field (works even if doc IDs change later)
      ids = querySnapshot.docs.map((doc) => doc.data()['id'].toString()).toList();
    } catch (e) {
      debugPrint("Error fetching IDs: $e");
    }

    if (ids.isNotEmpty) {
      await _loadMoviesFromIds(ids);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _generateForYouIfNeeded(User user) async {
    if (_isGenerating) return;

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      await _forYouService.generateForYouMovies(user.uid);


      if (mounted) setState(() => _isGenerating = true);


      final didGenerate = await _forYouService.generateForYouMovies(user.uid);

      if (didGenerate) {
        // use set + merge so it never fails if the user doc didn't exist yet
        await userRef.set({'forYouGenerated': true}, SetOptions(merge: true));
      } else {
        // optional: helps you debug in Firestore
        await userRef.set({
          'forYouGenerated': false,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error generating: $e");
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
          debugPrint("Failed loading movie $id: $e");
        }
      }
      if (mounted) setState(() => _forYouMovies = movies);
    } catch (e) {
      debugPrint("Load error: $e");
    }
  }

  Widget _shimmerCard(double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade800,
        highlightColor: Colors.grey.shade600,
        child: Container(width: width, height: height, color: Colors.white),
      ),
    );
  }

  Widget buildForYouShimmer({required double cardWidth, required double cardHeight}) {
    return SizedBox(
      height: cardHeight + 40,
      child: PageView.builder(
        controller: _pageController,
        itemCount: 5,
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please log in")));
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    Text(
                      'Home',
                      style: GoogleFonts.afacad(fontSize: 32, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),

                            GestureDetector(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: Iconify(Ri.heart_fill, size: 28, color: Colors.white),
                              ),
                              onTap: widget.onFavWatch_Tap,
                            ),

                            const SizedBox(width: 20),

                    GestureDetector(
                      onTap: widget.onAccountOptions_Tap,
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          String? photoUrl;

                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>;
                            photoUrl = data['photoUrl'];
                          }

                          return CircleAvatar(
                            radius: 15,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            backgroundImage:
                            photoUrl != null && photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null || photoUrl.isEmpty
                                ? Icon(
                              Icons.person,
                              size: 18,
                              color: Theme.of(context).colorScheme.surface,
                            )
                                : null,
                          );
                        },
                      ),

                    ),

                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_isLoading || _isGenerating)
                buildForYouShimmer(cardWidth: cardWidth, cardHeight: cardHeight)
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
                      return ValueListenableBuilder<int>(
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
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              MovieCarousel(
                title: 'Most loved movies',
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
