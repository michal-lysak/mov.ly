import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:movly/features/movies/presentation/widgets/cached_poster_image.dart';

class PreHomePage extends StatelessWidget {
  const PreHomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final tmdbService = TMDBService();

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
              child: Stack(
                children: [
                  FutureBuilder<List<Movie>>(
                    future: tmdbService.fetchPopularMovies(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final movies = snapshot.data!;

                      return GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: movies.length,
                        itemBuilder: (context, index) {
                          final movie = movies[index];
                          return CachedPosterImage.fromMovie(movie);
                        },
                      );
                    },
                  ),

                  // The fade overlay – gives that cinematic bottom shadow
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
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

// 3. Floating button (also positioned)
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
              onPressed: () {},
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
          ],
        ),
      ),
    );
  }
}
