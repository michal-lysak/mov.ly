import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/majesticons.dart';
import 'package:movly/features/movies/data/cache/poster_cache.dart';
import '../../data/models/movie.dart';
import '../../data/services/tmdb_service.dart';
import 'movie_sheet.dart';

class VerticalMovieGrid extends StatelessWidget {
  final List<Movie> movies;
  final bool allowSelection;

  final tmdbService = TMDBService();

   VerticalMovieGrid({
    super.key,
    required this.movies,
    this.allowSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(17),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        final poster = movie.posterPath;

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
          child: SizedBox(
            width: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: poster != null
                  ? CachedPosterImage.fromMovie(movie)
                  : _buildPlaceholder(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Colors.grey.shade800,
      child: Center(
        child: Iconify(
          Majesticons.image_off,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}