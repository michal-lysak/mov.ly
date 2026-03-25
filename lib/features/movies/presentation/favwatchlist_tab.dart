import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:movly/features/movies/presentation/widgets/vertical_movies_grid.dart';
import 'package:movly/features/social/data/favorites/data/services/favorite_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavwatchlistTab extends StatefulWidget {
  const FavwatchlistTab({super.key});

  @override
  State<FavwatchlistTab> createState() => _FavwatchlistTabState();
}

class _FavwatchlistTabState extends State<FavwatchlistTab> {
  int _index = 0; // 0 = Favorites, 1 = Watchlist
  final user = FirebaseAuth.instance.currentUser!;
  final FavoriteService _favoriteService = FavoriteService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Your Favorites',
          style: GoogleFonts.afacad(fontSize: 22),
        ),
      ),
      body: Column(
        children: [
          // --- Buttons Row ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _index = 0),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: _index == 0
                            ? Theme.of(context).colorScheme.tertiary // selected button dark
                            : Theme.of(context).colorScheme.secondary, // unselected button darker
                        foregroundColor: Colors.white, // text stays readable
                      ),
                      child: const Text('Favorites'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _index = 1),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: _index == 1
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Watchlist'),
                    ),
                  ),
                ],
              ),
            ),

          // --- Movie Grid ---
          Expanded(
            child: StreamBuilder<Map<String, List<Movie>>>(
              stream: _favoriteService.streamUserLists(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final favorites = snapshot.data!['favorites']!;
                final watchlist = snapshot.data!['watchlist']!;

                final movies = _index == 0 ? favorites : watchlist;

                if (movies.isEmpty) {
                  return const Center(child: Text('No movies found'));
                }

                return ListView(padding: const EdgeInsets.all(20), children: [ VerticalMovieGrid(movies: movies) ]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
