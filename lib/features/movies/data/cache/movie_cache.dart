import 'package:hive/hive.dart';
import '../models/movie.dart';

class MovieCache {
  static const String boxName = 'movies';

  /// Save a movie (or update if exists)
  static Future<void> saveMovie(Movie movie) async {
    final box = await Hive.openBox<Movie>(boxName);
    await box.put(movie.id, movie);
  }

  /// Load a movie by ID
  static Future<Movie?> loadMovie(int id) async {
    final box = await Hive.openBox<Movie>(boxName);
    final movie = box.get(id);
    return movie;
  }

  /// Load all movies
  static Future<List<Movie>> loadAllMovies() async {
    final box = await Hive.openBox<Movie>(boxName);
    final movies = box.values.toList();
    return movies;
  }

  /// Load multiple movies by IDs
  static Future<List<Movie>> loadMoviesByIds(List<int> ids) async {
    final box = await Hive.openBox<Movie>(boxName);

    final movies = <Movie>[];
    for (final id in ids) {
      final movie = box.get(id);
      if (movie != null) movies.add(movie);
    }
    return movies;
  }


  /// Delete a movie by ID
  static Future<void> deleteMovie(int id) async {
    final box = await Hive.openBox<Movie>(boxName);
    await box.delete(id);
  }

  /// Clear all movies
  static Future<void> clearCache() async {
    final box = await Hive.openBox<Movie>(boxName);
    await box.clear();
  }
}