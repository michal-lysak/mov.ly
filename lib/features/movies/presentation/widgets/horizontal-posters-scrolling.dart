import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';
import '../../data/cache/poster_cache.dart';
import 'movie_sheet.dart';

class MovieCarousel extends StatefulWidget {
  final String title;
  final Future<List<Movie>> moviesFuture;
  final double height;

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

  Widget _buildShimmerPlaceholder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade700,
        highlightColor: Colors.grey.shade500,
        child: Container(
          width: widget.height * 0.65,
          height: widget.height,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Text(
            widget.title,
            style: GoogleFonts.afacad(fontSize: 24, fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          height: widget.height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: _isLoading ? 5 : (_movies?.length ?? 0),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (_isLoading) {
                return _buildShimmerPlaceholder();
              }

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
                  borderRadius: BorderRadius.circular(10),
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
