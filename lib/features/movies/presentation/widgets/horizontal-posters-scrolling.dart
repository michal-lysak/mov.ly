import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';
import '../../data/models/movie.dart';
import 'movie_sheet.dart';
import '../../data/cache/poster_cache.dart';

class MovieCarousel extends StatefulWidget {
  final String title;
  final Future<List<Movie>> moviesFuture;
  final double height; // optional height

  const MovieCarousel({
    super.key,
    required this.title,
    required this.moviesFuture,
    this.height = 200,
  });

  @override
  State<MovieCarousel> createState() => _MovieCarouselState();
}

class _MovieCarouselState extends State<MovieCarousel> {
  List<Movie>? _movies;
  bool _isLoading = true;
  final TMDBService tmdbService = TMDBService();

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    try {
      final movies = await widget.moviesFuture;
      if (mounted) {
        setState(() {
          _movies = movies;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading movies: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Text(
            widget.title,
            style: GoogleFonts.afacad(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Loading / Empty / Carousel
        SizedBox(
          height: widget.height,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _movies == null || _movies!.isEmpty
              ? const Center(child: Text('No movies found'))
              : ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: _movies!.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final movie = _movies![index];
              return GestureDetector(
                onTap: () async {
                  final fullMovie = await tmdbService.fetchMovieById(movie.id);
                  if (fullMovie == null) return;

                  if (context.mounted) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => MovieSheet(movie: fullMovie),
                    );
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedPosterImage.fromMovie(movie),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
