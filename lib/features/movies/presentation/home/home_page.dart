import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movly/features/favorites/data/firestore_cloud/foryoupage_service.dart';
import 'package:movly/features/favorites/model/favorite_movie_model.dart';
import 'package:movly/features/movies/presentation/UserProfile/user_profile_tab.dart';
import 'package:movly/features/movies/presentation/home/personal_liked_movies_page.dart';
import 'package:movly/features/movies/presentation/social/social_tab.dart';
import '../../data/models/movie.dart';
import 'package:movly/features/movies/presentation/widgets/movie_card.dart';
import 'package:movly/features/movies/data/services/tmdb_service.dart';
import 'package:movly/features/movies/presentation/widgets/navbar_btn.dart';
import '../discover/discover_tab.dart';
import 'home_tab.dart';

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
  final userId = FirebaseAuth.instance.currentUser!.uid;


  // Social tab can show profile dynamically
  Widget? _currentProfileTab;

  void _openLikedMovies() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalLikedMovies(userId: userId),
      ),
    );
  }

  void openUserProfile(String username) {
    setState(() {
      _currentProfileTab = UserProfileTab(
        username: username, // now correct
        onBack: () {
          setState(() {
            _currentProfileTab = null; // go back to SocialTab
          });
        },
      );
      index = 2; // switch to SocialTab position
    });
  }


  // Custom function to handle back button press on the HomePage/App Exit
  Future<bool> _onWillPop() async {
    if (index != 0) {
      setState(() {
        index = 0;
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final pages = [
      HomeTab(onOpenLiked: _openLikedMovies),
      const DiscoverPage(),
      _currentProfileTab ?? SocialTab(onUserTap: openUserProfile),
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
