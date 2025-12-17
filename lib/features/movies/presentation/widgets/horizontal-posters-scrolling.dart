import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';
import '../../data/cache/movie_cache.dart';
import '../../data/cache/poster_cache.dart';
import '../../data/cache/sectionsCache/sections_cache.dart';
import 'movie_sheet.dart';

const double posterAspectRatio = 0.65;

class MovieCarousel extends StatefulWidget {
  final String title;
  final String sectionKey;
  final Future<List<Movie>> moviesFuture;
  final double height;

  const MovieCarousel({
    super.key,
    required this.title,
    required this.sectionKey,
    required this.moviesFuture,
    this.height = 175,
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
      final cached = await SectionsCache.loadSection(widget.sectionKey);
      if (cached != null) {
        final cachedMovies =
        await MovieCache.loadMoviesByIds(cached.movieIds);
        if (cachedMovies.isNotEmpty && mounted) {
          setState(() {
            _movies = cachedMovies;
            _isLoading = false;
          });
        }
      }

      final networkMovies = await widget.moviesFuture;
      if (mounted && networkMovies.isNotEmpty) {
        setState(() {
          _movies = networkMovies;
          _isLoading = false;
        });

        for (final m in networkMovies) {
          await MovieCache.saveMovie(m);
        }
        await SectionsCache.saveSection(
          widget.sectionKey,
          networkMovies.map((m) => m.id).toList(),
        );
      }
    } catch (e) {
      debugPrint('Error loading movies: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _shimmerItem() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade700,
        highlightColor: Colors.grey.shade500,
        child: SizedBox(
          width: widget.height * posterAspectRatio,
          height: widget.height,
          child: Container(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemWidth = widget.height * posterAspectRatio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        SizedBox(
          height: widget.height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: _isLoading ? 5 : (_movies?.length ?? 0),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (_isLoading) return _shimmerItem();

              final movie = _movies![index];
              return GestureDetector(
                onTap: () async {
                  final fullMovie =
                  await tmdbService.fetchMovieById(movie.id);
                  if (fullMovie == null) return;

                  await MovieCache.saveMovie(fullMovie);

                  if (context.mounted) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => MovieSheet(movie: fullMovie),
                    );
                  }
                },
                child: SizedBox(
                  width: itemWidth,
                  height: widget.height,
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
