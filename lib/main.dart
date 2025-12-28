import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:movly/features/auth/presentation/pages/signup_username_page.dart';
import 'package:movly/features/movies/presentation/liking_titles.dart'; // PreHomePage
import 'package:movly/features/movies/presentation/home/home_page.dart';
import 'package:movly/firebase_options.dart';
import 'features/auth/data/firestore_cloud/user_service.dart';
import 'features/auth/presentation/components/auth_gate.dart';
import 'features/movies/data/models/movie.dart';
import 'features/movies/data/models/production_company.dart';
import 'themes/dark_mode.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  await Hive.openBox('followingBox');

  // Initialize UserService
  final userService = UserService();
  await userService.initHive();

  runApp(MyApp(userService: userService));
}

class MyApp extends StatelessWidget {
  final UserService userService;
  const MyApp({super.key, required this.userService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mov.ly',
      theme: darkMode,

      // AuthGate decides whether user is logged in or not
      home: AuthGate(),

      routes: {
        '/preHome': (context) => const PreHomePage(),
        '/home': (context) => HomePage(userService: userService),
        '/username': (context) => const SignupUsernamePage(),
      },
    );
  }
}
