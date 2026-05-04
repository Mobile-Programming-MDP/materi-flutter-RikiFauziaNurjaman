import 'package:cepu_app/screens/add_post_screen.dart';
import 'package:cepu_app/screens/sign_screen.dart';
import 'package:cepu_app/service/post_service.dart';
import 'package:cepu_app/widget/post_list_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // testSetUser();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
      (route) => false,
    );
  }

  String generateAvatarUrl(String? fullName) {
    final name = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName
        : 'User';
    final formattedName = name.trim().replaceAll(' ', '+');
    return 'https://ui-avatars.com/api/?name=$formattedName&color=FFFFFF&background=000000';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Screen"),
        actions: [
          IconButton(
            onPressed: () {
              signOut();
            },
            icon: Icon(Icons.logout),
            tooltip: "Sign Out",
          ),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 8.0),
          Image.network(
            generateAvatarUrl(
              FirebaseAuth.instance.currentUser?.displayName ??
                  FirebaseAuth.instance.currentUser?.email,
            ),
            width: 80,
            height: 80,
          ),
          const SizedBox(height: 8.0),
          Text(
            FirebaseAuth.instance.currentUser?.displayName ??
                FirebaseAuth.instance.currentUser?.email ??
                'Unknown User',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          const Divider(),
          Expanded(
            child: StreamBuilder(
              stream: PostService.getPostList(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return const Center(child: Text('No posts yet.'));
                }
                return RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final isOwner =
                          currentUserId != null && post.userId == currentUserId;
                      return PostListItem(post: post, isOwner: isOwner);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddPostScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void testSetUser() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await user.updateDisplayName("Riki");
      await user.updateProfile(displayName: "Riki", photoURL: "");
      await user.reload();
    }
  }
}
