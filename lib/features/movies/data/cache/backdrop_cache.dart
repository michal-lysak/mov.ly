import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:movly/features/movies/data/models/movie.dart';

class CachedBackdropImage extends StatelessWidget {
  final String imageUrl;
  final double borderRadius;
  final BoxFit fit;

  const CachedBackdropImage({
    super.key,
    required this.imageUrl,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  });

  /// Create directly from Movie model — uses **backdropUrl**
  factory CachedBackdropImage.fromMovie(Movie movie) {
    return CachedBackdropImage(imageUrl: movie.backdropUrl);
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
        placeholder: (_, __) => Container(
          color: Colors.black12,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: Colors.black26,
          child: const Icon(Icons.landscape, color: Colors.white38, size: 46),
        ),
      ),
    );
  }
}
