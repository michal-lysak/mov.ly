import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:shimmer/shimmer.dart';

const double posterAspectRatio = 0.65;

class CachedPosterImage extends StatelessWidget {
  final String imageUrl;
  final double borderRadius;
  final BoxFit fit;

  const CachedPosterImage({
    super.key,
    required this.imageUrl,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  });

  factory CachedPosterImage.fromMovie(Movie movie) {
    return CachedPosterImage(imageUrl: movie.posterUrl);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        placeholder: (_, __) => Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.secondary,
          highlightColor: Theme.of(context).colorScheme.tertiary,
          child: AspectRatio(
            aspectRatio: posterAspectRatio,
            child: Container(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: Colors.grey[800],
          child: const Icon(Icons.movie, color: Colors.grey, size: 40),
        ),
      ),
    );
  }
}
