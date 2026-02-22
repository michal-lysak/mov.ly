import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../social/data/favorites/data/cache/social_cache.dart';
import '../../../social/data/favorites/data/services/favorite_service.dart';
import '../../../social/data/favorites/data/services/follow_service.dart';
import '../../../social/tabs/social_tab.dart';
import '../../../social/tabs/user_profile_tab.dart';
import '../../../user/auth/data/firestore_cloud/user_service.dart';

import '../discover/discover_tab.dart';
import '../widgets/navbar_btn.dart';
import 'home_tab.dart';
import 'personal_liked_movies_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _index = 0;

  String? _currentUserUsername;
  bool _isLoadingUsername = true;

  Widget? _currentProfileTab;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAppData());
  }

  Future<void> _initAppData() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      if (mounted) setState(() => _isLoadingUsername = false);
      return;
    }

    try {
      final userService = context.read<UserService>();
      final userDoc = await userService.getUser(firebaseUser.uid);
      final username = userDoc?.data()?['username'] as String?;

      if (!mounted) return;

      setState(() {
        _currentUserUsername = username;
        _isLoadingUsername = false;
      });

      if (username == null || username.isEmpty) return;

      _startBackgroundSync(username);
    } catch (e) {
      debugPrint('Error initializing app data: $e');
      if (mounted) setState(() => _isLoadingUsername = false);
    }
  }

  void _startBackgroundSync(String myUsername) {
    final socialCache = context.read<SocialCache>();
    final followService = context.read<FollowService>();
    final favoriteService = context.read<FavoriteService>();

    socialCache.syncFriendsData(
      myUsername: myUsername,
      followService: followService,
      favoriteService: favoriteService,
    );

    followService.listenToFollowing(
      myUsername: myUsername,
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

  void _openUserProfile(String username) {
    final myUsername = _currentUserUsername;
    if (myUsername == null || myUsername.isEmpty) return;

    setState(() {
      _currentProfileTab = UserProfileTab(
        username: username,
        currentUserUsername: myUsername,
        onBack: () => setState(() => _currentProfileTab = null),
      );
      _index = 2;
    });
  }

  Future<bool> _onWillPop() async {
    if (_currentProfileTab != null) {
      setState(() => _currentProfileTab = null);
      return false;
    }
    if (_index != 0) {
      setState(() => _index = 0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoadingUsername) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final pages = <Widget>[
      HomeTab(onOpenLiked: _openLikedMovies),
      const DiscoverPage(),
      _currentProfileTab ??
          SocialTab(
            currentUserUsername: _currentUserUsername ?? '',
            onUserTap: _openUserProfile,
          ),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        extendBody: true,
        body: IndexedStack(
          index: _index,
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
                  selected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
                NavIcon(
                  iconLine: 'lib/assets/icons/compass-2-line.svg',
                  iconSolid: 'lib/assets/icons/compass-2.svg',
                  selected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
                NavIcon(
                  iconLine: 'lib/assets/icons/users-line.svg',
                  iconSolid: 'lib/assets/icons/users.svg',
                  selected: _index == 2,
                  onTap: () => setState(() {
                    if (_index == 2 && _currentProfileTab != null) {
                      _currentProfileTab = null;
                    }
                    _index = 2;
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
