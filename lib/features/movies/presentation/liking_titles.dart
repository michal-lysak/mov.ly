import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';
import 'package:movly/features/movies/data/models/movie.dart';

class PreHomePage extends StatelessWidget {
  const PreHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tmdbService = TMDBService();

    return Scaffold(
      body: Center(
          child: Column(
            children: [
              const SizedBox(height: 150),
              Text(
                'Mov.ly',
                style: GoogleFonts.lilyScriptOne(
                  fontSize: 40,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Choose your favorite movies',
                  style: GoogleFonts.kronaOne(
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20), // spacing between text and grid
              Expanded(
                child: FutureBuilder<List<Movie>>(
                  future: tmdbService.fetchPopularMovies(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final movies = snapshot.data!;

                    return GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,       // 3 posters per row
                        mainAxisSpacing: 8,      // vertical spacing
                        crossAxisSpacing: 8,     // horizontal spacing
                        childAspectRatio: 0.7,   // width/height ratio for poster
                      ),
                      itemCount: movies.length,
                      itemBuilder: (context, index) {
                        final movie = movies[index];
                        final posterUrl = movie.posterPath.isNotEmpty
                            ? 'https://image.tmdb.org/t/p/w500${movie.posterPath}'
                            : 'https://via.placeholder.com/150x200';

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Image.network(
                                posterUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
        ),
      ),
    );
  }
}
