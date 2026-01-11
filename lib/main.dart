import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart'; // <--- 1. Import Provider
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:movly/firebase_options.dart';
import 'features/movies/data/models/movie.dart';
import 'features/movies/data/models/production_company.dart';
import 'features/social/data/favorites/data/services/favorite_service.dart';
import 'features/social/data/favorites/data/services/follow_service.dart';
import 'features/social/data/favorites/data/services/socialprofile_service.dart';
import 'features/social/data/favorites/data/cache/social_cache.dart';
import 'features/user/auth/data/firestore_cloud/user_service.dart';
import 'features/user/auth/presentation/components/auth_gate.dart';
import 'features/user/auth/presentation/pages/signup_username_page.dart';
import 'themes/dark_mode.dart';

// Import your SocialCache (adjust path if needed)
import 'package:movly/features/movies/presentation/liking_titles.dart';
import 'package:movly/features/movies/presentation/home/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Hive init
  await Hive.initFlutter();
  Hive.registerAdapter(MovieAdapter());
  Hive.registerAdapter(ProductionCompanyAdapter());
  await Hive.openBox<Movie>('movies');
  await Hive.openBox('sections');

  // Note: UserService also opens this, but opening it here doesn't hurt.
  await Hive.openBox('followingBox');

  // Initialize UserService
  final userService = UserService();
  await userService.initHive();

  runApp(
    MultiProvider(
      providers: [
        // 1. Services (The Muscles)
        Provider<UserService>.value(value: userService),
        Provider<SocialProfileService>(create: (_) => SocialProfileService()), // Add this
        Provider<FollowService>(create: (_) => FollowService()), // Add this
        Provider<FavoriteService>(create: (_) => FavoriteService()), // Add this

        // 2. State/Cache (The Brain)
        ChangeNotifierProvider<SocialCache>(
          create: (_) => SocialCache(userService.followingBox),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // 3. Removed UserService field and constructor
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mov.ly',
      theme: darkMode,
      home: AuthGate(),
      routes: {
        '/preHome': (context) => const PreHomePage(),
        // 4. Update HomePage call to remove argument
        '/home': (context) => const HomePage(),
        '/username': (context) => const SignupUsernamePage(),
      },
    );
  }
}