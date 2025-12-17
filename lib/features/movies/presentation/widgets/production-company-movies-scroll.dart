import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:movly/features/movies/data/models/production_company.dart';
import 'package:movly/features/movies/presentation/widgets/vertical_movies_grid.dart';

// Imports
import '../../data/models/movie.dart';

class CompanyMoviesSection extends StatefulWidget {
  final int movieId;
  final List<ProductionCompany> productionCompanies;

  const CompanyMoviesSection({
    super.key,
    required this.movieId,
    required this.productionCompanies,
  });

  @override
  State<CompanyMoviesSection> createState() => _CompanyMoviesSectionState();
}

class _CompanyMoviesSectionState extends State<CompanyMoviesSection> {
  List<Movie> _companyMovies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanyMovies();
  }

  Future<void> _loadCompanyMovies() async {
    if (widget.productionCompanies.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final companyId = widget.productionCompanies.first.id;
      final apiKey = dotenv.env['TMDB_API_KEY'];
      final url =
          "https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&with_companies=$companyId";

      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        final results = jsonData["results"] as List;

        // Convert raw JSON to Movie objects
        final List<Movie> mappedMovies = results
            .map((data) => Movie.fromJson(data))
            .where((m) => m.id != widget.movieId) // Optional: remove current movie
            .toList();

        if (mounted) {
          setState(() {
            _companyMovies = mappedMovies;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint("Error loading company movies: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_companyMovies.isEmpty) {
      return const SizedBox.shrink();
    }

    return VerticalMovieGrid(
      movies: _companyMovies,
    );
  }
}