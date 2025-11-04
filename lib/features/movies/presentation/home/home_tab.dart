import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:movly/features/auth/data/firestore_cloud/for_you_service.dart';
import '../widgets/movie_card.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ForYouService _forYouService = ForYouService();
  final PageController _pageController = PageController(
    initialPage: 0,
    viewportFraction: 0.7,
  );

  // Base card size and aspect ratio (312x194 from your original)
  static const double _baseWidth = 312.0;
  static const double _baseHeight = 194.0;
  static const double _aspect = _baseWidth / _baseHeight;

  // Scale range: center card is 1.05x, sides shrink to 0.9x
  static const double _minScale = 0.9;
  static const double _maxScale = 1.05;

  // Convenience getter for current page (handles not-attached state)
  double get _currentPage {
    if (!_pageController.hasClients) {
      return _pageController.initialPage.toDouble();
    }
    return _pageController.page ?? _pageController.initialPage.toDouble();
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

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Padded text section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Home',
                      style: GoogleFonts.afacad(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Landscape carousel at top
              StreamBuilder<List<Movie>>(
                stream: _forYouService.streamForYouList(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 210,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SizedBox(
                      height: 210,
                      child: Center(
                        child: Text('Error: ${snapshot.error}'),
                      ),
                    );
                  }

                  final movies = snapshot.data ?? [];

                  if (movies.isEmpty) {
                    return SizedBox(
                      height: 210,
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

                  return Column(
                    children: [
                      SizedBox(
                        height: 210,
                        child: PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.horizontal,
                          pageSnapping: true,
                          itemCount: movies.length,
                          itemBuilder: (context, index) {
                            final movie = movies[index];

                            return AnimatedBuilder(
                              animation: _pageController,
                              builder: (context, child) {
                                final double distance =
                                (index - _currentPage).abs().clamp(0.0, 1.0);
                                final double scale =
                                    _minScale + (1 - distance) * (_maxScale - _minScale);

                                // Keep height under the 210 container height
                                final double height = (_baseHeight * scale).clamp(0, 206);
                                final double width = height * _aspect;

                                return Align(
                                  alignment: Alignment.center,
                                  child: MovieCard(
                                    title: movie.title,
                                    posterUrl: movie.posterPath,
                                    year: _extractYear(movie.releaseDate),
                                    category: 'Recommended',
                                    width: width,
                                    height: height,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      // Page indicator using the same controller (no ephemeral notifiers)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, _) {
                            final int current = _currentPage.round();
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                movies.length,
                                    (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: current == index ? 12 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: current == index
                                        ? Colors.white
                                        : Colors.grey.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _extractYear(String releaseDate) {
    if (releaseDate.isEmpty || releaseDate == 'Unknown') return 0;
    try {
      return int.parse(releaseDate.split('-')[0]);
    } catch (_) {
      return 0;
    }
  }
}