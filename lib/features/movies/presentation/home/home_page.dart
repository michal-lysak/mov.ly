import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// Services
import '../../../social/data/favorites/data/services/favorite_service.dart';
import '../../../social/data/favorites/data/services/follow_service.dart';
import '../../../user/auth/data/firestore_cloud/user_service.dart';
import '../../../social/data/favorites/data/cache/social_cache.dart';

// Tabs & Pages
import '../../../social/tabs/social_tab.dart';
import '../../../social/tabs/user_profile_tab.dart';
import '../discover/discover_tab.dart';
import '../widgets/navbar_btn.dart';
import 'personal_liked_movies_page.dart';
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
  String? currentUserUsername;
  bool isLoadingUsername = true;
  Widget? _currentProfileTab;

  @override
  void initState() {
    super.initState();
    // Start the initialization process once the first frame is done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAppData();
    });
  }

  /// ✅ Unified Initialization Logic
  /// 1. Fetches the current username immediately to unblock the UI.
  /// 2. Triggers the heavy social sync in the background.
  /// ✅ Unified Initialization Logic
  /// 1. Fetches the current username immediately to unblock the UI.
  /// 2. Triggers the heavy social sync in the background.
  Future<void> _initAppData() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      if (mounted) setState(() => isLoadingUsername = false);
      return;
    }

    try {
      // 1. Fetch the user profile (Username)
      // We use the UserService directly or Firestore
      final userService = context.read<UserService>();
      final userDoc = await userService.getUser(firebaseUser.uid);
      final username = userDoc?.data()?['username'] as String?;

      // 2. Unblock the UI immediately
      if (mounted) {
        setState(() {
          currentUserUsername = username;
          isLoadingUsername = false;
        });
      }

      if (username == null) return;

      // 3. Start Background Syncs (Fire and Forget)
      _startBackgroundSync(username);

    } catch (e) {
      debugPrint("Error initializing app data: $e");
      if (mounted) setState(() => isLoadingUsername = false);
    }
  }

  /// Runs silently in the background to populate the cache
  void _startBackgroundSync(String username) {
    if (!mounted) return;

    final socialCache = context.read<SocialCache>();
    final followService = context.read<FollowService>();
    final favoriteService = context.read<FavoriteService>();

    // A. Sync existing friends & their favorites (The heavy lifting)
    // This uses the optimized "IDs only" fetch we created
    socialCache.syncFriendsData(
      myUsername: username,
      followService: followService,
      favoriteService: favoriteService,
    );

    // B. Listen for REAL-TIME new follows/unfollows
    // This keeps the list updated if you follow someone while using the app
    followService.listenToFollowing(
      myUsername: username,
      cache: socialCache,
    );
  }

  void _openLikedMovies() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonalLikedMovies(userId: userId),
      ),
    );
  }

  void openUserProfile(String username) {
    setState(() {
      _currentProfileTab = UserProfileTab(
        username: username,
        onBack: () {
          setState(() => _currentProfileTab = null);
        },
      );
      index = 2;
    });
  }

  Future<bool> _onWillPop() async {
    // If inside a sub-tab (like UserProfile inside Social), close it first
    if (_currentProfileTab != null) {
      setState(() => _currentProfileTab = null);
      return false;
    }
    // If on a tab other than Home, go back to Home
    if (index != 0) {
      setState(() => index = 0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Show loading spinner only while fetching YOUR username
    if (isLoadingUsername) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      HomeTab(onOpenLiked: _openLikedMovies),
      const DiscoverPage(),
      // If we have a specific profile open, show it, otherwise show the Social Tab
      _currentProfileTab ??
          SocialTab(
            currentUserUsername: currentUserUsername ?? '',
            onUserTap: openUserProfile,
          ),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        extendBody: true, // Allows content to go behind the blurred navbar
        body: IndexedStack(
          index: index,
          children: pages,
        ),
        bottomNavigationBar: _buildBottomNavbar(),
      ),
    );
  }

  Widget _buildBottomNavbar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 70),
        child: Container(
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
                  onTap: () => setState(() {
                    // If tapping the Social icon while already there, reset to main list
                    if (index == 2 && _currentProfileTab != null) {
                      _currentProfileTab = null;
                    }
                    index = 2;
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}