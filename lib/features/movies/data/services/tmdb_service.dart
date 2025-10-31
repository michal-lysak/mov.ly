import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TMDBService {
  final String _baseUrl = 'https://api.themoviedb.org/3';
  final String? _apiKey = dotenv.env['TMDB_API_KEY'];

  Future<List<Movie>> fetchTrendingMovies({String window = 'day', int page = 1}) async {
    // window can be 'day' or 'week'
    final response = await http.get(
      Uri.parse('$_baseUrl/trending/movie/$window?api_key=$_apiKey&page=$page'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['results'];
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load trending movies: ${response.statusCode}');
    }
  }

  Future<List<Movie>> fetchPopularMovies({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movie/popular?api_key=$_apiKey&page=$page'),
    );


    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['results'];
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load popular movies: ${response.statusCode}');
    }
  }



  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    if (query.isEmpty) return [];

    final encodedQuery = Uri.encodeComponent(query);
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/search/movie?api_key=$_apiKey&query=$encodedQuery&page=$page',
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['results'];
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search movies: ${response.statusCode}');
    }
  }

  Future<List<Movie>> fetchSimilarMovies(int movieId, {int page = 1}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movie/$movieId/similar?api_key=$_apiKey&page=$page'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['results'];
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load similar movies: ${response.statusCode}');
    }
  }
}