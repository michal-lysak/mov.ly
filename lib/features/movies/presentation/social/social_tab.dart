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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
        child: Column(
          children: [
            SizedBox(height: 40),

            Row(
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

            SizedBox(height: 24),
            SearchingBar(controller: _controller, onChanged: _onChanged),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? const Center(child: Text("No users found"))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(),
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final user = _results[index];
                  return GestureDetector(
                    onTap: () {
                      widget.onUserTap(user['username']);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.3),
                              backgroundImage: (user?['photoUrl'] != null &&
                                  (user!['photoUrl'] as String).isNotEmpty)
                                  ? NetworkImage(user!['photoUrl'])
                                  : null,
                              child: (user?['photoUrl'] == null ||
                                  (user!['photoUrl'] as String).isEmpty)
                                  ? const Icon(Icons.person, size: 18)
                                  : null,
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    user['name'] ?? user['username'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.afacad(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 0),
                                  Text(
                                    "@${user['username'] ?? 'user'}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.afacad(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
