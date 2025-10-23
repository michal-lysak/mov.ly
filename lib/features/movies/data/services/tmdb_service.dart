import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TMDBService {
  final String _baseUrl = 'https://api.themoviedb.org/3';
  final String? _apiKey = dotenv.env['TMDB_API_KEY'];

  Future<List<Movie>> fetchPopularMovies() async {
    final response = await http.get(
        Uri.parse('$_baseUrl/movie/popular?api_key=$_apiKey')
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['results'];
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load popular movies');
    }

  }
}