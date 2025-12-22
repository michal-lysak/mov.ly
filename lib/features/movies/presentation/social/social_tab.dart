import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart'; // REQUIRED
import '../../../auth/data/firestore_cloud/user_service.dart';
import 'package:movly/features/movies/presentation/widgets/searching_bar.dart';

class SocialTab extends StatefulWidget {
  // Use 'this.' to automatically initialize the final variables above
  const SocialTab({
    super.key,
    required this.userService,
    required this.onUserTap,
    required this.currentUserUsername,
  });

  final UserService userService;
  final Function(String uid) onUserTap;
  final String currentUserUsername;

  @override
  State<SocialTab> createState() => _SocialTabState();
}

class _SocialTabState extends State<SocialTab> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    widget.userService.listenToFollowingChanges(widget.currentUserUsername);
  }

  void _onChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);
    final users = await widget.userService.searchUsers(query);

    if (mounted) {
      setState(() {
        // FILTER: Remove the current user from the results list
        _results = users.where((u) => u['username'] != widget.currentUserUsername).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Row(
              children: [
                Text('Social', style: GoogleFonts.afacad(fontSize: 32, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 24),
            SearchingBar(controller: _controller, onChanged: _onChanged),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? const Center(child: Text("No users found"))
                  : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final user = _results[index];
                  final String theirUserId = user['uid'];
                  final String theirUsername = user['username'] ?? 'user';

                  return GestureDetector(
                    onTap: () => widget.onUserTap(theirUsername),
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
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundImage: (user['photoUrl'] != null && user['photoUrl'].isNotEmpty)
                                  ? NetworkImage(user['photoUrl'])
                                  : null,
                              child: (user['photoUrl'] == null || user['photoUrl'].isEmpty)
                                  ? const Icon(Icons.person, size: 18)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['name'] ?? theirUsername,
                                      style: GoogleFonts.afacad(fontSize: 17, fontWeight: FontWeight.w600)),
                                  Text("@$theirUsername",
                                      style: GoogleFonts.afacad(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            ValueListenableBuilder(
                              valueListenable: Hive.box('followingBox').listenable(),
                              builder: (context, Box box, child) {
                                final bool isFollowing = box.containsKey(theirUserId);
                                return GestureDetector(
                                  onTap: () async {
                                    if (isFollowing) {
                                      await widget.userService.unfollowUser(theirUsername, widget.currentUserUsername, theirUserId);
                                    } else {
                                      await widget.userService.followUser(theirUsername, widget.currentUserUsername, theirUserId);
                                    }
                                  },
                                  child: Container(
                                    height: 30,
                                    width: 75,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: isFollowing ? Colors.grey[700] : Theme.of(context).colorScheme.surface,
                                    ),
                                    child: Center(
                                      child: Text(isFollowing ? 'Following' : 'Follow',
                                          style: GoogleFonts.afacad(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                                    ),
                                  ),
                                );
                              },
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