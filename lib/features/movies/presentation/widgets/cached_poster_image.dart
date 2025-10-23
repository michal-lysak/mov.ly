import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:movly/features/movies/data/models/movie.dart';

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

  // Factory constructor to create directly from a Movie
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
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(
          color: Colors.grey[900],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[800],
          child: const Icon(Icons.movie, color: Colors.grey, size: 48),
        ),
      ),
    );
  }
}
