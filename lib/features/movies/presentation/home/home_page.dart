import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movly/features/favorites/data/firestore_cloud/foryoupage_service.dart';
import 'package:movly/features/favorites/model/favorite_movie_model.dart';
import 'package:movly/features/movies/presentation/home/personal_liked_movies_page.dart';
import '../../data/models/movie.dart';
import 'package:movly/features/movies/presentation/widgets/movie_card.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';
import 'package:movly/features/movies/presentation/widgets/navbar_btn.dart';
import '../discover/discover_tab.dart';
import 'home_tab.dart';

// Placeholder for the third tab (optional)
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Users/Social Tab (Placeholder)',
          style: GoogleFonts.afacad(),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int index = 0;

  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _openLikedMovies() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalLikedMovies(userId: userId),
      ),
    );
  }

  // Custom function to handle back button press on the HomePage/App Exit
  Future<bool> _onWillPop() async {
    // If we are not on the main HomeTab (index 0), switch back to it.
    if (index != 0) {
      setState(() {
        index = 0;
      });
      return false; // Prevent exit
    }
    // If we are on HomeTab (index 0), allow exit/pop to previous screen
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final pages = [
      HomeTab(onOpenLiked: _openLikedMovies),
      const DiscoverPage(),
      const PlaceholderPage(),
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: IndexedStack(
          index: index,
          children: pages,
        ),
        bottomNavigationBar: Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                NavIcon(
                  iconLine: 'lib/assets/icons/home-line.svg',
                  iconSolid: 'lib/assets/icons/home.svg',
                  selected: index == 0,
                  onTap: () => setState(() => index = 0),
                ),
                NavIcon(
                  iconLine: 'lib/assets/icons/compass-2-line.svg',
                  iconSolid: 'lib/assets/icons/compass-2.svg',
                  selected: index == 1,
                  onTap: () => setState(() => index = 1),
                ),
                NavIcon(
                  iconLine: 'lib/assets/icons/users-line.svg',
                  iconSolid: 'lib/assets/icons/users.svg',
                  selected: index == 2,
                  onTap: () => setState(() => index = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}