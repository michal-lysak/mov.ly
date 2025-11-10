class FavoriteMovieRef {
  final int movieId;
  final List<String> keywords;
  final DateTime favoritedAt;

  FavoriteMovieRef({
    required this.movieId,
    required this.keywords,
    required this.favoritedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': movieId,
    'keywords': keywords,
    'favoritedAt': favoritedAt.toIso8601String(),
  };

  factory FavoriteMovieRef.fromMap(Map<String, dynamic> map) => FavoriteMovieRef(
    movieId: map['id'],
    keywords: List<String>.from(map['keywords']),
    favoritedAt: DateTime.parse(map['favoritedAt']),
  );
}

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
