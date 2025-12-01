import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/data/firestore_cloud/user_service.dart';
import '../UserProfile/user_profile_tab.dart';
import 'package:movly/features/movies/presentation/widgets/searching_bar.dart';

class SocialTab extends StatefulWidget {
  final Function(String uid) onUserTap; // callback when a user is tapped
  const SocialTab({super.key, required this.onUserTap});

  @override
  State<SocialTab> createState() => _SocialTabState();
}

class _SocialTabState extends State<SocialTab> {
  final _controller = TextEditingController();
  final _userService = UserService();

  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  void _onChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);
    final users = await _userService.searchUsers(query);

    setState(() {
      _results = users;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 20, 15, 16),
            child: Row(
              children: [
                Text(
                  'Social',
                  style: GoogleFonts.afacad(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchingBar(controller: _controller, onChanged: _onChanged),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                ? const Center(child: Text("No users found"))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final user = _results[index];
                return GestureDetector(
                  onTap: () {
                    widget.onUserTap(user['uid']); // call the callback
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user['username'] ?? "unknown",
                      style: GoogleFonts.afacad(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
