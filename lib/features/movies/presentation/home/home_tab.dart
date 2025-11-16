import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movly/features/constants/spacing.dart';
import 'package:movly/features/favorites/data/firestore_cloud/foryoupage_service.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';
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

  bool _didGenerate = false;

  @override
  void initState() {
    super.initState();
    _tryGenerateForYou();
  }

  Future<void> _tryGenerateForYou() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await _forYouService.streamForYouList(user.uid).first;

    if (!_didGenerate && snapshot.isEmpty) {
      _didGenerate = true;
      await _forYouService.generateForYouMovies(user.uid);
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
        body: Center(child: Text('Please log in')),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.8;
    final cardHeight = cardWidth / (16.0 / 9.0);

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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: cardHeight + 40,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return SizedBox(
                      height: cardHeight + 40,
                      child: Center(child: Text('Error: ${snapshot.error}')),
                    );
                  }

                  final movieIds = snapshot.data ?? [];

                  if (movieIds.isEmpty) {
                    return SizedBox(
                      height: cardHeight + 40,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'Add some favorites to get personalized recommendations!',
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
                      padEnds: true,
                      itemCount: movieIds.length,
                      itemBuilder: (context, index) {
                        final movieId = movieIds[index];
                        final posterUrl = _tmdbService.getPosterUrl(movieId);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          child: MovieCard(
                            posterUrl: posterUrl,
                            width: cardWidth,
                            height: cardHeight,
                            isActive: true,
                            onTap: () {},
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return _buildMoviesHorizontalList(
                    "Fresh Finds",
                    snapshot.data!,
                    cardWidth: (screenWidth * 0.4).clamp(150.0, 200.0),
                    cardHeight:
                    (screenWidth * 0.4 * (3.0 / 2.0)).clamp(225.0, 300.0),
                    horizontalPadding: 15.0,
                    itemSpacing: kPosterSpacing,
                    titlePadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
        double horizontalPadding = 15.0,
        double itemSpacing = 15.0,
        EdgeInsetsGeometry titlePadding =
        const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double finalCardWidth =
        cardWidth ?? (screenWidth * 0.4).clamp(150.0, 200.0);
    final double finalCardHeight =
        cardHeight ?? finalCardWidth * (3.0 / 2.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: titlePadding,
          child: Text(
            title,
            style: GoogleFonts.afacad(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: finalCardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            padding: EdgeInsets.only(left: horizontalPadding),
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Padding(
                padding: EdgeInsets.only(right: itemSpacing),
                child: MovieCard(
                  movie: movie,
                  width: finalCardWidth,
                  height: finalCardHeight,
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
