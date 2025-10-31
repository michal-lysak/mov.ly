import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movly/features/auth/data/firestore_cloud/for_you_service.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:movly/features/movies/presentation/widgets/movie_card.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _forYouService = ForYouService();
  final _tmdbService = TMDBService();
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title:  Text(
          _currentIndex == 0 ? 'Mov.ly' : _currentIndex == 1 ? 'Discover' : 'Friends',
        style: GoogleFonts.lilyScriptOne(
          fontSize: 32,
          fontWeight: FontWeight.normal,
        ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                // TODO: Navigate to profile/settings
              },
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
        elevation: 0,
      ),
      body: _currentIndex == 0
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Section For you
                //TODO: For you page made by algorithm
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                'For you',
                style: GoogleFonts.afacad(
                    fontSize: 24,
                    //fontWeight: FontWeight.bold
                ),
                          ),
              ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 245,
                  child: Builder(
                    builder: (context) {
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId == null) {
                        return const Center(
                          child: Text(
                            'Sign in to see recommendations',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      return StreamBuilder<List<Movie>>(
                        stream: _forYouService.streamForYouList(userId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final movies = snapshot.data ?? const <Movie>[];
                          if (movies.isEmpty) {
                            return const Center(
                              child: Text(
                                'No recommendations yet',
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            scrollDirection: Axis.horizontal,
                            itemCount: movies.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 5),
                            itemBuilder: (context, index) {
                              final m = movies[index];
                              final String yearStr = (m.releaseDate.isNotEmpty && m.releaseDate.contains('-'))
                                  ? m.releaseDate.split('-').first
                                  : (m.releaseDate.isNotEmpty ? m.releaseDate : '');
                              final String posterUrl = m.posterPath.isNotEmpty
                                  ? 'https://image.tmdb.org/t/p/w342${m.posterPath}'
                                  : 'https://via.placeholder.com/286x324.png?text=No+Image';

                              return MovieCard(
                                title: m.title,
                                posterUrl: posterUrl,
                                year: int.tryParse(yearStr) ?? 0,
                                category: 'Recommended',
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // New - Now Trending
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'New',
                    style: GoogleFonts.afacad(
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: FutureBuilder<List<Movie>>(
                    future: _tmdbService.fetchTrendingMovies(window: 'day'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Failed to load trending movies',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }
                      final movies = snapshot.data ?? const <Movie>[];
                      if (movies.isEmpty) {
                        return const Center(
                          child: Text(
                            'No trending movies right now',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        scrollDirection: Axis.horizontal,
                        itemCount: movies.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final m = movies[index];
                          final String posterUrl = (m.posterPath.isNotEmpty)
                              ? 'https://image.tmdb.org/t/p/w342${m.posterPath}'
                              : '';
                          return AspectRatio(
                            aspectRatio: 2/3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: posterUrl.isNotEmpty
                                  ? Image.network(
                                      posterUrl,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.grey,
                                      child: const Center(
                                        child: Icon(Icons.image_not_supported, color: Colors.white54),
                                      ),
                                    ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                //Section
              ],
            ),
          ),
        )
          : _currentIndex == 1
              ? const Center(
                  child: Text(
                    'Discover coming soon',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : const Center(
                  child: Text(
                    'Friends coming soon',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.search),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: '',
          ),
        ],
      ),
    );
  }
}
