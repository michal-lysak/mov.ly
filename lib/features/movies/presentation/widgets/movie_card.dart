import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import '../../../social/data/favorites/data/cache/social_cache.dart';
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
    final double scale = isActive ? 1.0 : 0.9;
    final double titleFontSize = (height * 1).clamp(20.0, 36.0);
    final double metaFontSize = (height * 0.05).clamp(12.0, 15.0);
    const double cardBorderRadius = 16.0;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cardBorderRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. The Image
                CachedBackdropImage.fromMovie(movie),

                // 2. The Gradient Overlay
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.3, 0.95],
                        colors: [
                          Colors.transparent,
                          Colors.black,
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
                  child: Consumer<SocialCache>(
                    builder: (context, socialCache, _) {
                      final users = socialCache.usersWhoFavorited(movie.id);

                      if (users.isEmpty) return const SizedBox.shrink();

                      final displayUsers = users.take(3).toList();
                      final remainingCount = users.length - displayUsers.length;

                      return Row(
                        children: [
                          // Overlapping Avatar Stack
                          SizedBox(
                            height: 30,
                            width: 30.0 + (displayUsers.length - 1) * 18.0,
                            child: Stack(
                              children: List.generate(displayUsers.length, (index) {
                                final user = displayUsers[index];
                                // Inside the builder loop
                                print("DEBUG PFP: User: ${user.username}, URL: '${user.photoUrl}'"); // <--- Add this
                                return Positioned(
                                  left: index * 18.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 13,
                                      backgroundColor: Colors.grey[800],
                                      backgroundImage: user.photoUrl.isNotEmpty
                                          ? CachedNetworkImageProvider(user.photoUrl)
                                          : null,
                                      child: user.photoUrl.isEmpty
                                          ? Text(
                                        user.username.isNotEmpty
                                            ? user.username[0].toUpperCase()
                                            : '?',
                                        style: GoogleFonts.afacad(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                  )
                                ],
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
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.8),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Metadata Row
                      _buildMetaRow(metaFontSize),
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

  Widget _buildMetaRow(double fontSize) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        // Year
        _buildMetaText(
          movie.releaseDate.isNotEmpty
              ? movie.releaseDate.split('-').first
              : "N/A",
          fontSize,
        ),

        // Separator
        _buildMetaSeparator(fontSize),

        // Genres (joined by dots)
        ...movie.categories.take(3).expand((cat) {
          final isFirstGenre = movie.categories.indexOf(cat) == 0;
          return [
            if (!isFirstGenre) _buildMetaSeparator(fontSize),
            _buildMetaText(cat, fontSize),
          ];
        }),
      ],
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
        fontSize: fontSize * 1.2,
        color: Colors.grey[500],
        fontWeight: FontWeight.bold,
      ),
    );
  }
}