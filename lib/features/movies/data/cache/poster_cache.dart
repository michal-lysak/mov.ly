import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:shimmer/shimmer.dart';

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

  // use posterUrl specifically
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
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey.shade700,
          highlightColor: Colors.grey.shade500,
          child: Container(
            width: 130,  // fixed poster width
            height: 200, // match carousel height
            color: Colors.white,
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
