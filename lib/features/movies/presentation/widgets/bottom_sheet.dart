import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movly/features/movies/data/cache/backdrop_cache.dart';
import '../../data/models/movie.dart';
import '../../data/services/tmdb_service.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ri.dart';
import 'package:iconify_flutter/icons/majesticons.dart';

class MovieSheet extends StatefulWidget {
  final Movie movie;
  const MovieSheet({super.key, required this.movie});

  @override
  State<MovieSheet> createState() => _MovieSheetState();
}

class _MovieSheetState extends State<MovieSheet> {
  final TMDBService _tmdbService = TMDBService();

  late PageController _pageController;

  List<String> _backdropPaths = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _loadBackdrops();
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
    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            const SizedBox(height: 20),

            SizedBox(
              height: 200,
              child: _isLoading && _backdropPaths.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : PageView.builder(
                controller: _pageController,
                itemCount: _backdropPaths.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return _buildCarouselItem(index);
                },
              ),
            ),

            const SizedBox(height: 15),

            Center(
              child: Text(
                widget.movie.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.bebasNeue(
                  fontSize: 32,
                  height: 0.9,
                ),
              ),
            ),

            const SizedBox(height: 15),

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
                          color: Colors.grey.shade300.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: Iconify(
                    Ri.heart_line,
                    size: 32,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 10),

                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Iconify(
                      Majesticons.bookmark_plus,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    'Overview',
                    textAlign: .start,
                    style: GoogleFonts.afacad(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              Text(
              widget.movie.overview,
              textAlign: .start,
              style: GoogleFonts.afacad(
                fontSize: 16,
                color: Colors.white,
              ),
              ),
                ],

            ),



            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselItem(int index) {
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
            child: Image.network(
              'https://image.tmdb.org/t/p/w780${_backdropPaths[index]}',
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade800,
                child: const Icon(Icons.broken_image, size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
