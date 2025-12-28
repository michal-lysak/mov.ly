import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:movly/features/auth/data/firestore_cloud/user_service.dart';
import 'package:movly/features/movies/data/models/movie.dart';

import '../../data/cache/backdrop_cache.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({
    super.key,
    required this.movie,
    required this.width,
    required this.height,
    required this.userService,
    this.isActive = false,
    this.onTap,
  });

  final Movie movie;
  final double width;
  final double height;
  final bool isActive;
  final VoidCallback? onTap;
  final UserService userService;

  @override
  Widget build(BuildContext context) {
    // Adjusted scale factors for a punchier active state
    final double scale = isActive ? 1.0 : 0.9;
    // Responsive font sizing
    final double titleFontSize = (height * 1).clamp(20.0, 36.0);
    final double metaFontSize = (height * 0.05).clamp(12.0, 15.0);
    const double cardBorderRadius = 16.0;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic, // Smoother curve
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          // Add shadow for depth
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          // Use ClipRRect here so the shadow isn't clipped by the container decoration
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cardBorderRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. The Image
                CachedBackdropImage.fromMovie(movie),

                // 2. The Gradient Overlay (Better readability)
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.3, 0.95],
                        colors: [
                          Colors.transparent,
                          Colors.black, // Solid black at bottom for text safety
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Top Section: Social Proof (Avatar Stack)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: ValueListenableBuilder(
                    valueListenable: userService.followingBox.listenable(),
                    builder: (context, Box box, _) {
                      userService.rebuildMovieLookup();
                      final users = userService.usersWhoFavorited(movie.id);

                      if (users.isEmpty) return const SizedBox.shrink();

                      final displayUsers = users.take(3).toList();
                      final remainingCount = users.length - displayUsers.length;

                      return Row(
                        children: [
                          // Overlapping Avatar Stack
                          SizedBox(
                            height: 30,
                            // Calculate width based on how many items overlap
                            width: 30.0 + (displayUsers.length - 1) * 18.0,
                            child: Stack(
                              children: List.generate(displayUsers.length, (index) {
                                final user = displayUsers[index];
                                return Positioned(
                                  left: index * 18.0, // The overlap magic
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.black, width: 2), // White border defines separation
                                    ),
                                    child: CircleAvatar(
                                      radius: 13,
                                      backgroundColor: Colors.grey[800],
                                      backgroundImage: user.photoUrl.isNotEmpty
                                          ? NetworkImage(user.photoUrl)
                                          : null,
                                      child: user.photoUrl.isEmpty
                                          ? Text(
                                        user.username.isNotEmpty
                                            ? user.username[0].toUpperCase()
                                            : '?',
                                        style: GoogleFonts.afacad(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      )
                                          : null,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          if (remainingCount > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '+$remainingCount others',
                              style: GoogleFonts.afacad(
                                fontSize: metaFontSize,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),

                // 4. Bottom Section: Movie Info
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.bebasNeue(
                            fontWeight: FontWeight.w600,
                            height: 0.95,
                            fontSize: titleFontSize,
                            color: Colors.white,
                            shadows: [Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 8, offset: Offset(0,2))]
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Metadata Row (Clean text separated by dots)
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6, // horizontal gap between items
                        runSpacing: 4, // gap between lines if it wraps
                        children: [
                          // Year
                          _buildMetaText(
                              movie.releaseDate.isNotEmpty
                                  ? movie.releaseDate.split('-').first
                                  : "N/A",
                              metaFontSize),

                          // Separator
                          _buildMetaSeparator(metaFontSize),

                          // Genres (joined by dots)
                          ...movie.categories.take(3).expand((cat) {
                            // Add separator before every genre except the very first item in the whole Wrap
                            final isFirstGenre = movie.categories.indexOf(cat) == 0;
                            return [
                              if (!isFirstGenre) _buildMetaSeparator(metaFontSize),
                              _buildMetaText(cat, metaFontSize),
                            ];
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaText(String text, double fontSize) {
    return Text(
      text,
      style: GoogleFonts.afacad(
        fontSize: fontSize,
        color: Colors.grey[300],
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildMetaSeparator(double fontSize) {
    return Text(
      "·",
      style: GoogleFonts.afacad(
        fontSize: fontSize * 1.2, // Slightly larger dot
        color: Colors.grey[500],
        fontWeight: FontWeight.bold,
      ),
    );
  }
}