import 'package:flutter/material.dart';

import '../models/post.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onTap,
  });

  final Post post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = _categoryLabel(post);
    final readTime = _readTime(post.body);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.toUpperCase(), style: theme.textTheme.labelMedium),
            const SizedBox(height: 10),
            Text(post.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('User ${post.userId}', style: theme.textTheme.labelLarge),
                const SizedBox(width: 8),
                Text('•', style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey.shade300)),
                const SizedBox(width: 8),
                Text('$readTime min read', style: theme.textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.body,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            const _EditorialLine(),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(Post post) {
    if (post.tags.isNotEmpty) {
      return post.tags.first;
    }
    return 'Story';
  }

  int _readTime(String body) {
    final words = body.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final minutes = (words / 180).ceil();
    return minutes == 0 ? 1 : minutes;
  }
}

class _EditorialLine extends StatelessWidget {
  const _EditorialLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.grey.shade300,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
