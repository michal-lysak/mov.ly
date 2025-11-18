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
    final double titleFontSize = (height * 0.10).clamp(18.0, 28.0);
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
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            movie.releaseDate.isNotEmpty
                                ? movie.releaseDate.split('-').first
                                : "N/A",
                            style: GoogleFonts.afacad(
                              fontSize: metaFontSize,
                              color: Colors.grey[300],
                            ),
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
                        Row(
                          children: movie.categories.take(3).map((cat) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: SizedBox(
                                width: 60,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Text(
                                    cat,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: .center,
                                    style: GoogleFonts.afacad(
                                      fontSize: metaFontSize,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        )


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
