import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movly/features/movies/presentation/account/profile-settings_tab.dart';
import 'package:movly/features/user/auth/data/firebase_auth_repo.dart';

class PersonalLikedMovies extends StatefulWidget {
  final String userId;


  PersonalLikedMovies({
    super.key,
    required this.userId,
  });

  @override
  State<PersonalLikedMovies> createState() => _PersonalLikedMoviesState();
}

class _PersonalLikedMoviesState extends State<PersonalLikedMovies> {
  bool _isPublicFavorites = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySetting();
  }

  Future<void> _loadPrivacySetting() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('favoritesperuser')
          .doc(widget.userId);

      final doc = await docRef.get();

      if (!doc.exists) {
        // Create document with default value
        await docRef.set(
          {'isPublic': true},
          SetOptions(merge: true),
        );

        setState(() {
          _isPublicFavorites = true;
        });

        return;
      }

      final data = doc.data();
      final isPublic = data?['isPublic'];

      if (isPublic is bool) {
        setState(() {
          _isPublicFavorites = isPublic;
        });
      } else {
        // Field missing → initialize it safely
        await docRef.set(
          {'isPublic': true},
          SetOptions(merge: true),
        );

        setState(() {
          _isPublicFavorites = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading privacy setting: $e');
    }
  }

  final FirebaseAuthRepo firebaseAuthRepo = FirebaseAuthRepo();
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Your Account',
          style: GoogleFonts.afacad(fontSize: 22),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [

          /// ---------------- PROFILE SETTINGS ----------------
          _buildSection(
            context,
            child: GestureDetector(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(
                  'Profile settings',
                  style: GoogleFonts.afacad(fontSize: 18),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                },

              ),
              //TODO: onTap
            ),
          ),

          const SizedBox(height: 16),

          /// ---------------- PRIVACY SECTION ----------------
          _buildSection(
            context,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(
                    'Privacy',
                    style: GoogleFonts.afacad(fontSize: 18),
                  ),
                ),
                const Divider(height: 1),

                SwitchListTile(
                  title: Text(
                    'Public liked movies',
                    style: GoogleFonts.afacad(fontSize: 16),
                  ),
                  subtitle: Text(
                    'Other users can see your favorites',
                    style: GoogleFonts.afacad(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  value: _isPublicFavorites,
                  onChanged: (value) async {
                    setState(() => _isPublicFavorites = value);

                    try {
                      await FirebaseFirestore.instance
                          .collection('favoritesperuser')
                          .doc(widget.userId)
                          .set(
                        {'isPublic': value},
                        SetOptions(merge: true),
                      );
                    } catch (e) {
                      debugPrint("Error updating privacy setting: $e");
                    }
                  },

                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          /// ---------------- DELETE ACCOUNT ----------------
          _buildSection(
            context,
            color: Colors.grey.withOpacity(0.1),
            child: ListTile(
              leading: const Icon(Icons.output, color: Colors.grey),
              title: Text(
                'Log out',
                style: GoogleFonts.afacad(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              onTap: () async {
                try {
                  await firebaseAuthRepo.logout();

                  if (!mounted) return;

                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                        (route) => false,
                  );
                } catch (e) {
                  debugPrint("Logout error: $e");
                }
              },

            ),
          ),
          SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: _showDeleteDialog,
              child: Text(
                'Delete account',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.red, // optional but recommended
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )

        ],
      ),
    );
  }

  /// Reusable rounded section container
  Widget _buildSection(
      BuildContext context, {
        required Widget child,
        Color? color,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This action is permanent and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              // TODO:
              // 1. Delete user document from Firestore
              // 2. Delete auth account
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
