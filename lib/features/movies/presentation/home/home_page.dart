import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/data/firestore_cloud/user_service.dart';
import '../UserProfile/user_profile_tab.dart';
import '../discover/discover_tab.dart';
import '../social/social_tab.dart';
import '../widgets/navbar_btn.dart';
import 'personal_liked_movies_page.dart';
import 'home_tab.dart';

class HomePage extends StatefulWidget {
  final UserService userService;
  const HomePage({super.key, required this.userService});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int index = 0;

  // Current user's username (fetched from Firestore)
  String? currentUserUsername;
  bool isLoadingUsername = true;

  // Social tab can show profile dynamically
  Widget? _currentProfileTab;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserUsername();
  }

  Future<void> _fetchCurrentUserUsername() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    setState(() {
      currentUserUsername = doc['username'];
      isLoadingUsername = false;
    });

    // Load following cache now that we have username
    await widget.userService.loadFollowingCache(currentUserUsername!);
  }

  void _openLikedMovies() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
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
        username: username,
        onBack: () {
          setState(() {
            _currentProfileTab = null; // go back to SocialTab
          });
        },
      );
      index = 2; // switch to SocialTab
    });
  }

  // Custom back button behavior
  Future<bool> _onWillPop() async {
    if (index != 0) {
      setState(() => index = 0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (isLoadingUsername) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      HomeTab(
          userService: widget.userService,
          onOpenLiked: _openLikedMovies),
      const DiscoverPage(),
      _currentProfileTab ??
          SocialTab(
            userService: widget.userService,
            currentUserUsername: currentUserUsername!,
            onUserTap: openUserProfile,
          ),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        extendBody: true,
        body: IndexedStack(
          index: index,
          children: pages,
        ),
        bottomNavigationBar: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 70.0),
            child: Container(
              width: double.infinity,
              height: 70,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.08),
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
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
        ),
      ),
    );
  }
}
