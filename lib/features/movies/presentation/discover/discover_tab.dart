import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';
import '../widgets/searching_bar.dart';
import 'package:movly/features/movies/presentation/widgets/h-categories.dart';
import '../widgets/vertical_movies_grid.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final TextEditingController searchController = TextEditingController();
  final tmdbService = TMDBService();

  List<Movie> searchResults = [];
  List<Movie> categoryMovies = [];

  // FIXED STATE MANAGEMENT
  bool isSearchMode = false;
  bool isLoadingSearch = false;
  bool isLoadingCategory = false;

  final Map<String, int> genreIds = {
    "Action": 28,
    "Adventure": 12,
    "Animation": 16,
    "Comedy": 35,
    "Crime": 80,
    "Documentary": 99,
    "Drama": 18,
    "Family": 10751,
    "Fantasy": 14,
    "History": 36,
    "Horror": 27,
    "Music": 10402,
    "Mystery": 9648,
    "Romance": 10749,
    "Sci-Fi": 878,
    "TV Movie": 10770,
    "Thriller": 53,
    "War": 10752,
    "Western": 37,
  };

  @override
  void initState() {
    super.initState();
    _fetchCategoryMovies(null);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // -----------------------
  // CATEGORY FETCHING
  // -----------------------
  Future<void> _fetchCategoryMovies(String? category) async {
    if (isSearchMode) return;

    setState(() => isLoadingCategory = true);

    List<Movie> results;

    if (category == null) {
      results = await tmdbService.fetchPopularMovies();
    } else {
      final id = genreIds[category];
      results = id != null ? await tmdbService.fetchMoviesByGenre(id) : [];
    }

    if (!mounted) return;

    setState(() {
      categoryMovies = results;
      isLoadingCategory = false;
    });
  }

  // -----------------------
  // SEARCH HANDLING
  // -----------------------
  void _onSearchChanged(String value) async {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      setState(() {
        isSearchMode = false;
        searchResults = [];
      });

      _fetchCategoryMovies(null);
      return;
    }

    setState(() {
      isSearchMode = true;
      isLoadingSearch = true;
    });

    final results = await tmdbService.searchMovies(trimmed);

    if (!mounted) return;

    setState(() {
      searchResults = results;
      isLoadingSearch = false;
    });
  }

  // -----------------------
  // BUILD UI
  // -----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const SizedBox(height: 40),
              Text(
                'Discover',
                style: GoogleFonts.afacad(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // Search Bar
              SearchingBar(
                controller: searchController,
                onChanged: _onSearchChanged,
              ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Categories only visible when not searching
            if (!isSearchMode)
              HorizontalScrolling_Categories(
                onCategoryChanged: _fetchCategoryMovies,
              ),

            if (!isSearchMode) const SizedBox(height: 10),

            // Main content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child:
                    isSearchMode ? _buildSearchResults() : _buildCategoryView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------
  // SEARCH RESULTS VIEW
  // -----------------------
  Widget _buildSearchResults() {
    if (isLoadingSearch) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchResults.isEmpty) {
      return Center(
        child: Text(
          "No movies found",
          style: GoogleFonts.afacad(fontSize: 18),
        ),
      );
    }

    return SingleChildScrollView(
      child: VerticalMovieGrid(movies: searchResults),
    );
  }

  // -----------------------
  // CATEGORY VIEW
  // -----------------------
  Widget _buildCategoryView() {
    return RefreshIndicator(
      onRefresh: () async => _fetchCategoryMovies(null),
      child: isLoadingCategory
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(top: 10),
              children: [
                VerticalMovieGrid(
                  movies: categoryMovies,
                  allowSelection: true,
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}
