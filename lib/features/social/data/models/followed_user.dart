class FollowedUser {
  final String uid;
  final String username;
  final String name;
  final String photoUrl;
  final List<int> favMovieIds;

  const FollowedUser({
    required this.uid,
    required this.username,
    required this.name,
    required this.photoUrl,
    required this.favMovieIds,
  });

  factory FollowedUser.fromHive(String uid, Map data) {
    return FollowedUser(
      uid: uid,
      username: data['username'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      favMovieIds: List<int>.from(
        (data['favMovies'] ?? []).map((m) => m['id']),
      ),
    );
  }

  Map<String, dynamic> toHive() {
    return {
      'username': username,
      'name': name,
      'photoUrl': photoUrl,
      'favMovies': favMovieIds.map((id) => {'id': id}).toList(),
    };
  }

  bool get hasFavorites => favMovieIds.isNotEmpty;
  String get displayName => name.isNotEmpty ? name : username;
}
