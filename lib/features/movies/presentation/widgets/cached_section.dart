class CachedSection {
  final List<int> movieIds;
  final int cachedAt;

  CachedSection({
    required this.movieIds,
    required this.cachedAt,
  });

  Map<String, dynamic> toJson() => {
    'movieIds': movieIds,
    'cachedAt': cachedAt,
  };

  factory CachedSection.fromJson(Map<String, dynamic> json) {
    return CachedSection(
      movieIds: List<int>.from(json['movieIds']),
      cachedAt: json['cachedAt'],
    );
  }
}
