import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';
import 'package:movly/features/movies/data/cache/poster_cache.dart';
import '../widgets/movie_sheet.dart';
import '../widgets/searching_bar.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}


class _DiscoverPageState extends State<DiscoverPage> {
  final TextEditingController searchController = TextEditingController();
  final tmdbService = TMDBService();

  List<Movie> searchResults = [];
  bool _isSearching = false;


  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) async {
    if (value.trim().isEmpty) {
      setState(() {
        searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final results = await tmdbService.searchMovies(value);

    setState(() {
      searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discover',
                style: GoogleFonts.afacad(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              SearchingBar(
                controller: searchController,
                onChanged: _onSearchChanged,
              ),

              const SizedBox(height: 20),

              Expanded(
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : searchResults.isEmpty
                    ? Center(
                  child: Text(
                    "Start typing to search movies...",
                    style: GoogleFonts.afacad(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                )
                    : GridView.builder(
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final movie = searchResults[index];
                    return GestureDetector(
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
                      child: CachedPosterImage.fromMovie(movie),
                    );
                  },
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}
