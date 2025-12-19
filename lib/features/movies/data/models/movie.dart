import 'package:hive/hive.dart';
import 'package:movly/features/movies/data/models/production_company.dart';

part 'movie.g.dart';

@HiveType(typeId: 0)
class Movie {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String overview;

  @HiveField(3)
  final String? posterPath;

  @HiveField(4)
  final String? backdropPath;

  @HiveField(5)
  final String releaseDate;

  @HiveField(6)
  final double voteAverage;

  @HiveField(7)
  final List<String> categories;

  @HiveField(8)
  final List<ProductionCompany> productionCompanies;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
    this.categories = const [],
    this.productionCompanies = const [],
  });

  factory Movie.fromJson(Map<String, dynamic> json, {Map<int, String>? genreMap}) {
    // Genre processing
    List<String> genres = [];
    if (json['genre_ids'] != null && json['genre_ids'] is List) {
      genres = (json['genre_ids'] as List)
          .map((id) {
        final genreName = genreMap?[id] ?? 'Unknown';
        return genreName == 'Science Fiction' ? 'Sci-Fi' : genreName;
      })
          .cast<String>()
          .toList();
    } else if (json['genres'] != null && json['genres'] is List) {
      genres = (json['genres'] as List)
          .map((g) {
        final genreName = g['name'] ?? 'Unknown';
        return genreName == 'Science Fiction' ? 'Sci-Fi' : genreName;
      })
          .cast<String>()
          .toList();
    }

    // Production companies
    List<ProductionCompany> companies = [];
    if (json['production_companies'] != null &&
        json['production_companies'] is List) {
      companies = (json['production_companies'] as List)
          .map((c) =>
          ProductionCompany(
            id: c['id'] as int,
            name: c['name'] ?? 'Unknown',
          ))
          .toList();
    }

    return Movie(
      id: json['id'] as int,
      title: json['title'] ?? 'Untitled',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      releaseDate: json['release_date'] ?? 'Unknown',
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      categories: genres,
      productionCompanies: companies, // typed correctly
    );
  }



    Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'release_date': releaseDate,
      'vote_average': voteAverage,
      'categories': categories,
    };
  }

  /// Single universal image URL preference: Backdrop → Poster → Placeholder
  String get imageUrl {
    const base = 'https://image.tmdb.org/t/p';

    if (backdropPath != null && backdropPath!.isNotEmpty) {
      return '$base/w780$backdropPath'; // landscape
    }

    if (posterPath != null && posterPath!.isNotEmpty) {
      return '$base/w342$posterPath'; // portrait fallback
    }

    return 'https://via.placeholder.com/600x400?text=No+Image';
  }

  /// Forces using backdrop only, fallback to poster, finally placeholder
  String get backdropUrl {
    const base = 'https://image.tmdb.org/t/p';

    if (backdropPath != null && backdropPath!.isNotEmpty) {
      return '$base/w780$backdropPath';
    }

    if (posterPath != null && posterPath!.isNotEmpty) {
      return '$base/w342$posterPath';
    }

    return 'https://via.placeholder.com/1280x720?text=No+Backdrop';
  }

  String get cardImageUrl {
    const base = 'https://image.tmdb.org/t/p/w780';

    if (backdropPath != null && backdropPath!.isNotEmpty) {
      return '$base$backdropPath';
    }

    // fallback if no backdrop exists
    return 'https://via.placeholder.com/1280x720?text=No+Backdrop';
  }

  /// Forces using poster only, fallback to backdrop, then placeholder
  String get posterUrl {
    const base = 'https://image.tmdb.org/t/p';

    if (posterPath != null && posterPath!.isNotEmpty) {
      return '$base/w342$posterPath'; // portrait
    }

    if (backdropPath != null && backdropPath!.isNotEmpty) {
      return '$base/w780$backdropPath'; // fallback landscape if no poster exists
    }

    return 'https://via.placeholder.com/400x600?text=No+Poster';
  }



  @override
  String toString() => 'Movie(id: $id, title: $title)';
}