import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:movly/features/auth/data/firestore_cloud/user_service.dart';
import 'package:movly/features/auth/data/profile_picture_service.dart';
import '../components/my_textfield.dart';

class SignupUsernamePage extends StatefulWidget {
  const SignupUsernamePage({super.key});

  @override
  State<SignupUsernamePage> createState() => _SignupUsernamePageState();
}

class _SignupUsernamePageState extends State<SignupUsernamePage> {
  final UserService userService = UserService();
  final ProfilePictureService _pfpService = ProfilePictureService();

  // Changed to non-final so we can update them
  bool _isUploading = false;
  String? _currentPhotoUrl;
  String? errorMessage;

  final usernameController = TextEditingController();

  /// Picks and uploads the image to Cloudinary
  Future<void> _handleImageUpdate() async {
    final dynamic image = await _pfpService.pickImage();
    if (image == null) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      setState(() => errorMessage = "User not logged in");
      return;
    }

    setState(() {
      _isUploading = true;
      errorMessage = null;
    });

    try {
      // Upload image to Cloudinary
      final uploadedUrl = await _pfpService.uploadAndSaveImage(
        userId: firebaseUser.uid,
        file: image,
      );

      if (uploadedUrl != null) {
        setState(() {
          _currentPhotoUrl = uploadedUrl;
        });
      } else {
        setState(() {
          errorMessage = "Failed to upload image.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Upload failed: $e";
      });
    } finally {
      setState(() {
        _isUploading = false; // Always turn off the loader
      });
    }
  }


  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: SingleChildScrollView( // Added to prevent overflow on small screens
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Set up your profile',
                  style: GoogleFonts.afacad(
                      fontWeight: FontWeight.bold, fontSize: 24),
                ),

                const SizedBox(height: 30),

                // --- PROFILE PICTURE SECTION ---
                GestureDetector(
                  onTap: _isUploading ? null : _handleImageUpdate,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                        backgroundImage: _currentPhotoUrl != null
                            ? NetworkImage(_currentPhotoUrl!)
                            : null,
                        child: _currentPhotoUrl == null && !_isUploading
                            ? Icon(Icons.add_a_photo, size: 30, color: Theme.of(context).colorScheme.primary)
                            : null,
                      ),
                      if (_isUploading)
                        const SizedBox(
                          height: 100,
                          width: 100,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Choose a profile picture",
                  style: GoogleFonts.afacad(fontSize: 14, color: Colors.grey),
                ),
                // -------------------------------

                const SizedBox(height: 30),

                MyTextField(
                  controller: usernameController,
                  hintText: 'Username',
                  obscureText: false,
                ),

                const SizedBox(height: 20),

                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      errorMessage!,
                      style: GoogleFonts.afacad(color: Colors.red),
                    ),
                  ),

                GestureDetector(
                  onTap: () async {
                    if (_isUploading) return; // Prevent continue while uploading

                    final firebaseUser = FirebaseAuth.instance.currentUser;
                    if (firebaseUser == null) return;

                    try {
                      final username = usernameController.text.trim();
                      if (username.isEmpty) {
                        setState(() => errorMessage = 'Username cannot be empty.');
                        return;
                      }

                      // Check if username is available first
                      bool available = await userService.isUsernameAvailable(username);
                      if (!available) {
                        setState(() => errorMessage = 'Username is already taken.');
                        return;
                      }

                      // Attempt to set the username in Firestore
                      // This now creates the document in /usernames and /users
                      await userService.setUsername(
                        firebaseUser.uid,
                        username,
                        _currentPhotoUrl,
                      );

                      if (mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/preHome', (route) => false);
                      }

                    } catch (e) {
                      setState(() {
                        errorMessage = e.toString().replaceFirst('Exception: ', 'Error: ');
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _isUploading
                          ? Colors.grey
                          : Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'Continue',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.afacad(
                            fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}