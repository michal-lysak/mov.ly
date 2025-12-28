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
  final ScrollController _scrollController = ScrollController();
  final tmdbService = TMDBService();

  List<Movie> searchResults = [];
  List<Movie> categoryMovies = [];

  bool isSearchMode = false;
  bool isLoadingSearch = false;
  bool isLoadingCategory = false;
  bool isLoadingMore = false;

  int _currentPage = 1;
  String? _currentCategory;

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

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 300 &&
          !isLoadingMore &&
          !isSearchMode) {
        _fetchCategoryMovies(_currentCategory, loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // -----------------------
  // CATEGORY FETCHING (PAGED)
  // -----------------------
  Future<void> _fetchCategoryMovies(
      String? category, {
        bool loadMore = false,
      }) async {
    if (isSearchMode) return;

    if (!loadMore) {
      _currentPage = 1;
      categoryMovies.clear();
      setState(() => isLoadingCategory = true);
    } else {
      setState(() => isLoadingMore = true);
    }

    _currentCategory = category;

    List<Movie> results;

    if (category == null) {
      results = await tmdbService.fetchPopularMovies(page: _currentPage);
    } else {
      final id = genreIds[category];
      results = id != null
          ? await tmdbService.fetchMoviesByGenre(id, page: _currentPage)
          : [];
    }

    if (!mounted) return;

    setState(() {
      categoryMovies.addAll(results);
      _currentPage++;
      isLoadingCategory = false;
      isLoadingMore = false;
    });
  }

  // -----------------------
  // SEARCH
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
  // UI
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

                  // Search bar
                  SearchingBar(
                    controller: searchController,
                    onChanged: _onSearchChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            if (!isSearchMode)
              HorizontalScrolling_Categories(
                onCategoryChanged: _fetchCategoryMovies,
              ),

            const SizedBox(height: 10),

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

  Widget _buildSearchResults() {
    if (isLoadingSearch) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchResults.isEmpty) {
      return const Center(child: Text("No movies found"));
    }

    return SingleChildScrollView(
      child: VerticalMovieGrid(movies: searchResults),
    );
  }

  Widget _buildCategoryView() {
    if (isLoadingCategory && categoryMovies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      controller: _scrollController,
      children: [
        VerticalMovieGrid(
          movies: categoryMovies,
          allowSelection: true,
        ),
        if (isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        const SizedBox(height: 40),
      ],
    );
  }
}
