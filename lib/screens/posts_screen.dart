import 'dart:ui';

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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _Header(loaded: _posts.length, total: _total),
                Expanded(
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
                                      thickness: 5,
                                      radius: const Radius.circular(12),
                                      child: ListView.builder(
                                        controller: _scrollController,
                                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
                                        itemCount: _posts.length + 1,
                                        itemBuilder: (context, index) {
                                          if (index < _posts.length) {
                                            final post = _posts[index];
                                            return PostCard(
                                              post: post,
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        PostDetailScreen(post: post),
                                                  ),
                                                );
                                              },
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
          ),
          const _DotNav(),
          const _HomeIndicator(),
        ],
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

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('The Journal', style: theme.textTheme.displaySmall),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search_rounded),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: const Icon(Icons.person, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            total > 0 ? '$loaded of $total posts loaded' : '$loaded posts loaded',
            style: theme.textTheme.labelLarge,
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
            'END OF LIST',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 2.8,
                  color: Colors.grey.shade300,
                ),
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
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 36),
          const SizedBox(height: 12),
          Text('We could not reach the feed.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 36),
          const SizedBox(height: 12),
          Text('No posts right now.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reload feed'),
          ),
        ],
      ),
    );
  }
}

class _DotNav extends StatelessWidget {
  const _DotNav();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 44,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dot(active: true),
                    _dot(),
                    _dot(),
                    _dot(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot({bool active = false}) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: active ? Colors.black : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            width: 120,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}
