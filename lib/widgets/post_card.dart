import 'package:flutter/material.dart';

import '../models/post.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  final Post post;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final readTime = _readTime(post.body);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.95),
                      scheme.surface.withValues(alpha: 0.92),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.secondary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Post #${post.id}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.tertiary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: onToggleFavorite,
                          icon: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFavorite ? const Color(0xFFB44F5E) : Colors.grey.shade500,
                          ),
                          tooltip: 'Toggle favorite',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.04),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(post.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('User ${post.userId}', style: theme.textTheme.labelLarge),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('$readTime min read', style: theme.textTheme.labelLarge),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${post.likes} likes', style: theme.textTheme.labelLarge),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      post.body,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _EditorialLine(),
        ],
      ),
    );
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
      color: Colors.black,
    );
  }
}
