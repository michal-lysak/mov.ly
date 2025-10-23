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
  final _selectedMovies = <int>{};

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
                          final isSelected = _selectedMovies.contains(movie.id);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedMovies.remove(movie.id);
                                } else {
                                  _selectedMovies.add(movie.id);
                                }
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
                                          color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    )
                                  ),
                              ],
                            ),
                          );
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
                              Colors.black.withOpacity(0.8),
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