import 'package:flutter/material.dart';

import '../models/post.dart';

class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 6),
                    Text('Post #${post.id}', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Text(
                        'User ${post.userId}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  post.title,
                  style: theme.textTheme.displayMedium?.copyWith(
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  post.body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    _ReactionChip(
                      icon: Icons.favorite_rounded,
                      label: post.likes,
                      color: const Color(0xFF17161B),
                      background: const Color(0xFFD0D0D3),
                    ),
                    const SizedBox(width: 12),
                    _ReactionChip(
                      icon: Icons.thumb_down_alt_rounded,
                      label: post.dislikes,
                      color: scheme.secondary,
                      background: scheme.secondaryContainer,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (post.tags.isNotEmpty)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: post.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '#$tag',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: scheme.tertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0E8DC),
            Color(0xFFF8F5EE),
            Color(0xFFE9E1D5),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -160,
            left: -120,
            child: _Blob(size: 360, color: Color(0x2ABEA788)),
          ),
          Positioned(
            bottom: -240,
            right: -140,
            child: _Blob(size: 420, color: Color(0x33A8A09A)),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final int label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(width: 10),
          Text(
            label.toString(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
