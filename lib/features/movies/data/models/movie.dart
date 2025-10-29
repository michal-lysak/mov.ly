class Movie {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final String releaseDate;
  final double voteAverage;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.releaseDate,
    required this.voteAverage,
  });

  // Factory constructor: create movie into a Movie from a JSON map
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int,
      title: (json['title'] ?? 'Untitled'),
      overview: (json['overview'] ?? '') as String,
      posterPath: (json['poster_path'] ?? '') as String,
      releaseDate: (json['release_date'] ?? 'Unknown') as String,
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
    );
  }
  // Convert Movie back to JSON (useful for caching or sending)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'release_date': releaseDate,
      'vote_average': voteAverage,
    };
  }

  /// Computed property for full poster URL
  String get posterUrl {
    if (posterPath.isEmpty) {
      return 'https://via.placeholder.com/300x450?text=No+Image';
    }
    return 'https://image.tmdb.org/t/p/w185$posterPath';
  }

  @override
  String toString() {
    return 'Movie(id: $id, title: $title, voteAverage: $voteAverage)';
  }
}