import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movly/features/auth/data/firestore_cloud/for_you_service.dart';
import 'package:movly/features/movies/data/models/movie.dart';
import 'package:movly/features/movies/presentation/widgets/movie_card.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _forYouService = ForYouService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title:  Text(
          'Mov.ly',
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
      body: SingleChildScrollView(
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

                //Section
            ],
          ),
      ),
    ),
    );
  }
}
