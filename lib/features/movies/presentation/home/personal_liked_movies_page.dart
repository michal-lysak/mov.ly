import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ri.dart';
import '../../../social/data/favorites/data/services/favorite_service.dart';
import '../../data/cache/poster_cache.dart';
import '../../data/models/movie.dart';
import '../../data/services/tmdb_service.dart';
import '../widgets/movie_sheet.dart';

class PersonalLikedMovies extends StatefulWidget {
  final String userId;

  const PersonalLikedMovies({
    super.key,
    required this.userId,
  });

  @override
  State<PersonalLikedMovies> createState() => _PersonalLikedMoviesState();
}

class _PersonalLikedMoviesState extends State<PersonalLikedMovies> {
  final FavoriteService _favoriteService = FavoriteService();
  final tmdbService = TMDBService();
  List<Movie> _favorites = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final movies = await _favoriteService.fetchFavoriteMovies(widget.userId);

      if (mounted) {
        setState(() {
          // Filter out nulls and cast to List<Movie>
          _favorites = movies.whereType<Movie>().toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Liked Movies', style: GoogleFonts.afacad())),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (_favorites.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Liked Movies', style: GoogleFonts.afacad())),
        body: const Center(child: Text('No liked movies yet.')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text('Liked Movies', style: GoogleFonts.afacad()),
        shadowColor: Colors.blue,
        // Default back button is used automatically
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.7,
        ),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final movie = _favorites[index];

          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: GestureDetector(
              onTap: () async {
                final fullMovie = await tmdbService.fetchMovieById(movie.id);

                if (fullMovie == null) return;

                if (context.mounted) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => MovieSheet(movie: fullMovie),
                  );
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedPosterImage.fromMovie(movie),
                  Container(
                    child: const Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Iconify(
                          Ri.heart_fill,
                          size: 25,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}