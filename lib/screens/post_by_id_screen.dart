import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/post_api.dart';
import 'post_detail_screen.dart';

class PostByIdScreen extends StatelessWidget {
  const PostByIdScreen({super.key, required this.postId});

  final int postId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Post>(
      future: PostApi.fetchPostById(postId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Post')),
            body: const Center(
              child: Text('Unable to load this post.'),
            ),
          );
        }

        return PostDetailScreen(post: snapshot.data!);
      },
    );
  }
}
