import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movly/features/movies/data/models/movie.dart';

import '../../data/cache/backdrop_cache.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({
    super.key,
    required this.movie,
    required this.width,
    required this.height,
    this.isActive = false,
    this.onTap,
  });

  final Movie movie;
  final double width;
  final double height;

  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double scale = isActive ? 1.0 : 0.87;
    final double titleFontSize = (height * 0.093).clamp(14.0, 22.0);
    final double metaFontSize = (height * 0.072).clamp(12.0, 18.0);
    final double gradientHeight = (height * 0.41).clamp(60.0, 110.0);

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Backdrop only — pure cinema
              CachedBackdropImage.fromMovie(movie),


              // Fade for text readability
              Positioned(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.82),
                      ],
                    ),
                  ),
                ),
              ),

              // Title + Year
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.afacad(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          movie.releaseDate.isNotEmpty
                              ? movie.releaseDate.split('-').first
                              : "N/A",
                          style: GoogleFonts.afacad(
                            fontSize: metaFontSize,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "·",
                          style: GoogleFonts.afacad(
                            fontSize: metaFontSize,
                            color: Colors.grey[300],
                            fontWeight: .w900,
                          ),
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            movie.categories.join(", "),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.afacad(
                              fontSize: metaFontSize,
                              color: Colors.grey[300],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
