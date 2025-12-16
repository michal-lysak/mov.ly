import 'package:hive/hive.dart';
import '../models/movie.dart';

class MovieCache {
  static const String boxName = 'movies';

  /// Save a movie (or update if exists)
  static Future<void> saveMovie(Movie movie) async {
    final box = await Hive.openBox<Movie>(boxName);
    await box.put(movie.id, movie);
    await box.close();
  }

  /// Load a movie by ID
  static Future<Movie?> loadMovie(int id) async {
    final box = await Hive.openBox<Movie>(boxName);
    final movie = box.get(id);
    await box.close();
    return movie;
  }

  /// Load all movies
  static Future<List<Movie>> loadAllMovies() async {
    final box = await Hive.openBox<Movie>(boxName);
    final movies = box.values.toList();
    await box.close();
    return movies;
  }

  /// Delete a movie by ID
  static Future<void> deleteMovie(int id) async {
    final box = await Hive.openBox<Movie>(boxName);
    await box.delete(id);
    await box.close();
  }

  /// Clear all movies
  static Future<void> clearCache() async {
    final box = await Hive.openBox<Movie>(boxName);
    await box.clear();
    await box.close();
  }
}