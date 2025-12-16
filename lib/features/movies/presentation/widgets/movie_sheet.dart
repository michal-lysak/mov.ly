import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movly/features/favorites/data/firestore_cloud/favorite_service.dart';
import 'package:movly/features/movies/data/cache/backdrop_cache.dart';
import 'package:movly/features/movies/presentation/widgets/production-company-movies-scroll.dart';
import '../../data/models/movie.dart';
import '../../data/services/tmdb_service.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ri.dart';
import 'package:iconify_flutter/icons/bx.dart';
import 'package:iconify_flutter/icons/bxs.dart';
import 'package:iconify_flutter/icons/majesticons.dart';
import 'dart:ui';

class MovieSheet extends StatefulWidget {
  final Movie movie;
  const MovieSheet({super.key, required this.movie});

  @override
  State<MovieSheet> createState() => _MovieSheetState();
}

class _MovieSheetState extends State<MovieSheet> {
  final TMDBService _tmdbService = TMDBService();
  final FavoriteService favoriteService = FavoriteService();

  late PageController _pageController;
  List<String> _backdropPaths = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _inWatchlist = false;


  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _loadBackdrops();
    _loadMovieStatus();
  }

  void _loadMovieStatus() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final status = await favoriteService.getMovieListsStatus(userId, widget.movie.id);
    if (!mounted) return;

    setState(() {
      _isFavorite = status['isFavorite'] ?? false;
      _inWatchlist = status['inWatchlist'] ?? false;
    });
  }

  Future<void> _toggleFavorite(int movieId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      if (_isFavorite) {
        await favoriteService.removeFromList(userId, movieId, 'favorites');
        setState(() => _isFavorite = false);
      } else {
        await favoriteService.addToList(userId, movieId, 'favorites');
        setState(() => _isFavorite = true);
      }
    } catch (e) {
      debugPrint('Error updating favorites: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favorites.')),
        );
      }
    }
  }

  Future<void> _toggleWatchlist(int movieId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      if (_inWatchlist) {
        await favoriteService.removeFromList(userId, movieId, 'watchlist');
        setState(() => _inWatchlist = false);
      } else {
        await favoriteService.addToList(userId, movieId, 'watchlist');
        setState(() => _inWatchlist = true);
      }
    } catch (e) {
      debugPrint('Error updating watchlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update watchlist.')),
        );
      }
    }
  }

  Future<void> _loadBackdrops() async {
    try {
      if (widget.movie.backdropPath != null) {
        _backdropPaths.add(widget.movie.backdropPath!);
      }

      final fetchedPaths =
      await _tmdbService.fetchMovieBackdrops(widget.movie.id);

      if (mounted) {
        setState(() {
          for (var path in fetchedPaths) {
            if (!_backdropPaths.contains(path)) {
              _backdropPaths.add(path);
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading backdrops: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(25)),
                border: Border.all(
                  color:
                  Theme.of(context).colorScheme.surface.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // BACKDROP CAROUSEL
                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _backdropPaths.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          return _buildCarouselItem(index);
                        },
                      ),
                    ),

                    const SizedBox(height: 15),

                    // TITLE
                    Center(
                      child: Column(
                        children: [
                          Text(
                            widget.movie.title,
                            textAlign: .center,
                            style: GoogleFonts.bebasNeue(
                              fontSize: 32,
                              height: 0.9,
                            ),
                          ),

                          Text(
                            widget.movie.releaseDate.isNotEmpty
                                ? widget.movie.releaseDate.split('-').first
                                : "N/A",
                            style: GoogleFonts.afacad(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // CATEGORIES
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: widget.movie.categories.take(3).map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: SizedBox(
                            width: 80,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                  Colors.grey.shade300.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              child: Text(
                                cat,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.afacad(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 15),

                    // FAVORITE & BOOKMARK
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _toggleFavorite(widget.movie.id),
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: Iconify(
                              _isFavorite
                                  ? Ri.heart_fill
                                  : Ri.heart_line,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _toggleWatchlist(widget.movie.id),
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color:
                              Theme.of(context).colorScheme.secondary,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Iconify(
                                _inWatchlist
                                    ? Bxs.bookmark_alt_minus
                                    : Bx.bookmark_alt_plus,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 10),

                    // OVERVIEW
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overview',
                            style: GoogleFonts.afacad(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ExpandableText(
                            text: widget.movie.overview,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // MORE MOVIES FROM THE COMPANY
                    Center(
                      child: Text(
                        "More from production",
                        style: GoogleFonts.afacad(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: CompanyMoviesSection(
                        movieId: widget.movie.id,
                        productionCompanies:
                        widget.movie.productionCompanies,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselItem(int index) {
    final backdropPath = _backdropPaths[index];

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double scale = 0.8;
        if (_pageController.position.haveDimensions) {
          double page = _pageController.page ?? 0;
          double value = (page - index).abs();
          scale = (1 - (value * 0.15)).clamp(0.85, 1.0);
        }
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedBackdropImage.fromPath(backdropPath),
          ),
        ),
      ),
    );
  }
}

class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 2,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText>
    with SingleTickerProviderStateMixin {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final needTruncate = widget.text.length > 120;
    final fullText = widget.text;
    final shortText = widget.text.substring(0, 120) + "...";

    return GestureDetector(
      onTap: () => setState(() => expanded = !expanded),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: RichText(
            key: ValueKey(expanded),
            text: TextSpan(
              children: [
                TextSpan(
                  text: expanded || !needTruncate ? fullText : shortText,
                  style: GoogleFonts.afacad(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                if (needTruncate)
                  TextSpan(
                    text: expanded ? "  Less" : "  More",
                    style: GoogleFonts.afacad(
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
