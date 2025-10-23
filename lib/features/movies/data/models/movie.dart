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

  @override
  String toString() {
    return 'Movie(id: $id, title: $title, voteAverage: $voteAverage)';
  }
}