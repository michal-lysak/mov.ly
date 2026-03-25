import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


import 'package:image_picker/image_picker.dart';

import '../../../user/auth/data/profile_picture_service.dart';



class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();


  bool _isSaving = false;

  // Profile picture
  final ProfilePictureService _pfpService = ProfilePictureService();
  String? _photoUrl;
  bool _isUploading = false;

  String? _oldUsername;


  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // DISPOSE controllers to free up memory
  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleImageUpdate() async {
    final dynamic image = await _pfpService.pickImage();
    if (image == null) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final uploadedUrl = await _pfpService.uploadAndSaveImage(
        userId: firebaseUser.uid,
        file: image,
      );

      if (uploadedUrl != null) {
        // Update Firestore with new photo URL
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .update({'photoUrl': uploadedUrl});

        if (mounted) {
          setState(() {
            _photoUrl = uploadedUrl;
          });
        }
      }
    } catch (e) {
      debugPrint("Upload failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }


  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) return;

      final data = doc.data();

      // FIXED: Wrap in setState so UI updates
      if (mounted) {
        setState(() {
          _nameController.text = data?['name'] ?? '';
          _usernameController.text = data?['username'] ?? '';
          _photoUrl = data?['photoUrl'];

          _oldUsername = data?['username'];
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = _photoUrl != null && _photoUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        title: Text(
          "Edit Profile",
          style: GoogleFonts.afacad(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        actions: [
          TextButton(
          onPressed: (_isSaving || _isUploading) ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Text(
              "Done",
              style: GoogleFonts.afacad(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _isUploading ? null : _handleImageUpdate,
                child:Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: hasImage ? NetworkImage(_photoUrl!) : null,
                      child: !hasImage && !_isUploading
                          ? const Icon(Icons.person, size: 45, color: Colors.grey)
                          : null,
                    ),
                    if (_isUploading)
                      const SizedBox(
                        height: 90,
                        width: 90,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),

              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      style: GoogleFonts.afacad(fontSize: 18, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: "Your name",
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _usernameController,
                      style: GoogleFonts.afacad(fontSize: 15, color: Colors.grey),
                      decoration: const InputDecoration(
                        hintText: "username",
                        prefixText: "@",
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Opacity(
              opacity: 0.1,
              child: const Divider()),

          Center(
            child:
            Text(
                'Tap on the item you want to edit',
                 style: TextStyle(
                   color: Colors.grey
                 )
            )
          )
        ],
      ),
    );
  }

  void _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final newUsername = _usernameController.text.trim().toLowerCase();

    setState(() => _isSaving = true);

    try {
      final firestore = FirebaseFirestore.instance;

      // 🔒 Check if username changed
      if (_oldUsername != newUsername) {
        // 1. Check if new username already exists
        final usernameDoc =
        await firestore.collection('usernames').doc(newUsername).get();

        if (usernameDoc.exists) {
          throw Exception("Username already taken");
        }

        // 2. Delete old username
        if (_oldUsername != null && _oldUsername!.isNotEmpty) {
          await _moveSubcollections(_oldUsername!, newUsername);
          await firestore.collection('usernames').doc(_oldUsername).delete();
        }

        // 3. Create new username
        await firestore.collection('usernames').doc(newUsername).set({
          'uid': uid,
          'username': newUsername,
          'name': _nameController.text.trim(),
          'photoUrl': _photoUrl ?? '',
        });
      }

      // 4. Update user document
      await firestore.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'username': newUsername,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error saving profile: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _moveSubcollections(
      String oldUsername,
      String newUsername,
      ) async {
    final firestore = FirebaseFirestore.instance;

    final oldRef = firestore.collection('usernames').doc(oldUsername);
    final newRef = firestore.collection('usernames').doc(newUsername);

    final subcollections = ['followers', 'following'];

    for (final sub in subcollections) {
      final oldSub = oldRef.collection(sub);
      final newSub = newRef.collection(sub);

      final snapshot = await oldSub.get();

      for (final doc in snapshot.docs) {
        await newSub.doc(doc.id).set(doc.data());
      }
    }
  }

}