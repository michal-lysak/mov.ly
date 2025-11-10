// Favorite movie reference, global database counter for each movie
class FavoriteMovieRef {
  final int movieId;
  final List<String> keywords;

  FavoriteMovieRef({
    required this.movieId,
    required this.keywords,
  });

  Map<String, dynamic> toMap() => {
    'id': movieId,
    'keywords': keywords,
  };

  factory FavoriteMovieRef.fromMap(Map<String, dynamic> map) => FavoriteMovieRef(
    movieId: map['id'],
    keywords: List<String>.from(map['keywords']),
  );
}

// User's personal database, favorite movies
class FavoriteMoviesProfile {
  final bool isPublic;
  final List<FavoriteMovieRef> favorites;

  FavoriteMoviesProfile({
    required this.isPublic,
    required this.favorites,
  });

  factory FavoriteMoviesProfile.fromMap(Map<String, dynamic> map) {
    return FavoriteMoviesProfile(
      isPublic: map['isPublic'] ?? true,
      favorites: (map['favorites'] as List<dynamic>? ?? [])
          .map((e) => FavoriteMovieRef.fromMap(e))
          .toList(),
    );
  }
}
