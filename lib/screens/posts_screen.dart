import 'package:flutter/material.dart';

import '../models/post.dart';
import '../screens/post_detail_screen.dart';
import '../services/post_api.dart';
import '../widgets/post_card.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  final List<Post> _posts = [];
  int _total = 0;
  int _skip = 0;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _hasMore => _posts.length < _total;

  Future<void> _loadFirstPage() async {
    setState(() {
      _isInitialLoading = true;
      _hasError = false;
      _posts.clear();
      _skip = 0;
      _total = 0;
    });

    try {
      final page = await PostApi.fetchPosts(limit: _pageSize, skip: 0);
      if (!mounted) return;
      setState(() {
        _posts.addAll(page.posts);
        _total = page.total;
        _skip = page.skip + page.posts.length;
        _isInitialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final page = await PostApi.fetchPosts(limit: _pageSize, skip: _skip);
      if (!mounted) return;
      setState(() {
        _posts.addAll(page.posts);
        _total = page.total;
        _skip = page.skip + page.posts.length;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: _isInitialLoading
                ? const _LoadingState()
                : _hasError && _posts.isEmpty
                    ? _ErrorState(onRetry: _loadFirstPage)
                    : _posts.isEmpty
                        ? _EmptyState(onRetry: _loadFirstPage)
                        : RefreshIndicator(
                            color: scheme.primary,
                            onRefresh: _loadFirstPage,
                            child: NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (notification.metrics.pixels >=
                                    notification.metrics.maxScrollExtent * 0.7) {
                                  _loadMore();
                                }
                                return false;
                              },
                              child: Scrollbar(
                                controller: _scrollController,
                                thumbVisibility: true,
                                interactive: true,
                                thickness: 6,
                                radius: const Radius.circular(12),
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                                  itemCount: _posts.length + 2,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return _Header(loaded: _posts.length, total: _total);
                                    }

                                    final postIndex = index - 1;
                                    if (postIndex < _posts.length) {
                                      final post = _posts[postIndex];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: PostCard(
                                          post: post,
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    PostDetailScreen(post: post),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    }

                                    return _LoadMoreSection(
                                      hasMore: _hasMore,
                                      isLoading: _isLoadingMore,
                                      onLoadMore: _loadMore,
                                    );
                                  },
                                ),
                              ),
                            ),
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withOpacity(0.4),
            scheme.surface,
            scheme.secondaryContainer.withOpacity(0.35),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -40,
            child: _GlowBlob(color: scheme.secondary.withOpacity(0.25)),
          ),
          Positioned(
            bottom: -120,
            right: -60,
            child: _GlowBlob(color: scheme.primary.withOpacity(0.2)),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.loaded, required this.total});

  final int loaded;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Poststream',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All posts from the DummyJSON feed, styled for focus and calm.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface.withOpacity(0.7),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              total > 0 ? '$loaded of $total posts loaded' : '$loaded posts loaded',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadMoreSection extends StatelessWidget {
  const _LoadMoreSection({
    required this.hasMore,
    required this.isLoading,
    required this.onLoadMore,
  });

  final bool hasMore;
  final bool isLoading;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'You\'re all caught up.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : OutlinedButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('Load more'),
              ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading posts...',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 42, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'We could not reach the feed.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 42, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'No posts right now.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Pull to refresh or try again later.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reload feed'),
            ),
          ],
        ),
      ),
    );
  }
}
