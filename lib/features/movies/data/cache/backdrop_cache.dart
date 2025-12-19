import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:shimmer/shimmer.dart';

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

  factory CachedBackdropImage.fromPath(String path) {
    // 1. Define the base URL (use w780, w1280, or original)
    const baseUrl = 'https://image.tmdb.org/t/p/w780';

    // 2. Combine them
    return CachedBackdropImage(imageUrl: '$baseUrl$path');
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
        placeholder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
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
